//
//  ContactsDb.swift
//  BudChatDB
//
//  Created by lai A on 2024/1/9.
//  Copyright © 2024 BudChat LLC. All rights reserved.
//

import Foundation
import SQLite

public struct AddressBookEntity: Codable {
    public var userId: String?
    public var name: String?
    public var head: String?
    public var phone: String?
    public var relation: String?
    public var desc: String?
    public var selected: Bool?

    public init(userId: String? = nil,
                name: String? = nil,
                head: String? = nil,
                phone: String? = nil,
                relation: String? = nil,
                desc: String? = nil,
                selected _: Bool? = nil)
    {
        self.userId = userId
        self.name = name
        self.head = head
        self.phone = phone
        self.relation = relation
        self.desc = desc
    }
}

public class ContactsDb {
    public static let kTableName = "com.addressbook.bud"

    public static let kNoAddressBook = "NONE"

    private let db: SQLite.Connection

    public let table: Table

    public let id = Expression<Int64>("id")
    public let accountId = Expression<Int64?>("account_id")
    public let userId = Expression<String?>("userId")
    public let name = Expression<String?>("name")
    public let head = Expression<String?>("head")
    public let mobile = Expression<String?>("mobile")
    public let relation = Expression<String?>("relation")
    public let desc = Expression<String?>("desc")

    private let baseDb: BaseDb!

    init(_ database: SQLite.Connection, baseDb: BaseDb) {
        db = database
        self.baseDb = baseDb
        table = Table(ContactsDb.kTableName)
    }

    func destroyTable() {
        try! db.run(table.dropIndex(accountId, ifExists: true))
        try! db.run(table.drop(ifExists: true))
    }

    func createTable() {
        let accountDb = baseDb.accountDb!
        // Must succeed.
        try! db.run(table.create(ifNotExists: true) { t in
            t.column(self.id, primaryKey: .autoincrement)
            t.column(self.accountId, references: accountDb.table, accountDb.id)
            t.column(self.userId)
            t.column(self.name)
            t.column(self.head)
            t.column(self.mobile)
            t.column(self.relation)
            t.column(self.desc)
        })
        try! db.run(table.createIndex(accountId, ifNotExists: true))
    }

    public func truncateTable() {
        try! db.run(table.delete())
    }

    @discardableResult public func insert(addressBook: AddressBookEntity?) -> Int64 {
        guard let addressBook = addressBook else { return 0 }
        return insert(userId: addressBook.userId,
                      name: addressBook.name,
                      head: addressBook.head,
                      phone: addressBook.phone,
                      relation: addressBook.relation,
                      desc: addressBook.desc)
    }

    func insert(userId: String?,
                name: String?,
                head: String?,
                phone: String?,
                relation: String?,
                desc: String?) -> Int64
    {
        guard let userId = userId else { return -1 }
        guard let id = getId(userId) else {
            do {
                let desc = (desc ?? "").isEmpty ? ContactsDb.kNoAddressBook : desc!
                let rowid = try db.run(
                    table.insert(
                        accountId <- baseDb.account?.id,
                        self.userId <- userId,
                        self.name <- name,
                        self.head <- head,
                        mobile <- phone,
                        self.relation <- relation,
                        self.desc <- desc
                    ))
                return rowid
            } catch SQLite.Result.error(message: let errMsg, code: let code, statement: _) {
                BaseDb.log.error("AddressBookDb - SQL error: phoneNumber = %@, desc = %@, code = %d, error = %@", userId, code, errMsg)
                return -1
            } catch {
                BaseDb.log.error("AddressBookDb - insert operation failed: phoneNumber = %@, desc = %@, error = %@", userId, error.localizedDescription)
                return -1
            }
        }
        return update(id: id, userId, name, head, phone, relation, desc)
    }

    // 获取row
    public func getRow(_ userId: String) -> Row? {
        let query = table.select(id).filter(self.userId == userId)
        if let row = try? db.pluck(query) {
            return row
        }
        return nil
    }

    public func getId(_ userId: String) -> Int64? {
        guard let row = getRow(userId) else { return nil }
        return row[id]
    }

    public func update(id: Int64,
                       _ userId: String?,
                       _ name: String?,
                       _ head: String?,
                       _ phone: String?,
                       _ relation: String?,
                       _ desc: String?) -> Int64
    {
        do {
            let update = table.filter(self.id == id)
            let rowid = try db.run(update.update(accountId <- baseDb.account?.id,
                                                 self.userId <- userId,
                                                 self.name <- name,
                                                 self.head <- head,
                                                 mobile <- phone,
                                                 self.relation <- relation,
                                                 self.desc <- desc))
            return Int64(rowid)
        } catch SQLite.Result.error(message: let errMsg, code: let code, statement: _) {
            BaseDb.log.error("GroupDb - SQL error: code = %d, error = %@", code, errMsg)
            return -1
        } catch {
            BaseDb.log.error("GroupDb - insert operation failed: error = %@", error.localizedDescription)
            return -1
        }
    }

    @discardableResult
    public func delete(for userId: String) -> Bool {
        guard let id = getId(userId) else { return false }
        return delete(id: id)
    }

    @discardableResult
    public func delete(id: Int64) -> Bool {
        let record = table.filter(self.id == id)
        do {
            return try db.run(record.delete()) > 0
        } catch {
            BaseDb.log.error("AddressBookDb - deleteRow operation failed: userId = %lld, error = %@", id, error.localizedDescription)
            return false
        }
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
            BaseDb.log.error("AddressBookDb - delete(forAccount) operation failed: accountId = %lld, error = %@", accountId ?? -1, error.localizedDescription)
            return false
        }
    }

    private func rowToAddressBook(r: Row) -> AddressBookEntity? {
        let userId = r[self.userId]
        let name = r[self.name]
        let head = r[self.head]
        let phone = r[mobile]
        let relation = r[self.relation]
        let desc = r[self.desc]
        let addressBookEntity = AddressBookEntity(userId: userId,
                                                  name: name,
                                                  head: head,
                                                  phone: phone,
                                                  relation: relation,
                                                  desc: desc)
        return addressBookEntity
    }

    public func readOne(phone: String?) -> AddressBookEntity? {
        guard let accountId = baseDb.account?.id else {
            return nil
        }
        let phone = phone ?? ContactsDb.kNoAddressBook
        guard let row = try? db.pluck(table.filter(mobile == phone && self.accountId == accountId)) else {
            return nil
        }
        return rowToAddressBook(r: row)
    }

    // Generic reader
    public func read(phones: [String]) -> ([AddressBookEntity]?, [String]?) {
        guard !phones.isEmpty else { return (nil, nil) }

        guard let accountId = baseDb.account?.id else {
            return (nil, nil)
        }
        var query = table.select(table[*])
        query = query.where(self.accountId == accountId && phones.contains(mobile))
        do {
            var entities = [AddressBookEntity]()
            for r in try db.prepare(query) {
                if let u = rowToAddressBook(r: r) {
                    entities.append(u)
                }
            }

            let noCachePhones = phones.filter { phone in
                !entities.contains(where: { $0.phone == phone })
            }

            return (entities, noCachePhones)
        } catch {
            BaseDb.log.error("AddressBookDb - read operation failed: error = %@", error.localizedDescription)
        }
        return (nil, nil)
    }

    public func readContacts() -> [AddressBookEntity] {
        guard let accountId = baseDb.account?.id else { return [] }
        let query = table.select(table[*]).where(self.accountId == accountId)
        do {
            var entities = [AddressBookEntity]()
            for r in try db.prepare(query) {
                if let u = rowToAddressBook(r: r) {
                    entities.append(u)
                }
            }
            return entities
        } catch {
            BaseDb.log.error("AddressBookDb - read operation failed: error = %@", error.localizedDescription)
            return []
        }
    }

    public func query(_ keyword: String, limit: Int?, offset: Int?) -> [AddressBookEntity]? {
        guard let accountId = baseDb.account?.id else { return [] }
        // 查询语句
        let likes = "%" + keyword + "%"
        let filter = name.like(likes) || mobile.like(likes)
        var query = table.select(table[*]).filter(filter).where(self.accountId == accountId).order(name.desc)
        if let l = limit, let o = offset {
            query = query.limit(l, offset: o)
        }
        // 开始查询
        do {
            var list: [AddressBookEntity] = []
            for row in try db.prepare(query) {
                if let sm = rowToAddressBook(r: row) {
                    list.append(sm)
                }
            }
            return list
        } catch SQLite.Result.error(message: let errMsg, code: let code, statement: _) {
            BaseDb.log.error("AddressBookDb - query SQLite error: code = %d, error = %@", code, errMsg)
            return nil
        } catch {
            BaseDb.log.error("AddressBookDb - query operation failed: error = %@", error.localizedDescription)
            return nil
        }
    }
}
