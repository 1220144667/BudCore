//
//  SubscriberDb.swift
//  ios
//
//  Copyright © 2019 BudChat. All reserved.
//

import Foundation
import SQLite

public class StoredSubscription: Payload {
    public var id: Int64?
    public var topicId: Int64?
    public var userId: Int64?
    public var status: BaseDb.Status?
}

enum SubscriberDbError: Error {
    case dbError(String)
}

public class SubscriberDb {
    public static let kTableName = "subscriptions"
    private let db: SQLite.Connection

    private var table: Table

    public let id: Expression<Int64>
    public var topicId: Expression<Int64?>
    public let userId: Expression<Int64?>
    public let status: Expression<Int?>
    public let mode: Expression<String?>
    public let updated: Expression<Date?>

    public let read: Expression<Int?>
    public let recv: Expression<Int?>
    public let clear: Expression<Int?>
    public let priv: Expression<String?>
    public let lastSeen: Expression<Date?>
    public let userAgent: Expression<String?>
    public let subscriptionClass: Expression<String>

    private let baseDb: BaseDb!

    init(_ database: SQLite.Connection, baseDb: BaseDb) {
        db = database
        self.baseDb = baseDb
        table = Table(SubscriberDb.kTableName)
        id = Expression<Int64>("id")
        topicId = Expression<Int64?>("topic_id")
        userId = Expression<Int64?>("user_id")
        status = Expression<Int?>("status")
        mode = Expression<String?>("mode")
        updated = Expression<Date?>("updated")
        // self.deleted =
        read = Expression<Int?>("read")
        recv = Expression<Int?>("recv")
        clear = Expression<Int?>("clear")
        priv = Expression<String?>("priv")
        lastSeen = Expression<Date?>("last_seen")
        userAgent = Expression<String?>("user_agent")
        subscriptionClass = Expression<String>("subscription_class")
    }

    func destroyTable() {
        try! db.run(table.dropIndex(topicId, ifExists: true))
        try! db.run(table.drop(ifExists: true))
    }

    func createTable() {
        let userDb = baseDb.userDb!
        let topicDb = baseDb.topicDb!
        // Must succeed.
        try! db.run(table.create(ifNotExists: true) { t in
            t.column(id, primaryKey: .autoincrement)
            t.column(topicId, references: topicDb.table, topicDb.id)
            t.column(userId, references: userDb.table, userDb.id)
            t.column(status)
            t.column(mode)
            t.column(updated)
            // self.deleted =
            t.column(read)
            t.column(recv)
            t.column(clear)
            t.column(priv)
            t.column(lastSeen)
            t.column(userAgent)
            t.column(subscriptionClass)
        })
        try! db.run(table.createIndex(topicId, ifNotExists: true))
    }

    // Deletes all records from `subscribers` table.
    func truncateTable() {
        try! db.run(table.delete())
    }

    func insert(for topicId: Int64, with status: BaseDb.Status, using sub: SubscriptionProto) -> Int64 {
        var rowId: Int64 = -1
        let savepointName = "SubscriberDb.insert"
        do {
            try db.savepoint(savepointName) {
                let ss = StoredSubscription()
                let userDb = baseDb.userDb!
                ss.userId = userDb.getId(for: sub.user)
                if (ss.userId ?? -1) <= 0 {
                    ss.userId = userDb.insert(sub: sub)
                }
                // Still not okay?
                if (ss.userId ?? -1) <= 0 {
                    throw SubscriberDbError.dbError("failed to insert row into UserDb: \(String(describing: ss.userId))")
                }
                var setters = [Setter]()

                ss.topicId = topicId
                setters.append(self.topicId <- ss.topicId)
                setters.append(self.userId <- ss.userId)
                setters.append(self.mode <- sub.acs?.serialize())
                setters.append(self.updated <- sub.updated ?? Date())
                setters.append(self.status <- status.rawValue)
                ss.status = status
                setters.append(self.read <- sub.getRead)
                setters.append(self.recv <- sub.getRecv)
                setters.append(self.clear <- sub.getClear)
                setters.append(self.priv <- sub.serializePriv())
                if let seen = sub.seen {
                    setters.append(self.lastSeen <- seen.when)
                    setters.append(self.userAgent <- seen.ua)
                }
                setters.append(self.subscriptionClass <- String(describing: type(of: sub as Any)))
                rowId = try db.run(self.table.insert(setters))
                ss.id = rowId
                sub.payload = ss
            }
        } catch {
            // Explicitly releasing savepoint since ROLLBACK TO (SQLite.swift behavior) won't release the savepoint transaction.
            db.releaseSavepoint(withName: savepointName)
            BaseDb.log.error("SubscriberDb - insert operation failed: topicId = %lld, error = %@", topicId, error.localizedDescription)
            return -1
        }
        return rowId
    }

    func update(using sub: SubscriptionProto) -> Bool {
        guard let ss = sub.payload as? StoredSubscription, let recordId = ss.id, recordId >= 0 else {
            return false
        }
        let record = table.filter(id == recordId)
        var updated = 0
        let savepointName = "SubscriberDb.update"
        do {
            try db.savepoint(savepointName) {
                var status = ss.status!
                _ = baseDb.userDb!.update(sub: sub)
                var setters = [Setter]()
                setters.append(self.mode <- sub.acs?.serialize())
                setters.append(self.updated <- sub.updated)
                if status != .synced {
                    setters.append(self.status <- BaseDb.Status.synced.rawValue)
                    status = .synced
                }
                setters.append(self.read <- sub.getRead)
                setters.append(self.recv <- sub.getRecv)
                setters.append(self.clear <- sub.getClear)
                setters.append(self.priv <- sub.serializePriv())
                if let seen = sub.seen {
                    setters.append(self.lastSeen <- seen.when)
                    setters.append(self.userAgent <- seen.ua)
                }
                updated = try self.db.run(record.update(setters))
                ss.status = status
            }
        } catch {
            // Explicitly releasing savepoint since ROLLBACK TO (SQLite.swift behavior) won't release the savepoint transaction.
            db.releaseSavepoint(withName: savepointName)
            BaseDb.log.error("SubscriberDb - update operation failed: subId = %lld, error = %@", recordId, error.localizedDescription)
            return false
        }
        return updated > 0
    }

    func delete(recordId: Int64) -> Bool {
        let record = table.filter(id == recordId)
        do {
            return try db.run(record.delete()) > 0
        } catch {
            BaseDb.log.error("SubscriberDb - delete operation failed: subId = %lld, error = %@", recordId, error.localizedDescription)
            return false
        }
    }

    @discardableResult
    func deleteForTopic(topicId: Int64) -> Bool {
        let record = table.filter(self.topicId == topicId)
        do {
            return try db.run(record.delete()) > 0
        } catch {
            BaseDb.log.error("SubscriberDb - deleteForTopic operation failed: topicId = %lld, error = %@", topicId, error.localizedDescription)
            return false
        }
    }

    private func readOne(r: Row) -> SubscriptionProto? {
        guard let s = DefaultSubscription.createByName(name: r[subscriptionClass]) else { return nil }
        guard let udb = baseDb.userDb else { return nil }
        guard let tdb = baseDb.topicDb else { return nil }
        let ss = StoredSubscription()
        ss.id = r[id]
        ss.topicId = r[topicId]
        ss.userId = r[userId]
        ss.status = BaseDb.Status(rawValue: r[status] ?? 0) ?? .undefined

        s.acs = Acs.deserialize(from: r[mode])
        s.updated = r[updated]
        s.seq = r[tdb.seq]
        s.read = r[read]
        s.recv = r[recv]
        s.clear = r[clear]
        s.seen = LastSeen(when: r[lastSeen], ua: r[userAgent])
        s.user = r[udb.uid]
        s.topic = r[tdb.topic]
        s.deserializePub(from: r[udb.pub])
        s.deserializePriv(from: r[priv])
        s.payload = ss
        return s
    }

    func readAll(topicId: Int64) -> [SubscriptionProto]? {
        guard let userDb = baseDb.userDb else { return nil }
        guard let topicDb = baseDb.topicDb else { return nil }
        let joinedTable = table.select(
            table[id],
            self.topicId,
            userId,
            table[status],
            table[mode],
            table[updated],
            // self.deleted
            table[read],
            table[recv],
            table[clear],
            table[priv],
            lastSeen,
            userAgent,
            userDb.table[userDb.uid],
            userDb.table[userDb.pub],
            topicDb.table[topicDb.topic],
            topicDb.table[topicDb.seq],
            subscriptionClass
        )
        .join(.leftOuter, userDb.table, on: table[userId] == userDb.table[userDb.id])
        .join(.leftOuter, topicDb.table, on: table[self.topicId] == topicDb.table[topicDb.id])
        .filter(self.topicId == topicId)

        do {
            var subscriptions = [SubscriptionProto]()
            for row in try db.prepare(joinedTable) {
                if let s = readOne(r: row) {
                    subscriptions.append(s)
                } else {
                    BaseDb.log.error("SubscriberDb - readAll: topicId = %lld | failed to create subscription for %@", topicId, row[subscriptionClass])
                }
            }
            return subscriptions
        } catch {
            BaseDb.log.error("SubscriberDb - failed to read subscriptions: %@", error.localizedDescription)
            return nil
        }
    }

    func updateRead(for subId: Int64, with value: Int) -> Bool {
        return BaseDb.updateCounter(db: db, table: table,
                                    usingIdColumn: id, forId: subId,
                                    in: read, with: value)
    }

    func updateRecv(for subId: Int64, with value: Int) -> Bool {
        return BaseDb.updateCounter(db: db, table: table,
                                    usingIdColumn: id, forId: subId,
                                    in: recv, with: value)
    }
}
