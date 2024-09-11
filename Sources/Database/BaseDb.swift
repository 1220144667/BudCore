//
//  BaseDb.swift
//  ios
//
//  Copyright © 2019-2022 BudChat. All reserved.
//

import Foundation
import SQLite

public class BaseDb {
    // Current database schema version. Increment on schema changes.
    public static let kSchemaVersion: Int32 = 111

    // Object statuses. Values are incremented by 10 to make it easier to add new statuses.
    public enum Status: Int, Comparable {
        // Status undefined/not set.
        case undefined = 0
        // Object is not ready to be sent to the server.
        case draft = 10
        // Object is ready but not yet sent to the server.
        case queued = 20
        // Object is in the process of being sent to the server.
        case sending = 30
        // Sending failed
        case failed = 40
        // Object is received by the server.
        case synced = 50
        // Object is hard-deleted.
        case deletedHard = 60
        // Object is soft-deleted.
        case deletedSoft = 70
        // Object is a deletion range marker synchronized with the server.
        case deletedSynced = 80

        public static func < (lhs: BaseDb.Status, rhs: BaseDb.Status) -> Bool {
            return lhs.rawValue < rhs.rawValue
        }
    }

    // Meta-status: object should be visible in the UI.
    public static let kStatusVisible = Status.synced

    public static let kBundleId = "com.budchat.im.db"
    public static let kAppGroupId = "group.com.budchat.im.db"
    // No direct access to the shared instance.
    private static var `default`: BaseDb?
    private static let accessQueue = DispatchQueue(label: BaseDb.kBundleId)
    var db: SQLite.Connection?
    // 判断用户是否已经通过登录. daxiong 2024-02-01
    private var hasLogin: Bool?
    private let pathToDatabase: String
    public var sqlStore: SqlStore?
    public var topicDb: TopicDb?
    public var accountDb: AccountDb?
    public var subscriberDb: SubscriberDb?
    public var userDb: UserDb?
    public var messageDb: MessageDb?
    public var loginfoDb: LoginfoDb?
    public var addressBookDb: ContactsDb?
    public var callLogDb: CallLogsDb?
    public var noticeDb: NoticeDb?
    public var groupDb: GroupDb?
    var account: StoredAccount?
    var isCredValidationRequired: Bool {
        return !(account?.credMethods?.isEmpty ?? true)
    }

    public var isReady: Bool {
        return account != nil && !isCredValidationRequired
    }

    static let log = Log(subsystem: BaseDb.kBundleId)

    /**
     * The init is private to ensure that the class is a singleton.
     * 多用户数据库模式。根据用户是否登录使用不同的数据库. daxiong 2024-02-01
     */
    private init() {
        var documentsDirectory = FileManager.default
            .containerURL(forSecurityApplicationGroupIdentifier: BaseDb.kAppGroupId)!.absoluteString
        if documentsDirectory.last! != "/" {
            documentsDirectory.append("/")
        }

        // 取消原有的单用户数据库模式代码. daxiong 2023-02-01
//        self.pathToDatabase = documentsDirectory.appending("database.sqlite")
//
//        do {
//            self.db = try SQLite.Connection(self.pathToDatabase)
//        } catch {
//            BaseDb.log.error("BaseDb - init failed: %@", error.localizedDescription)
//        }
//        assert(self.db != nil)
//
//        self.sqlStore = SqlStore(dbh: self)

        // 修改为多用户数据库模式. daxiong 2023-02-01
        if let token = SharedUtils.getAuthToken(), !token.isEmpty {
            if let userId = SharedUtils.getAuthUserId(), !userId.isEmpty {
                pathToDatabase = documentsDirectory.appending(userId + ".sqlite")
                hasLogin = true
            } else {
                pathToDatabase = documentsDirectory.appending("database.sqlite")
                hasLogin = false
            }
        } else {
            pathToDatabase = documentsDirectory.appending("database.sqlite")
            hasLogin = false
        }

        do {
            db = try SQLite.Connection(pathToDatabase)
        } catch {
            BaseDb.log.error("BaseDb - init failed: %@", error.localizedDescription)
        }
        assert(db != nil)

        if let hasLogin = hasLogin, hasLogin {
            sqlStore = SqlStore(dbh: self)
        }

        print("==multi-user database init db: \(pathToDatabase)")
    }

    private func initDb() {
        BaseDb.log.info("Initializing local store.")
        accountDb = AccountDb(db!)
        userDb = UserDb(db!, baseDb: self)
        topicDb = TopicDb(db!, baseDb: self)
        subscriberDb = SubscriberDb(db!, baseDb: self)
        messageDb = MessageDb(db!, baseDb: self)
        loginfoDb = LoginfoDb(db!, baseDb: self)
        addressBookDb = ContactsDb(db!, baseDb: self)
        callLogDb = CallLogsDb(db!, baseDb: self)
        noticeDb = NoticeDb(db!, baseDb: self)
        groupDb = GroupDb(db!, baseDb: self)
        var account: StoredAccount?
        var deviceToken: String?
        if db!.schemaVersion != BaseDb.kSchemaVersion {
            BaseDb.log.info("BaseDb - schema has changed from %d to %d", db?.schemaVersion ?? -1, BaseDb.kSchemaVersion)

            // Retain active account accross DB upgrades to keep user logged in.
            account = accountDb!.getActiveAccount()
            deviceToken = accountDb!.getDeviceToken()

            // Schema has changed, delete database.
            dropDb()
            db!.schemaVersion = BaseDb.kSchemaVersion
        }

        BaseDb.log.info("Creating SQLite db tables.")
        accountDb!.createTable()
        userDb!.createTable()
        topicDb!.createTable()
        subscriberDb!.createTable()
        messageDb!.createTable()
        loginfoDb!.createTable()
        addressBookDb!.createTable()
        callLogDb!.createTable()
        noticeDb!.createTable()
        groupDb!.createTable()
        // Enable foreign key enforcement.
        try! db!.run("PRAGMA foreign_keys = ON")

        if let account = account {
            _ = accountDb!.addOrActivateAccount(for: account.uid, withCredMethods: account.credMethods)
            accountDb!.saveDeviceToken(token: deviceToken)
        }
        self.account = accountDb!.getActiveAccount()
    }

    private func clearSequences() {
        let table = Table("sqlite_sequence")
        try! db!.run(table.delete())
    }

    private func clearDb() {
        BaseDb.log.info("Clearing local store (SQLite db).")
        try! db!.transaction {
            self.messageDb?.truncateTable()
            self.subscriberDb?.truncateTable()
            self.topicDb?.truncateTable()
            self.userDb?.truncateTable()
            self.loginfoDb?.truncateTable()
            self.addressBookDb?.truncateTable()
            self.callLogDb?.truncateTable()
            self.noticeDb?.truncateTable()
            self.groupDb?.truncateTable()
            /// accountDb需最后删除，其他数据库会依赖account
            self.accountDb?.truncateTable()
            self.clearSequences()
        }
    }

    private func dropDb() {
        BaseDb.log.info("Dropping local store (SQLite db).")
        messageDb?.destroyTable()
        subscriberDb?.destroyTable()
        topicDb?.destroyTable()
        userDb?.destroyTable()
        loginfoDb?.destroyTable()
        addressBookDb?.destroyTable()
        callLogDb?.destroyTable()
        noticeDb?.destroyTable()
        groupDb?.destroyTable()
        accountDb?.destroyTable()
    }

    /**
     * Get singleton instance
     * 多用户数据库模式。根据用户是否登录获取不同的数据库单例. TODO: 未来优化代码时，在用户没有登录前，不需要获取数据库单例. daxiong 2024-02-01
     */
    public static var sharedInstance: BaseDb {
        // 取消原有的单用户数据库模式代码. daxiong 2023-02-01
//        return BaseDb.accessQueue.sync {
//            if let instance = BaseDb.default {
//                return instance
//            }
//            let instance = BaseDb()
//            BaseDb.default = instance
//            instance.initDb()
//            return instance
//        }

        // 修改为多用户数据库模式. daxiong 2023-02-01
        return BaseDb.accessQueue.sync {
            if let instance = BaseDb.default {
                if let hasLogin = instance.hasLogin, let token = SharedUtils.getAuthToken(), !token.isEmpty && !hasLogin {
                    let instance = BaseDb()
                    BaseDb.default = instance
                    instance.initDb()
                    print("==multi-user database get instance 1: \(instance.pathToDatabase)")
                    return instance
                }
                // print("==multi-user database get instance 2: \(instance.pathToDatabase)")
                return instance
            }
            let instance = BaseDb()
            BaseDb.default = instance
            instance.initDb()
            print("==multi-user database get instance 3: \(instance.pathToDatabase)")
            return instance
        }
    }

    public func getDbPath() -> String {
        return pathToDatabase
    }

    func isMe(uid: String?) -> Bool {
        guard let uid = uid, let acctUid = BaseDb.sharedInstance.uid else { return false }
        return uid == acctUid
    }

    var uid: String? {
        return account?.uid
    }

    func setUid(uid: String?, credMethods: [String]?) {
        guard let uid = uid else {
            account = nil
            return
        }
        do {
            if account != nil {
                try accountDb?.deactivateAll()
            }
            account = accountDb?.addOrActivateAccount(for: uid, withCredMethods: credMethods)
        } catch {
            BaseDb.log.error("BaseDb - setUid failed %@", error.localizedDescription)
            account = nil
        }
    }

    public func logout() {
        // Drop database altogether.
        // Db will be recreated when the user logs back in.
        //
        // Data can also be retained by deactivating the account:
        //
        // _ = try? self.accountDb?.deactivateAll()
        // self.setUid(uid: nil, credMethods: nil)
        BaseDb.accessQueue.sync {
            self.setUid(uid: nil, credMethods: nil)
            // 取消代码，多用户数据库模式，不需要清理数据库. 224-02-01
            // self.clearDb()
            BaseDb.default = nil
        }
    }

    public func deleteUid(_ uid: String) -> Bool {
        var acc: StoredAccount?
        if self.uid == uid {
            acc = account
            account = nil
        } else {
            acc = accountDb?.getByUid(uid: uid)
        }
        guard let acc2 = acc else {
            BaseDb.log.error("Could not find account for uid [%@]", uid)
            return false
        }
        let savepointName = "BaseDb.deleteUid"
        do {
            try db?.savepoint(savepointName) {
                if !(self.topicDb?.deleteAll(forAccount: acc2.id) ?? true) {
                    BaseDb.log.error("Failed to clear topics/messages/subscribers for account id [%lld]", acc2.id)
                }
                if !(self.userDb?.delete(forAccount: acc2.id) ?? true) {
                    BaseDb.log.error("Failed to clear users for account id [%lld]", acc2.id)
                }
                if !(self.loginfoDb?.delete(forAccount: acc2.id) ?? true) {
                    BaseDb.log.error("Failed to delete loginfo for id [%lld]", acc2.id)
                }
                if !(self.addressBookDb?.delete(forAccount: acc2.id) ?? true) {
                    BaseDb.log.error("Failed to delete addressBook for id [%lld]", acc2.id)
                }
                if !(self.accountDb?.delete(accountId: acc2.id) ?? true) {
                    BaseDb.log.error("Failed to delete account for id [%lld]", acc2.id)
                }
                if !(self.callLogDb?.delete(forAccount: acc2.id) ?? true) {
                    BaseDb.log.error("Failed to delete account for id [%lld]", acc2.id)
                }
                if !(self.noticeDb?.delete(forAccount: acc2.id) ?? true) {
                    BaseDb.log.error("Failed to delete account for id [%lld]", acc2.id)
                }
                if !(self.groupDb?.delete(forAccount: acc2.id) ?? true) {
                    BaseDb.log.error("Failed to delete account for id [%lld]", acc2.id)
                }
            }
        } catch {
            // Explicitly releasing savepoint since ROLLBACK TO (SQLite.swift behavior) won't release the savepoint transaction.
            db?.releaseSavepoint(withName: savepointName)
            BaseDb.log.error("BaseDb - deleteUid operation failed: uid = %@, error = %@", uid, error.localizedDescription)
            return false
        }
        return true
    }

    public static func updateCounter(db: SQLite.Connection, table: Table,
                                     usingIdColumn idColumn: Expression<Int64>, forId id: Int64,
                                     in column: Expression<Int?>, with value: Int) -> Bool
    {
        let record = table.filter(idColumn == id && column < value)
        do {
            return try db.run(record.update(column <- value)) > 0
        } catch {
            if let result = error as? Result {
                // Skip logging "success" errors: they just mean the row was not found and some such.
                switch result {
                case .error:
                    return false
                }
            }
            BaseDb.log.error("BaseDb - updateCounter failed %@", error.localizedDescription)
            return false
        }
    }
}

// Database schema versioning.
public extension SQLite.Connection {
    var schemaVersion: Int32 {
        get { return Int32((try? scalar("PRAGMA user_version") as? Int64) ?? -1) }
        set { try! run("PRAGMA user_version = \(newValue)") }
    }

    /// Releases a savepoint explicitly.
    func releaseSavepoint(withName savepointName: String) {
        try? execute("RELEASE '\(savepointName)'")
    }
}
