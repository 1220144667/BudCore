//
//  LoginfoDb.swift
//  BudChatDB
//
//  Created by lai A on 2023/11/14.
//  Copyright © 2023 BudChat LLC. All rights reserved.
//

import Foundation
import SQLite

public struct LogupContentEntity: Codable {
    private static var req_id_int = 0xFFFF + Int((Float(arc4random()) / Float(UInt32.max)) * 0xFFFF)

    public var req_id: String?
    public var createdat: Int64?
    public var type: String?
    public var status: String?
    public var info: [String: String]?

    public init(req_id: String? = nil,
                createdat: Int64? = nil,
                type: String? = nil,
                status: String? = nil,
                info: [String: String]? = nil)
    {
        self.req_id = req_id
        self.createdat = createdat
        self.type = type
        self.status = status
        self.info = info
    }

    public init(type: String? = nil,
                status: String? = nil,
                info: [String: String]? = nil)
    {
        req_id = getNextReq_id()
        createdat = Date().millisecondsSince1970
        self.type = type
        self.status = status
        self.info = info
    }

    private mutating func getNextReq_id() -> String {
        LogupContentEntity.req_id_int += 1
        return String(LogupContentEntity.req_id_int)
    }
}

extension Date {
    func string(withFormat format: String = "dd/MM/yyyy HH:mm") -> String {
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = format
        return dateFormatter.string(from: self)
    }

    var millisecondsSince1970: Int64 {
        return Int64((timeIntervalSince1970 * 1000.0).rounded())
    }
}

extension Dictionary {
    func getJSONStringFromDictionary() -> String {
        if !JSONSerialization.isValidJSONObject(self) {
            return String()
        }
        let data: NSData! = try? JSONSerialization.data(withJSONObject: self, options: []) as NSData?
        let JSONString = NSString(data: data as Data, encoding: String.Encoding.utf8.rawValue)
        return JSONString! as String
    }

    static func getDictionaryFromJSONString(_ jsonString: String) -> [String: Any]? {
        let jsonData: Data = jsonString.data(using: .utf8)!
        let dictionary = try? JSONSerialization.jsonObject(with: jsonData, options: .mutableContainers)
        if dictionary != nil {
            return dictionary as? [String: Any]
        }
        return dictionary as? [String: Any]
    }
}

public class LoginfoDb {
    public static let kTableName = "loginfo"
    // Fake UID for "no user" user.
    private static let kNoLoginfo = "NONE"

    private let db: SQLite.Connection

    public let table: Table

    public let id: Expression<Int64>
    public let req_id: Expression<String>
    public let accountId: Expression<Int64?>
    public let createdat: Expression<String?>
    public let type: Expression<String?>
    public let status: Expression<String?>
    public let info: Expression<String?>

    private let baseDb: BaseDb!

    init(_ database: SQLite.Connection, baseDb: BaseDb) {
        db = database
        self.baseDb = baseDb
        table = Table(LoginfoDb.kTableName)
        id = Expression<Int64>("id")
        accountId = Expression<Int64?>("account_id")
        req_id = Expression<String>("req_id")
        createdat = Expression<String?>("createdat")
        type = Expression<String?>("type")
        status = Expression<String?>("status")
        info = Expression<String?>("info")
    }

    func destroyTable() {
        try! db.run(table.dropIndex(accountId, req_id, ifExists: true))
        try! db.run(table.drop(ifExists: true))
    }

    func createTable() {
        let accountDb = baseDb.accountDb!
        // Must succeed.
        try! db.run(table.create(ifNotExists: true) { t in
            t.column(self.id, primaryKey: .autoincrement)
            t.column(self.accountId, references: accountDb.table, accountDb.id)
            t.column(self.req_id)
            t.column(self.createdat)
            t.column(self.type)
            t.column(self.status)
            t.column(self.info)
        })
        try! db.run(table.createIndex(accountId, ifNotExists: true))
    }

    // Deletes all records from `users` table.
    public func truncateTable() {
        try! db.run(table.delete())
    }

    public func insert(entity: LogupContentEntity?) -> Int64 {
        guard let entity = entity else { return 0 }
        let infoString = entity.info?.getJSONStringFromDictionary()

        var createdatString = ""
        if let createdatValue = entity.createdat {
            createdatString = "\(createdatValue)"
        }

        let id = insert(req_id: entity.req_id, createdat: createdatString, type: entity.type, status: entity.status, info: infoString)
        return id
    }

    func insert(req_id: String?,
                createdat: String?,
                type: String?,
                status: String?,
                info: String?) -> Int64
    {
        let req_id = (req_id ?? "").isEmpty ? LoginfoDb.kNoLoginfo : req_id!
        do {
            let rowid = try db.run(
                table.insert(
                    accountId <- baseDb.account?.id,
                    self.req_id <- req_id,
                    self.createdat <- createdat,
                    self.type <- type,
                    self.status <- status,
                    self.info <- info
                ))
            return rowid
        } catch SQLite.Result.error(message: let errMsg, code: let code, statement: _) {
            BaseDb.log.error("LoginfoDb - SQL error: uid = %@, code = %d, error = %@", req_id, code, errMsg)
            return -1
        } catch {
            BaseDb.log.error("LoginfoDb - insert operation failed: uid = %@, error = %@", req_id, error.localizedDescription)
            return -1
        }
    }

    @discardableResult
    public func deleteRow(for id: Int64) -> Bool {
        let record = table.filter(self.id == id)
        do {
            return try db.run(record.delete()) > 0
        } catch {
            BaseDb.log.error("LoginfoDb - deleteRow operation failed: userId = %lld, error = %@", id, error.localizedDescription)
            return false
        }
    }

    public func delete(forAccount accountId: Int64?) -> Bool {
        var tempAccountId: Int64?
        if accountId == nil {
            if let account_Id = baseDb.account?.id {
                tempAccountId = account_Id
            }
        } else {
            tempAccountId = accountId
        }

        let record = table.filter(self.accountId == tempAccountId)
        do {
            return try db.run(record.delete()) > 0
        } catch {
            BaseDb.log.error("LoginfoDb - delete(forAccount) operation failed: accountId = %lld, error = %@", tempAccountId ?? -1, error.localizedDescription)
            return false
        }
    }

    public func getId(for req_id: String?) -> Int64 {
        let req_id = req_id ?? LoginfoDb.kNoLoginfo
        if let row = try? db.pluck(table.select(self.req_id).filter(self.req_id == req_id)) {
            return row[id]
        }
        return -1
    }

    private func rowToUser(r: Row) -> LogupContentEntity? {
        let req_id = r[self.req_id]
        let createdat = r[self.createdat]
        let status = r[self.status]
        let type = r[self.type]

        var infoDic: [String: String]?
        if let info = r[info], let dic = Dictionary<String, String>.getDictionaryFromJSONString(info) as? [String: String] {
            infoDic = dic
        }

        let createdatInt = Int64(createdat ?? "")

        let entity = LogupContentEntity(req_id: req_id, createdat: createdatInt, type: type, status: status, info: infoDic)
        return entity
    }

    public func readOne(req_id: String?) -> LogupContentEntity? {
        let req_id = req_id ?? LoginfoDb.kNoLoginfo
        guard let row = try? db.pluck(table.filter(self.req_id == req_id)) else {
            return nil
        }
        return rowToUser(r: row)
    }

    // Generic reader
    private func read() -> [LogupContentEntity]? {
        guard let accountId = baseDb.account?.id else {
            return nil
        }
        var query = table.select(table[*])
        query = query.where(self.accountId == accountId)
        do {
            var entities = [LogupContentEntity]()
            for r in try db.prepare(query) {
                if let u = rowToUser(r: r) {
                    entities.append(u)
                }
            }
            return entities
        } catch {
            BaseDb.log.error("LoginfoDb - read operation failed: error = %@", error.localizedDescription)
        }
        return nil
    }

    // Select all users except given user.
    public func readAllCurrentAccount() -> [LogupContentEntity]? {
        return read()
    }
}
