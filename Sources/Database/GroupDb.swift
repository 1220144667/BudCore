//
//  GroupDb.swift
//  BudChatDB
//
//  Created by 洪陪 on 2024/3/26.
//  Copyright © 2024 BudChat LLC. All rights reserved.
//

import Foundation
import SQLite

public class GroupDb {
    public static let kTableName = "Groups"

    private let db: SQLite.Connection

    public let table: Table

    private let baseDb: BaseDb!

    public let id = Expression<Int64>("id")
    public let accountId = Expression<Int64?>("account_id")
    public let topic = Expression<String?>("Topic")
    public let membersNum = Expression<Int64?>("MembersNum")
    public let name = Expression<String?>("Name")
    public let groupId = Expression<String?>("groupId")

    public init(_ database: SQLite.Connection, baseDb: BaseDb) {
        db = database
        self.baseDb = baseDb
        table = Table(GroupDb.kTableName)
    }

    public func createTable() {
        let accountDb = baseDb.accountDb!
        // Must succeed.
        try! db.run(table.create(ifNotExists: true) { t in
            t.column(self.id, primaryKey: true)
            t.column(self.accountId, references: accountDb.table, accountDb.id)
            t.column(self.topic)
            t.column(self.membersNum)
            t.column(self.name)
            t.column(self.groupId)
        })
        try! db.run(table.createIndex(accountId, accountId, ifNotExists: true))
    }

    public func truncateTable() {
        try! db.run(table.delete())
    }

    // 增
    @discardableResult
    public func insert(_ name: String?, num: Int64?, topic: String?, groupId: String?) -> Int {
        guard let gid = groupId else { return -1 }
        guard let id = getId(gid) else {
            do {
                let rowid = try db.run(
                    table.insert(
                        accountId <- baseDb.account?.id,
                        self.name <- name,
                        self.topic <- topic,
                        membersNum <- num,
                        self.groupId <- groupId
                    ))
                return Int(rowid)
            } catch SQLite.Result.error(message: let errMsg, code: let code, statement: _) {
                BaseDb.log.error("GroupDb - SQL error: code = %d, error = %@", code, errMsg)
                return -1
            } catch {
                BaseDb.log.error("GroupDb - insert operation failed: error = %@", error.localizedDescription)
                return -1
            }
        }
        // 更新
        return update(id: id, name, num: num, topic: topic, groupId: groupId)
    }

    public func update(id: Int64, _ name: String?, num: Int64?, topic: String?, groupId: String?) -> Int {
        let update = table.filter(self.id == id)
        do {
            let rowid = try db.run(
                update.update(
                    accountId <- baseDb.account?.id,
                    self.name <- name,
                    self.topic <- topic,
                    membersNum <- num,
                    self.groupId <- groupId
                ))
            return rowid
        } catch SQLite.Result.error(message: let errMsg, code: let code, statement: _) {
            BaseDb.log.error("GroupDb - SQL error: code = %d, error = %@", code, errMsg)
            return -1
        } catch {
            BaseDb.log.error("GroupDb - insert operation failed: error = %@", error.localizedDescription)
            return -1
        }
    }

    // 删
    @discardableResult
    public func deleteRow(_ topic: String) -> Bool {
        guard let id = getId(topic) else { return false }
        let record = table.filter(self.id == id)
        do {
            return try db.run(record.delete()) > 0
        } catch {
            BaseDb.log.error("GroupDb - deleteRow operation failed, error = %@", error.localizedDescription)
            return false
        }
    }

    // 获取row
    public func getRow(_ topic: String) -> Row? {
        let query = table.select(id).filter(groupId == topic)
        if let row = try? db.pluck(query) {
            return row
        }
        return nil
    }

    public func getId(_ topic: String) -> Int64? {
        guard let row = getRow(topic) else { return nil }
        return row[id]
    }

    @discardableResult
    public func delete(forAccount accountId: Int64? = nil) -> Bool {
        var accountId = accountId
        if accountId == nil {
            accountId = baseDb.account?.id
        }

        let record = table.filter(self.accountId == accountId)
        do {
            return try db.run(record.delete()) > 0
        } catch {
            BaseDb.log.error("GroupDb - delete(forAccount) operation failed: accountId = %lld, error = %@", accountId ?? -1, error.localizedDescription)
            return false
        }
    }

    public func destroyTable() {
        try! db.run(table.dropIndex(accountId, ifExists: true))
        try! db.run(table.drop(ifExists: true))
    }

    // 查
    public func queryGroups() -> [GroupData] {
        guard let accountId = baseDb.account?.id else { return [] }
        var query = table.select(table[*])
        query = query.where(self.accountId == accountId)
        do {
            var logs = [GroupData]()
            for row in try db.prepare(query).reversed() {
                logs.append(rowToData(row: row))
            }
            return logs
        } catch {
            BaseDb.log.error("GroupDb - read operation failed: error = %@", error.localizedDescription)
        }
        return []
    }

    public func query(_ keyword: String, limit: Int? = nil, offset: Int? = nil) -> [GroupData]? {
        // 查询语句
        let likes = "%" + keyword + "%"
        var query = table.select(table[*]).filter(name.like(likes))
        if let l = limit, let o = offset {
            query = query.limit(l, offset: o)
        }
        // 开始查询
        do {
            var messages: [GroupData] = []
            for row in try db.prepare(query) {
                let sm = rowToData(row: row)
                messages.append(sm)
            }
            return messages
        } catch SQLite.Result.error(message: let errMsg, code: let code, statement: _) {
            BaseDb.log.error("GroupDb - query SQLite error: code = %d, error = %@", code, errMsg)
            return nil
        } catch {
            BaseDb.log.error("GroupDb - query operation failed: error = %@", error.localizedDescription)
            return nil
        }
    }

    private func rowToData(row: Row) -> GroupData {
        let topicJson = row[topic]
        var callData = GroupData()
        callData.Topic = decodeTopic(topicJson)
        callData.MembersNum = row[membersNum]
        return callData
    }

    private func decodeTopic(_ string: String?) -> GroupTopicData? {
        guard let json = string else { return nil }
        guard let data = json.data(using: .utf8) else { return nil }
        var topic: GroupTopicData?
        do {
            topic = try JSONDecoder().decode(GroupTopicData.self, from: data)
        } catch {
            print(error)
        }
        return topic
    }
}

public struct GroupData: Codable {
    public var Topic: GroupTopicData?
    public var MembersNum: Int64?

    public init(Topic: GroupTopicData? = nil, MembersNum: Int64? = nil) {
        self.Topic = Topic
        self.MembersNum = MembersNum
    }
}

public struct GroupTopicData: Codable {
    public var Id: String?
    public var CreatedAt: String?
    public var UpdatedAt: String?
    public var State: String?
    public var TouchedAt: String?
    public var UseBt: Bool?
    public var Owner: String?
    public var Name: String?
    public var Access: GroupAccessData?
    public var SeqId: Int64?
    public var DelId: Int64?
    public var Public: GroupPublicData?
}

public struct GroupAccessData: Codable {
    public var Auth: String?
    public var Anon: String?
}

public struct GroupPublicData: Codable {
    public var fn: String?
    public var photo: GroupPhotoData?
}

public struct GroupPhotoData: Codable {
    public var ref: String?
}
