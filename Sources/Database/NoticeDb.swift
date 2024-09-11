//
//  NoticeDb.swift
//  BudChatDB
//
//  Created by 洪陪 on 2024/2/26.
//  Copyright © 2024 BudChat LLC. All rights reserved.
//

import Foundation
import SQLite

public class NoticeDb {
    public static let kTableName = "NoticeLogs"

    private let db: SQLite.Connection

    public let table: Table

    private let baseDb: BaseDb!

    public let id = Expression<Int64>("id")
    public let accountId = Expression<Int64?>("account_id")
    public let momentId = Expression<String?>("momentId")
    public let ts = Expression<String?>("ts")
    public let type = Expression<String?>("type")
    public let xfrom = Expression<String?>("xfrom")
    public let content = Expression<String?>("content")

    public init(_ database: SQLite.Connection, baseDb: BaseDb) {
        db = database
        self.baseDb = baseDb
        table = Table(NoticeDb.kTableName)
    }

    public func createTable() {
        let accountDb = baseDb.accountDb!
        // Must succeed.
        try! db.run(table.create(ifNotExists: true) { t in
            t.column(self.id, primaryKey: true)
            t.column(self.accountId, references: accountDb.table, accountDb.id)
            t.column(self.momentId)
            t.column(self.ts)
            t.column(self.type)
            t.column(self.xfrom)
            t.column(self.content)
        })
        try! db.run(table.createIndex(accountId, accountId, ifNotExists: true))
    }

    public func truncateTable() {
        try! db.run(table.delete())
    }

    // 增
    public func insert(_ data: NoticeData) -> Int64 {
        do {
            let rowid = try db.run(
                table.insert(
                    accountId <- baseDb.account?.id,
                    momentId <- data.momentId,
                    ts <- data.ts,
                    type <- data.type,
                    xfrom <- data.xfrom,
                    content <- data.content
                ))
            return rowid
        } catch SQLite.Result.error(message: let errMsg, code: let code, statement: _) {
            BaseDb.log.error("NoticeDb - SQL error: code = %d, error = %@", code, errMsg)
            return -1
        } catch {
            BaseDb.log.error("NoticeDb - insert operation failed: error = %@", error.localizedDescription)
            return -1
        }
    }

    // 删
    @discardableResult
    public func deleteRow(for momentId: String?) -> Bool {
        let id = getId(for: momentId)
        let record = table.filter(self.id == id)
        do {
            return try db.run(record.delete()) > 0
        } catch {
            BaseDb.log.error("NoticeDb - deleteRow operation failed: userId = %lld, error = %@", momentId ?? "", error.localizedDescription)
            return false
        }
    }

    public func getId(for momentId: String?) -> Int64 {
        guard let accountId = baseDb.account?.id else {
            return -1
        }
        if let row = try? db.pluck(table.select(id).filter(self.momentId == momentId && self.accountId == accountId)) {
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
            BaseDb.log.error("NoticeDb - delete(forAccount) operation failed: accountId = %lld, error = %@", accountId ?? -1, error.localizedDescription)
            return false
        }
    }

    public func destroyTable() {
        try! db.run(table.dropIndex(accountId, ifExists: true))
        try! db.run(table.drop(ifExists: true))
    }

    // 查
    public func queryLogs() -> [NoticeData] {
        guard let accountId = baseDb.account?.id else { return [] }
        var query = table.select(table[*])
        query = query.where(self.accountId == accountId)
        do {
            var logs = [NoticeData]()
            for row in try db.prepare(query).reversed() {
                logs.append(rowToData(row: row))
            }
            return logs
        } catch {
            BaseDb.log.error("NoticeDb - read operation failed: error = %@", error.localizedDescription)
        }
        return []
    }

    public func query(limit: Int? = nil, offset: Int? = nil) -> [NoticeData] {
        return query(select: [table[*]], limit: limit, offset: offset)
    }

    public func query(filter: Expression<Bool>? = nil, select: [Expressible] = [rowid], order: [Expressible] = [], limit: Int? = nil, offset: Int? = nil) -> [NoticeData] {
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
        var logs = [NoticeData]()
        do {
            for row in try db.prepare(query).reversed() {
                logs.append(rowToData(row: row))
            }
        } catch {
            BaseDb.log.error("NoticeDb - read operation failed: error = %@", error.localizedDescription)
        }
        return logs
    }

    private func rowToData(row: Row) -> NoticeData {
        var callData = NoticeData()
        callData.momentId = row[momentId]
        callData.ts = row[ts]
        callData.type = row[type]
        callData.xfrom = row[xfrom]
        callData.content = row[content]
        return callData
    }

    // 改
    public func update(id: Int64, data: NoticeData) {
        let update = table.filter(rowid == id)
        if let count = try? db.run(update.update(momentId <- data.momentId,
                                                 ts <- data.ts,
                                                 type <- data.type,
                                                 xfrom <- data.xfrom,
                                                 content <- data.content))
        {
            BaseDb.log.error("修改的结果为：%@", count == 1)
        } else {
            BaseDb.log.error("修改失败")
        }
    }
}

public struct NoticeData: Codable {
    public var momentId: String? // 朋友圈id
    public var ts: String? // 返回时间
    public var type: String? // 1代表评论、2代表点赞、3表示@mention you
    public var xfrom: String? // 表示发通知的用户
    public var content: String? // 评论的内容

    public init(momentId: String? = nil, ts: String? = nil, type: String? = nil, xfrom: String? = nil, content: String? = nil) {
        self.momentId = momentId
        self.ts = ts
        self.type = type
        self.xfrom = xfrom
        self.content = content
    }
}
