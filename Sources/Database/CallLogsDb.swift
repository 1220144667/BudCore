//
//  CallLogsDb.swift
//  BudChatDB
//
//  Created by 洪陪 on 2024/3/1.
//  Copyright © 2024 BudChat LLC. All rights reserved.
//

import Foundation
import SQLite

public class CallLogsDb {
    public static let kTableName = "CallLogs"

    private let db: SQLite.Connection

    public let table: Table

    private let baseDb: BaseDb!

    public let id = Expression<Int64>("id")
    public let accountId = Expression<Int64?>("account_id")
    public let userId = Expression<String?>("userId")
    public let name = Expression<String?>("name")
    public let status = Expression<Int?>("status")
    public let timestamp = Expression<Int?>("timestamp")
    public let callType = Expression<Int?>("callType")

    public init(_ database: SQLite.Connection, baseDb: BaseDb) {
        db = database
        self.baseDb = baseDb
        table = Table(CallLogsDb.kTableName)
    }

    public func createTable() {
        let accountDb = baseDb.accountDb!
        // Must succeed.
        try! db.run(table.create(ifNotExists: true) { t in
            t.column(self.id, primaryKey: true)
            t.column(self.accountId, references: accountDb.table, accountDb.id)
            t.column(self.userId)
            t.column(self.name)
            t.column(self.status)
            t.column(self.timestamp)
            t.column(self.callType)
        })
        try! db.run(table.createIndex(accountId, accountId, ifNotExists: true))
    }

    public func truncateTable() {
        try! db.run(table.delete())
    }

    // 增
    public func insert(_ data: ChatCallLogData) -> Int64 {
        do {
            let rowid = try db.run(
                table.insert(
                    accountId <- baseDb.account?.id,
                    userId <- data.userId,
                    name <- data.name,
                    status <- data.status,
                    timestamp <- data.timestamp,
                    callType <- data.callType
                ))
            return rowid
        } catch SQLite.Result.error(message: let errMsg, code: let code, statement: _) {
            BaseDb.log.error("CallLogsDb - SQL error: code = %d, error = %@", code, errMsg)
            return -1
        } catch {
            BaseDb.log.error("CallLogsDb - insert operation failed: error = %@", error.localizedDescription)
            return -1
        }
    }

    // 删
    @discardableResult
    public func deleteRow(for timestamp: Int?) -> Bool {
        let id = getId(for: timestamp)
        let record = table.filter(self.id == id)
        do {
            return try db.run(record.delete()) > 0
        } catch {
            BaseDb.log.error("CallLogsDb - deleteRow operation failed: userId = %lld, error = %@", timestamp ?? "", error.localizedDescription)
            return false
        }
    }

    public func getId(for timestamp: Int?) -> Int64 {
        guard let accountId = baseDb.account?.id else {
            return -1
        }
        if let row = try? db.pluck(table.select(id).filter(self.timestamp == timestamp && self.accountId == accountId)) {
            return row[id]
        }
        return -1
    }

    public func delete(forAccount accountId: Int64? = nil) -> Bool {
        var accountId = accountId
        if accountId == nil {
            accountId = baseDb.account?.id
        }

        let record = table.filter(self.accountId == accountId)
        do {
            return try db.run(record.delete()) > 0
        } catch {
            BaseDb.log.error("CallLogsDb - delete(forAccount) operation failed: accountId = %lld, error = %@", accountId ?? -1, error.localizedDescription)
            return false
        }
    }

    public func destroyTable() {
        try! db.run(table.dropIndex(accountId, ifExists: true))
        try! db.run(table.drop(ifExists: true))
    }

    // 查
    public func queryAllLogs() -> [ChatCallLogData] {
        guard let accountId = baseDb.account?.id else { return [] }
        var query = table.select(table[*])
        query = query.where(self.accountId == accountId)
        do {
            var logs = [ChatCallLogData]()
            let caches = try db.prepare(query).reversed()
            for row in caches {
                logs.append(rowToData(row: row))
            }
            return logs
        } catch {
            BaseDb.log.error("CallLogsDb - read operation failed: error = %@", error.localizedDescription)
        }
        return []
    }

    public func query(limit: Int?, offset: Int?) -> [ChatCallLogData] {
        return query(select: [table[*]], limit: limit, offset: offset)
    }

    public func query(filter: Expression<Bool>? = nil, select: [Expressible] = [rowid], order: [Expressible] = [], limit: Int? = nil, offset: Int? = nil) -> [ChatCallLogData] {
        var query = table.select(select).order(order)
        if let f = filter {
            query = query.filter(f)
        }
        if let l = limit {
            if let o = offset {
                query = query.limit(l, offset: o)
            } else {
                query = query.limit(l)
            }
        }
        var logs = [ChatCallLogData]()
        do {
            let caches = try db.prepare(query).reversed()
            for row in caches {
                logs.append(rowToData(row: row))
            }
        } catch {
            BaseDb.log.error("CallLogsDb - read operation failed: error = %@", error.localizedDescription)
        }
        return logs
    }

    private func rowToData(row: Row) -> ChatCallLogData {
        var callData = ChatCallLogData()
        callData.userId = row[userId]
        callData.name = row[name]
        callData.status = row[status]
        callData.timestamp = row[timestamp]
        callData.callType = row[callType]
        return callData
    }

    // 改
    public func update(id: Int64, data: ChatCallLogData) {
        let update = table.filter(rowid == id)
        if let count = try? db.run(update.update(userId <- data.userId,
                                                 name <- data.name,
                                                 status <- data.status,
                                                 timestamp <- data.timestamp,
                                                 callType <- data.callType))
        {
            BaseDb.log.error("修改的结果为：%@", count == 1)
        } else {
            BaseDb.log.error("修改失败")
        }
    }
}

public struct ChatCallLogData: Codable {
    public var userId: String?
    public var name: String?
    public var status: Int? // 1呼出 2收到
    public var timestamp: Int?
    public var callType: Int? // 1语音 2视频

    public init(userId: String? = nil, name: String? = nil, status: Int? = nil, timestamp: Int? = nil, callType: Int? = nil) {
        self.userId = userId
        self.name = name
        self.status = status
        self.timestamp = timestamp
        self.callType = callType
    }
}
