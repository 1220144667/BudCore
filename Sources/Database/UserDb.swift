//
//  UserDb.swift
//  ios
//
//  Copyright © 2019 BudChat. All reserved.
//

import Foundation
import SQLite

public class StoredUser: Payload {
    let id: Int64?
    init(id: Int64) { self.id = id }
}

public class UserDb {
    public static let kTableName = "users"
    // Fake UID for "no user" user.
    private static let kNoUser = "NONE"

    private let db: SQLite.Connection

    public let table: Table

    public let id: Expression<Int64>
    public let accountId: Expression<Int64?>
    public let uid: Expression<String?>
    public let updated: Expression<Date?>
    // public let deleted: Expression<Int?>
    public let pub: Expression<String?>

    private let baseDb: BaseDb!

    init(_ database: SQLite.Connection, baseDb: BaseDb) {
        db = database
        self.baseDb = baseDb
        table = Table(UserDb.kTableName)
        id = Expression<Int64>("id")
        accountId = Expression<Int64?>("account_id")
        uid = Expression<String?>("uid")
        updated = Expression<Date?>("updated")
        pub = Expression<String?>("pub")
    }

    func destroyTable() {
        try! db.run(table.dropIndex(accountId, uid, ifExists: true))
        try! db.run(table.drop(ifExists: true))
    }

    func createTable() {
        let accountDb = baseDb.accountDb!
        // Must succeed.
        try! db.run(table.create(ifNotExists: true) { t in
            t.column(id, primaryKey: .autoincrement)
            t.column(accountId, references: accountDb.table, accountDb.id)
            t.column(uid)
            t.column(updated)
            t.column(pub)
        })
        try! db.run(table.createIndex(accountId, uid, ifNotExists: true))
    }

    // Deletes all records from `users` table.
    public func truncateTable() {
        try! db.run(table.delete())
    }

    public func insert(user: UserProto?) -> Int64 {
        guard let user = user else { return 0 }
        let id = insert(uid: user.uid, updated: user.updated, serializedPub: user.serializePub())
        if id > 0 {
            let su = StoredUser(id: id)
            user.payload = su
        }
        return id
    }

    @discardableResult
    public func insert(sub: SubscriptionProto?) -> Int64 {
        guard let sub = sub else { return -1 }
        return insert(uid: sub.user ?? sub.topic, updated: sub.updated, serializedPub: sub.serializePub())
    }

    func insert(uid: String?, updated: Date?, serializedPub: String?) -> Int64 {
        let uid = (uid ?? "").isEmpty ? UserDb.kNoUser : uid!
        do {
            let rowid = try db.run(
                table.insert(
                    accountId <- baseDb.account?.id,
                    self.uid <- uid,
                    self.updated <- updated ?? Date(),
                    pub <- serializedPub
                ))
            return rowid
        } catch SQLite.Result.error(message: let errMsg, code: let code, statement: _) {
            BaseDb.log.error("UserDb - SQL error: uid = %@, code = %d, error = %@", uid, code, errMsg)
            return -1
        } catch {
            BaseDb.log.error("UserDb - insert operation failed: uid = %@, error = %@", uid, error.localizedDescription)
            return -1
        }
    }

    @discardableResult
    public func update(user: UserProto?) -> Bool {
        guard let user = user, let su = user.payload as? StoredUser, let userId = su.id, userId > 0 else { return false }
        return update(userId: userId, updated: user.updated, serializedPub: user.serializePub())
    }

    @discardableResult
    public func update(sub: SubscriptionProto?) -> Bool {
        guard let st = sub?.payload as? StoredSubscription, let userId = st.userId else { return false }
        return update(userId: userId, updated: sub?.updated, serializedPub: sub?.serializePub())
    }

    @discardableResult
    public func update(userId: Int64, updated: Date?, serializedPub: String?) -> Bool {
        var setters = [Setter]()
        if let u = updated {
            setters.append(self.updated <- u)
        }
        if let s = serializedPub {
            setters.append(pub <- s)
        }
        guard setters.count > 0 else { return false }
        let record = table.filter(id == userId)
        do {
            return try db.run(record.update(setters)) > 0
        } catch {
            BaseDb.log.error("UserDb - update operation failed: userId = %lld, error = %@", userId, error.localizedDescription)
            return false
        }
    }

    @discardableResult
    public func deleteRow(for id: Int64) -> Bool {
        let record = table.filter(self.id == id)
        do {
            return try db.run(record.delete()) > 0
        } catch {
            BaseDb.log.error("UserDb - deleteRow operation failed: userId = %lld, error = %@", id, error.localizedDescription)
            return false
        }
    }

    public func delete(forAccount accountId: Int64) -> Bool {
        let record = table.filter(self.accountId == accountId)
        do {
            return try db.run(record.delete()) > 0
        } catch {
            BaseDb.log.error("UserDb - delete(forAccount) operation failed: accountId = %lld, error = %@", accountId, error.localizedDescription)
            return false
        }
    }

    public func getId(for uid: String?) -> Int64 {
        guard let accountId = baseDb.account?.id else {
            return -1
        }
        let uid = uid ?? UserDb.kNoUser
        if let row = try? db.pluck(table.select(id).filter(self.uid == uid && self.accountId == accountId)) {
            return row[id]
        }
        return -1
    }

    private func rowToUser(r: Row) -> UserProto? {
        let id = r[self.id]
        let updated = r[self.updated]
        let pub = r[self.pub]
        guard let user = DefaultUser.createFromPublicData(uid: r[uid], updated: updated, data: pub) else { return nil }
        let storedUser = StoredUser(id: id)
        user.payload = storedUser
        return user
    }

    public func readOne(uid: String?) -> UserProto? {
        guard let accountId = baseDb.account?.id else {
            return nil
        }
        let uid = uid ?? UserDb.kNoUser
        guard let row = try? db.pluck(table.filter(self.uid == uid && self.accountId == accountId)) else {
            return nil
        }
        return rowToUser(r: row)
    }

    // Generic reader
    private func read(one uid: String?, multiple uids: [String]) -> [UserProto]? {
        guard uid != nil || !uids.isEmpty else { return nil }
        guard let accountId = baseDb.account?.id else {
            return nil
        }
        var query = table.select(table[*])
        query = uid != nil ? query.where(self.accountId == accountId && self.uid != uid) : query.where(self.accountId == accountId && uids.contains(self.uid))
        query = query.order(updated.desc, id.desc)
        do {
            var users = [UserProto]()
            for r in try db.prepare(query) {
                if let u = rowToUser(r: r) {
                    users.append(u)
                }
            }
            return users
        } catch {
            BaseDb.log.error("UserDb - read operation failed: error = %@", error.localizedDescription)
        }
        return nil
    }

    // Read users with uids in the array.
    public func read(uids: [String]) -> [UserProto]? {
        return read(one: nil, multiple: uids)
    }

    // Select all users except given user.
    public func readAll(for uid: String?) -> [UserProto]? {
        return read(one: uid, multiple: [])
    }
}
