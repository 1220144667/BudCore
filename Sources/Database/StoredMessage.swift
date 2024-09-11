//
//  StoredMessage.swift
//  ios
//
//  Copyright © 2019 BudChat. All reserved.
//

import Foundation

public class StoredMessage: MsgServerData, Message {
    public var msgId: Int64 = 0

    public var seqId: Int { return seq ?? 0 }

    var topicId: Int64?
    var userId: Int64?

    var dbStatus: BaseDb.Status?
    public var status: Int? {
        return dbStatus?.rawValue
    }

    public var isDraft: Bool { return dbStatus == .draft }
    public var isReady: Bool { return dbStatus == .queued }
    public var isDeleted: Bool {
        return dbStatus == .deletedHard || dbStatus == .deletedSoft || dbStatus == .deletedSynced
    }

    public func isDeleted(hard: Bool) -> Bool {
        return hard ?
            dbStatus == .deletedHard :
            dbStatus == .deletedSoft
    }

    public var isSynced: Bool { return dbStatus == .synced }

    /// Message has not been delivered to the server yet.
    public var isPending: Bool { return dbStatus == nil || dbStatus! <= .sending }

    /// True if message was forwarded from another topic.
    public var isForwarded: Bool {
        return !(head?["forwarded"]?.asString()?.isEmpty ?? true)
    }

    /// True if message has been edited.
    public var isEdited: Bool {
        return head?["replace"] != nil && head?["webrtc"] == nil
    }

    /// True if the acount owner is the author of the message.
    public var isMine: Bool {
        return BaseDb.sharedInstance.isMe(uid: from)
    }

    /// Cached representation of message content as attributed string.
    public var cachedContent: NSAttributedString?

    /// Cached representation of message preview as attributed string.
    public var cachedPreview: NSAttributedString?

    // MARK: initializers

    override public init() { super.init() }

    convenience init(from m: MsgServerData) {
        self.init()
        topic = m.topic
        head = m.head
        from = m.from
        ts = m.ts
        seq = m.seq
        content = m.content
    }

    convenience init(from m: MsgServerData, status: BaseDb.Status) {
        self.init(from: m)
        dbStatus = status
    }

    required init(from _: Decoder) throws {
        fatalError("init(from:) has not been implemented")
    }

    // Makes a shallow copy of self.
    public func copyOf() -> StoredMessage {
        let cp = StoredMessage(from: self)
        cp.msgId = msgId
        cp.topicId = topicId
        cp.userId = userId
        cp.dbStatus = dbStatus
        cp.cachedContent = cachedContent
        cp.cachedPreview = cachedPreview
        return cp
    }
}
