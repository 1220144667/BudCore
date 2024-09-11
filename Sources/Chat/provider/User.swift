//
//  User.swift
//  ios
//
//  Copyright © 2019 BudChat. All reserved.
//

import Foundation

public protocol UserProto: AnyObject {
    var updated: Date? { get set }
    var uid: String? { get set }
    var payload: Payload? { get set }

    func serializePub() -> String?
    static func createFromPublicData(uid: String?, updated: Date?, data: String?) -> UserProto?
}

public extension UserProto {
    static func createFromPublicData(uid: String?, updated: Date?, data: String?) -> UserProto? {
        guard let data = data else { return nil }
        if let p: TheCard = BudChat.deserializeObject(from: data) {
            return User(uid: uid, updated: updated, pub: p)
        }
        if let p: String = BudChat.deserializeObject(from: data) {
            return User(uid: uid, updated: updated, pub: p)
        }
        return nil
    }
}

public typealias DefaultUser = User<TheCard>

public class User<P: Codable>: UserProto {
    enum UserError: Error {
        case invalidUser(String)
    }

    public var updated: Date?
    public var uid: String?
    public var pub: P?
    public var payload: Payload?

    public init(uid: String?, updated: Date?, pub: P?) {
        self.uid = uid
        self.updated = updated
        self.pub = pub
    }

    public init<R: Decodable>(uid: String?, desc: Description<P, R>) {
        self.uid = uid
        updated = desc.updated
        pub = desc.pub
    }

    public init<R: Decodable>(sub: Subscription<P, R>) throws {
        if let uid = sub.user, !uid.isEmpty {
            self.uid = uid
            updated = sub.updated
            pub = sub.pub
        } else {
            throw UserError.invalidUser("Invalid subscription param: missing uid")
        }
    }

    public func serializePub() -> String? {
        guard let p = pub else { return nil }
        return BudChat.serializeObject(p)
    }

    func merge(from user: User<P>) -> Bool {
        var changed = false
        if user.updated != nil && (updated == nil || updated! < user.updated!) {
            updated = user.updated
            if user.pub != nil {
                pub = user.pub
            }
            changed = true
        } else if pub == nil && user.pub != nil {
            pub = user.pub
            changed = true
        }
        return changed
    }

    public func merge<DR: Decodable>(from desc: Description<P, DR>) -> Bool {
        var changed = false
        if desc.updated != nil && (updated == nil || updated! < desc.updated!) {
            updated = desc.updated
            if desc.pub != nil {
                pub = desc.pub
            }
            changed = true
        } else if pub == nil && desc.pub != nil {
            pub = desc.pub
            changed = true
        }
        return changed
    }

    func merge<DR: Decodable>(from sub: Subscription<P, DR>) -> Bool {
        var changed = false
        if sub.updated != nil && (updated == nil || updated! < sub.updated!) {
            updated = sub.updated
            if sub.pub != nil {
                pub = sub.pub
            }
            changed = true
        } else if pub == nil && sub.pub != nil {
            pub = sub.pub
            changed = true
        }
        return changed
    }
}
