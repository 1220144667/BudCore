//
//  TopicDb.swift
//  ios
//
//  Copyright © 2019-2022 BudChat. All reserved.
//

import Foundation
import SQLite

public class StoredTopic: Payload {
    var id: Int64?
    var lastUsed: Date?
    var minLocalSeq: Int?
    var maxLocalSeq: Int?
    var status: BaseDb.Status = .undefined
    var nextUnsentId: Int?

    public static func isAllDataLoaded(topic: TopicProto?) -> Bool {
        guard let topic = topic else { return false }
        if (topic.seq ?? -1) == 0 { return true }
        guard let st = topic.payload as? StoredTopic else { return false }
        return (st.minLocalSeq ?? -1) == 1
    }
}

public class TopicDb {
    public static let kTableName = "topics"
    private static let kUnsentIdStart = 2_000_000_000
    private let db: SQLite.Connection

    public var table: Table

    public let id: Expression<Int64>
    public let accountId: Expression<Int64?>
    public let status: Expression<Int?>
    public let topic: Expression<String?>
    public let type: Expression<Int?>
    public let visible: Expression<Int64?>
    public let created: Expression<Date?>
    public let updated: Expression<Date?>
    public let read: Expression<Int?>
    public let recv: Expression<Int?>
    public let seq: Expression<Int?>
    public let clear: Expression<Int?>
    public let maxDel: Expression<Int?>
    public let accessMode: Expression<String?>
    public let defacs: Expression<String?>
    public let lastUsed: Expression<Date?>
    public let minLocalSeq: Expression<Int?>
    public let maxLocalSeq: Expression<Int?>
    public let nextUnsentSeq: Expression<Int?>
    public let tags: Expression<String?>
    public let creds: Expression<String?>
    public let pub: Expression<String?>
    public let priv: Expression<String?>
    public let trusted: Expression<String?>

    private let baseDb: BaseDb!

    init(_ database: SQLite.Connection, baseDb: BaseDb) {
        db = database
        self.baseDb = baseDb
        table = Table(TopicDb.kTableName)
        id = Expression<Int64>("id")
        accountId = Expression<Int64?>("account_id")
        status = Expression<Int?>("status")
        topic = Expression<String?>("topic")
        type = Expression<Int?>("type")
        visible = Expression<Int64?>("visible")
        created = Expression<Date?>("created")
        updated = Expression<Date?>("updated")
        read = Expression<Int?>("read")
        recv = Expression<Int?>("recv")
        seq = Expression<Int?>("seq")
        clear = Expression<Int?>("clear")
        maxDel = Expression<Int?>("max_del")
        accessMode = Expression<String?>("mode")
        defacs = Expression<String?>("defacs")
        lastUsed = Expression<Date?>("last_used")
        minLocalSeq = Expression<Int?>("min_local_seq")
        maxLocalSeq = Expression<Int?>("max_local_seq")
        nextUnsentSeq = Expression<Int?>("next_unsent_seq")
        tags = Expression<String?>("tags")
        creds = Expression<String?>("creds")
        pub = Expression<String?>("pub")
        priv = Expression<String?>("priv")
        trusted = Expression<String?>("trusted")
    }

    func destroyTable() {
        try! db.run(table.dropIndex(accountId, topic, ifExists: true))
        try! db.run(table.drop(ifExists: true))
    }

    func createTable() {
        let accountDb = baseDb.accountDb!
        // Must succeed.
        try! db.run(table.create(ifNotExists: true) { t in
            t.column(id, primaryKey: .autoincrement)
            t.column(accountId, references: accountDb.table, accountDb.id)
            t.column(status)
            t.column(topic)
            t.column(type)
            t.column(visible)
            t.column(created)
            t.column(updated)

            t.column(read)
            t.column(recv)
            t.column(seq)
            t.column(clear)
            t.column(maxDel)

            t.column(accessMode)
            t.column(defacs)
            t.column(lastUsed)
            t.column(minLocalSeq)
            t.column(maxLocalSeq)
            t.column(nextUnsentSeq)

            t.column(tags)
            t.column(creds)
            t.column(pub)
            t.column(priv)
            t.column(trusted)
        })
        try! db.run(table.createIndex(accountId, topic, unique: true, ifNotExists: true))
    }

    // Deletes all records from `topics` table.
    public func truncateTable() {
        try! db.run(table.delete())
    }

    public static func isUnsentSeq(seq: Int) -> Bool {
        return seq >= TopicDb.kUnsentIdStart
    }

    func deserializeTopic(topic: TopicProto, row: Row) {
        let st = StoredTopic()
        st.id = row[id]
        st.status = BaseDb.Status(rawValue: row[status] ?? 0) ?? .undefined
        st.lastUsed = row[lastUsed]
        st.minLocalSeq = row[minLocalSeq]
        st.maxLocalSeq = row[maxLocalSeq]
        st.nextUnsentId = row[nextUnsentSeq]

        topic.updated = row[updated]
        topic.touched = st.lastUsed
        topic.deleted = st.status == BaseDb.Status.deletedHard || st.status == BaseDb.Status.deletedSoft
        topic.read = row[read]
        topic.recv = row[recv]
        topic.seq = row[seq]
        topic.clear = row[clear]
        topic.maxDel = row[maxDel] ?? 0
        (topic as? MeTopicProto)?.deserializeCreds(from: row[creds])
        topic.tags = row[tags]?.components(separatedBy: ",")

        topic.accessMode = Acs.deserialize(from: row[accessMode])
        topic.defacs = Defacs.deserialize(from: row[defacs])
        topic.deserializePub(from: row[pub])
        topic.deserializePriv(from: row[priv])
        topic.deserializeTrusted(from: row[trusted])
        topic.payload = st
    }

    public func getId(topic: String?) -> Int64 {
        guard let topic = topic else {
            return -1
        }
        if let row = try? db.pluck(table.select(id).filter(accountId
                == baseDb.account?.id && self.topic == topic))
        {
            return row[id]
        }
        return -1
    }

    public func getIds() -> [Int64] {
        let querys = query()
        return querys?.map { $0[self.id] } ?? []
    }

    func getNextUnusedSeq(topic: TopicProto) -> Int {
        guard let st = topic.payload as? StoredTopic, let recordId = st.id else { return -1 }
        let record = table.filter(id == recordId)
        st.nextUnsentId = (st.nextUnsentId ?? 0) + 1
        var setters = [Setter]()
        setters.append(nextUnsentSeq <- st.nextUnsentId)
        do {
            if try db.run(record.update(setters)) > 0 {
                return st.nextUnsentId!
            }
        } catch {
            BaseDb.log.error("TopicDb - getNextUnusedSeq operation failed: topicId = %lld, error = %@", recordId, error.localizedDescription)
        }
        return -1
    }

    func query(for tinode: BudChat?, keyword: String) -> [TopicProto] {
        // 查询语句
        let likes = "%" + keyword + "%"
        let query = table.select(table[*]).filter(pub.like(likes))
        // 开始查询
        do {
            var topics: [TopicProto] = []
            for row in try db.prepare(query) {
                if let topicName = row[topic] {
                    let t = BudChat.newTopic(withTinode: tinode, forTopic: topicName)
                    deserializeTopic(topic: t, row: row)
                    topics.append(t)
                }
            }
            return topics
        } catch SQLite.Result.error(message: let errMsg, code: let code, statement: _) {
            BaseDb.log.error("MessageDb - query SQLite error: code = %d, error = %@", code, errMsg)
            return []
        } catch {
            BaseDb.log.error("MessageDb - query operation failed: error = %@", error.localizedDescription)
            return []
        }
    }

    func query() -> AnySequence<Row>? {
        guard let accountId = baseDb.account?.id else {
            return nil
        }

        let topics = table.filter(self.accountId == accountId)
        return try? db.prepare(topics)
    }

    func readOne(for tinode: BudChat?, withName topicName: String?) -> TopicProto? {
        guard let accountId = baseDb.account?.id else {
            return nil
        }
        if let row = try? db.pluck(table.filter(self.accountId == accountId && topic == topicName)) {
            return readOne(for: tinode, row: row)
        }
        return nil
    }

    func readOne(for tinode: BudChat?, row: Row) -> TopicProto? {
        guard let topicName = row[topic] else {
            return nil
        }
        let t = BudChat.newTopic(withTinode: tinode, forTopic: topicName)
        deserializeTopic(topic: t, row: row)
        return t
    }

    func getTopicName(id: Int64?) -> String? {
        guard let topicId = id else { return nil }
        guard let accountId = baseDb.account?.id else { return nil }
        let query = table.filter(self.accountId == accountId && self.id == topicId)
        if let row = try? db.pluck(query) {
            return row[topic]
        }
        return nil
    }

    func insert(topic: TopicProto) -> Int64 {
        guard let accountId = baseDb.account?.id else {
            BaseDb.log.error("TopicDb.insert: account id is not defined.")
            return -1
        }
        do {
            // 1414213562 is Oct 25, 2014 05:06:02 UTC, incidentally equal to the first few digits of sqrt(2)
            let lastUsed = topic.touched ?? Date(timeIntervalSince1970: 1_414_213_562)

            let tp = topic.topicType
            let tpv = tp.rawValue
            let status = topic.isNew ? BaseDb.Status.queued : BaseDb.Status.synced
            let rowid = try db.run(
                table.insert(
                    self.accountId <- accountId,
                    self.status <- status.rawValue,
                    self.topic <- topic.name,
                    type <- tpv,
                    visible <- TopicType.grp == tp || TopicType.p2p == tp ? 1 : 0,
                    created <- lastUsed,
                    updated <- topic.updated,

                    read <- topic.read,
                    recv <- topic.recv,
                    seq <- topic.seq,
                    clear <- topic.clear,
                    maxDel <- topic.maxDel,

                    accessMode <- topic.accessMode?.serialize(),
                    defacs <- topic.defacs?.serialize(),
                    self.lastUsed <- lastUsed,
                    minLocalSeq <- 0,
                    maxLocalSeq <- 0,
                    nextUnsentSeq <- TopicDb.kUnsentIdStart,

                    tags <- topic.tags?.joined(separator: ","),
                    creds <- (topic as? MeTopicProto)?.serializeCreds(),
                    pub <- topic.serializePub(),
                    priv <- topic.serializePriv(),
                    trusted <- topic.serializeTrusted()
                ))
            if rowid > 0 {
                let st = StoredTopic()
                st.id = rowid
                st.lastUsed = lastUsed
                st.minLocalSeq = nil
                st.maxLocalSeq = nil
                st.status = status
                st.nextUnsentId = TopicDb.kUnsentIdStart
                topic.payload = st
            }
            return rowid
        } catch {
            BaseDb.log.error("TopicDb - insert operation failed: error = %@", error.localizedDescription)
            return -1
        }
    }

    func update(topic: TopicProto) -> Bool {
        guard let st = topic.payload as? StoredTopic, let recordId = st.id else {
            return false
        }
        let record = table.filter(id == recordId)
        var setters = [Setter]()
        var status = st.status
        if status == BaseDb.Status.queued && !topic.isNew {
            status = BaseDb.Status.synced
            setters.append(self.status <- status.rawValue)
            setters.append(self.topic <- topic.name)
        }
        if let updated = topic.updated {
            setters.append(self.updated <- updated)
        }
        setters.append(read <- topic.read)
        setters.append(recv <- topic.recv)
        setters.append(seq <- topic.seq)
        setters.append(clear <- topic.clear)
        setters.append(accessMode <- topic.accessMode?.serialize())
        setters.append(defacs <- topic.defacs?.serialize())
        setters.append(tags <- topic.tags?.joined(separator: ","))
        if let topic = topic as? MeTopicProto {
            setters.append(creds <- topic.serializeCreds())
        }
        setters.append(pub <- topic.serializePub())
        setters.append(priv <- topic.serializePriv())
        setters.append(trusted <- topic.serializeTrusted())
        if let touched = topic.touched {
            setters.append(lastUsed <- touched)
        }
        do {
            if try db.run(record.update(setters)) > 0 {
                if topic.touched != nil {
                    st.lastUsed = topic.touched
                }
                st.status = status
                return true
            }
        } catch {
            BaseDb.log.error("TopicDb - update operation failed: topicId = %lld, error = %@", recordId, error.localizedDescription)
        }
        return false
    }

    func msgReceived(topic: TopicProto, ts: Date, seq: Int) -> Bool {
        guard let st = topic.payload as? StoredTopic, let recordId = st.id else {
            return false
        }
        var setters = [Setter]()
        var updateMaxLocalSeq = false
        if seq > (st.maxLocalSeq ?? -1) {
            setters.append(maxLocalSeq <- seq)
            setters.append(recv <- seq)
            updateMaxLocalSeq = true
        }
        var updateMinLocalSeq = false
        if seq > 0 && (st.minLocalSeq == 0 || seq < (st.minLocalSeq ?? Int.max)) {
            setters.append(minLocalSeq <- seq)
            updateMinLocalSeq = true
        }
        if seq > (topic.seq ?? -1) {
            setters.append(self.seq <- seq)
        }
        var updateLastUsed = false
        if let lastUsed = st.lastUsed, lastUsed < ts {
            setters.append(self.lastUsed <- ts)
            updateLastUsed = true
        }
        if setters.count > 0 {
            let record = table.filter(id == recordId)
            do {
                if try db.run(record.update(setters)) > 0 {
                    if updateLastUsed { st.lastUsed = ts }
                    if updateMinLocalSeq { st.minLocalSeq = seq }
                    if updateMaxLocalSeq { st.maxLocalSeq = seq }
                }
            } catch {
                BaseDb.log.error("TopicDb - msgReceived failed: topicId = %@, error = %@", recordId, error.localizedDescription)
                return false
            }
        }
        return true
    }

    func msgDeleted(topic: TopicProto, delId: Int, from loId: Int, to hiId: Int) -> Bool {
        guard let st = topic.payload as? StoredTopic, let recordId = st.id else {
            return false
        }
        var setters = [Setter]()
        if delId > topic.maxDel {
            setters.append(maxDel <- delId)
        }
        // If lowId is 0, all earlier messages are being deleted, set it to lowest possible value: 1.
        var loId = loId > 0 ? loId : 1
        // Upper bound is exclusive.
        // If hiId is zero all later messages are bing deleted, set it to highest possible value.
        var hiId = hiId > 1 ? hiId - 1 : (topic.seq ?? 0)

        // Expand the available range only when there is an overlap.
        // When minLocalSeq is 0 then there are no locally stored messages. Don't update minLocalSeq.
        if loId < (st.minLocalSeq ?? 0) && hiId >= (st.minLocalSeq ?? 0) {
            setters.append(minLocalSeq <- loId)
        } else {
            loId = -1
        }
        if hiId > (st.maxLocalSeq ?? 0) && loId <= (st.maxLocalSeq ?? 0) {
            setters.append(maxLocalSeq <- hiId)
        } else {
            hiId = -1
        }

        guard !setters.isEmpty else { return true }
        let record = table.filter(id == recordId)
        var success = false
        do {
            success = try db.run(record.update(setters)) > 0
            if success {
                if loId > 0 {
                    st.minLocalSeq = loId
                }
                if hiId > 0 {
                    st.maxLocalSeq = hiId
                }
            }
        } catch {
            BaseDb.log.error("TopicDb - msgDelivered failed: topicId = %lld, error = %@", recordId, error.localizedDescription)
        }
        return success
    }

    @discardableResult
    func delete(recordId: Int64) -> Bool {
        let record = table.filter(id == recordId)
        do {
            return try db.run(record.delete()) > 0
        } catch {
            BaseDb.log.error("TopicDb - delete failed: topicId = %lld, error = %@", recordId, error.localizedDescription)
            return false
        }
    }

    @discardableResult
    func markDeleted(recordId: Int64) -> Bool {
        let record = table.filter(id == recordId)
        var setters: [Setter] = []
        setters.append(status <- BaseDb.Status.deletedHard.rawValue)
        do {
            return try db.run(record.update(setters)) > 0
        } catch {
            BaseDb.log.error("TopicDb - mark deleted failed: topicId = %lld, error = %@", recordId, error.localizedDescription)
            return false
        }
    }

    func deleteAll(forAccount accountId: Int64) -> Bool {
        // Delete from messages and subscribers where topicIds belong to accountId.
        guard let messageDb = baseDb.messageDb, let subscriberDb = baseDb.subscriberDb else { return false }
        // Using raw sql here because SQLite.swift doesn't support nested queries:
        // https://stackoverflow.com/questions/46033280/sqlite-swift-how-to-do-subquery
        let messageDbSql =
            "DELETE FROM " + MessageDb.kTableName +
            " WHERE " + messageDb.topicId.template + " IN (" +
            "SELECT " + id.template + " FROM " + TopicDb.kTableName +
            " WHERE " + self.accountId.template + " = ?)"
        let subscriberDbSql =
            "DELETE FROM " + SubscriberDb.kTableName +
            " WHERE " + subscriberDb.topicId.template + " IN (" +
            "SELECT " + id.template + " FROM " + TopicDb.kTableName +
            " WHERE " + self.accountId.template + " = ?)"
        let topics = table.filter(self.accountId == accountId)
        do {
            try db.run(messageDbSql, accountId)
            try db.run(subscriberDbSql, accountId)
            try db.run(topics.delete())
        } catch {
            BaseDb.log.error("TopicDb - deleteAll(forAccount) failed: accountId = %lld, error = %@", accountId, error.localizedDescription)
            return false
        }
        return true
    }

    func updateRead(for topicId: Int64, with value: Int) -> Bool {
        return BaseDb.updateCounter(db: db, table: table,
                                    usingIdColumn: id, forId: topicId,
                                    in: read, with: value)
    }

    func updateRecv(for topicId: Int64, with value: Int) -> Bool {
        return BaseDb.updateCounter(db: db, table: table,
                                    usingIdColumn: id, forId: topicId,
                                    in: recv, with: value)
    }
}
