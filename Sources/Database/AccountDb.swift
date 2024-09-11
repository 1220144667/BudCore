//
//  AccountDb.swift
//  ios
//
//  Copyright © 2019 BudChat. All reserved.
//

import Foundation
import SQLite

public class StoredAccount {
    var id: Int64
    let uid: String
    var credMethods: [String]?
    init(id: Int64, uid: String, credMethods: [String]?) {
        self.id = id
        self.uid = uid
        self.credMethods = credMethods
    }
}

public class AccountDb {
    public static let kTableName = "accounts"
    private let db: SQLite.Connection

    public var table: Table

    public let id: Expression<Int64>
    public let uid: Expression<String?>
    public let active: Expression<Int?>
    public let credMethods: Expression<String?>
    public let deviceId: Expression<String?>

    init(_ database: SQLite.Connection) {
        db = database
        table = Table(AccountDb.kTableName)
        id = Expression<Int64>("id")
        uid = Expression<String?>("uid")
        active = Expression<Int?>("last_active")
        credMethods = Expression<String?>("cred_methods")
        deviceId = Expression<String?>("device_id")
    }

    func destroyTable() {
        try! db.run(table.dropIndex(uid, ifExists: true))
        try! db.run(table.dropIndex(active, ifExists: true))
        try! db.run(table.drop(ifExists: true))
    }

    func createTable() {
        // Must succeed.
        try! db.run(table.create(ifNotExists: true) { t in
            t.column(self.id, primaryKey: .autoincrement)
            t.column(self.uid)
            t.column(self.active)
            t.column(self.credMethods)
            t.column(self.deviceId)
        })
        try! db.run(table.createIndex(uid, unique: true, ifNotExists: true))
        try! db.run(table.createIndex(active, ifNotExists: true))
    }

    // Deletes all records from `accounts` table.
    public func truncateTable() {
        do {
            try db.run(table.delete())
            print("Success to delete accounts")
        } catch let error as NSError {
            print("Failed to delete accounts: \(error)")
        }
    }

    @discardableResult
    func deactivateAll() throws -> Int {
        // 取消设置所有账户为非活跃状态处理，多用户数据库模式，每个用户单独DB, 不需要设置状态。daxiong 2024-02-01
        // return try self.db.run(self.table.update(self.active <- 0))
        return 0
    }

    public func getByUid(uid: String) -> StoredAccount? {
        if let row = try? db.pluck(table.select(id, credMethods).filter(self.uid == uid)) {
            return StoredAccount(id: row[id], uid: uid, credMethods: row[credMethods]?.components(separatedBy: ","))
        }
        return nil
    }

    func addOrActivateAccount(for uid: String, withCredMethods meth: [String]?) -> StoredAccount? {
        let savepointName = "AccountDb.addOrActivateAccount"
        var result: StoredAccount?
        do {
            try db.savepoint(savepointName) {
                try self.deactivateAll()
                result = self.getByUid(uid: uid)
                let serializedCredMeth = meth?.joined(separator: ",")
                if result != nil {
                    let record = self.table.filter(self.id == result!.id)
                    try self.db.run(record.update(
                        self.active <- 1,
                        self.credMethods <- serializedCredMeth
                    ))
                } else {
                    let newId = try db.run(self.table.insert(
                        self.uid <- uid,
                        self.active <- 1,
                        self.credMethods <- serializedCredMeth
                    ))
                    result = StoredAccount(id: newId, uid: uid, credMethods: meth)
                }
                if result!.id < 0 {
                    result = nil
                } else {
                    result?.credMethods = meth
                }
            }
        } catch SQLite.Result.error(message: let err, code: let code, statement: _) {
            // Explicitly releasing savepoint since ROLLBACK TO (SQLite.swift behavior) won't release the savepoint transaction.
            self.db.releaseSavepoint(withName: savepointName)
            BaseDb.log.error("Failed to add account for uid %@: SQLite code = %d, error = %@", uid, code, err)
            result = nil
        } catch {
            // Explicitly releasing savepoint since ROLLBACK TO (SQLite.swift behavior) won't release the savepoint transaction.
            db.releaseSavepoint(withName: savepointName)
            BaseDb.log.error("Failed to add account '%@'", error.localizedDescription)
            result = nil
        }
        return result
    }

    func delete(accountId: Int64) -> Bool {
        let record = table.filter(id == accountId)
        do {
            return try db.run(record.delete()) > 0
        } catch {
            BaseDb.log.error("AccountDb - delete(accountId) operation failed: accountId = %lld, error = %@", accountId, error.localizedDescription)
            return false
        }
    }

    func getActiveAccount() -> StoredAccount? {
        if let row = try? db.pluck(table.select(id, uid, credMethods).filter(active == 1)),
           let ruid = row[uid]
        {
            return StoredAccount(id: row[id], uid: ruid, credMethods: row[credMethods]?.components(separatedBy: ","))
        }
        return nil
    }

    @discardableResult
    func saveDeviceToken(token: String?) -> Bool {
        let record = table.filter(active == 1)
        do {
            return try db.run(record.update(deviceId <- token)) > 0
        } catch {
            return false
        }
    }

    func getDeviceToken() -> String? {
        if let row = try? db.pluck(table.select(deviceId).filter(active == 1)),
           let d = row[deviceId]
        {
            return d
        }
        return nil
    }
}
