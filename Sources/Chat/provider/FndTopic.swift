//
//  FndTopic.swift
//  TinodeSDK
//
//  Copyright © 2020-2022 BudChat LLC. All rights reserved.
//

import Foundation

public class FndTopic<SP: Codable>: Topic<String, String, SP, [String]> {
    init(tinode: BudChat?) {
        super.init(bud: tinode, name: BudChat.kTopicFnd)
    }

    @discardableResult
    override public func setMeta(meta: MsgSetMeta<String, String>) -> PromisedReply<ServerMessage> {
        if subs != nil {
            subs!.removeAll()
            subs = nil
            subsLastUpdated = nil
            listener?.onSubsUpdated()
        }
        return super.setMeta(meta: meta)
    }

    override func routeMetaSub(meta: MsgServerMeta) {
        if let subscriptions = meta.sub {
            for upd in subscriptions {
                var sub = getSubscription(for: upd.uniqueId)
                if sub != nil {
                    _ = sub!.merge(sub: upd as! Subscription<SP, [String]>)
                } else {
                    sub = upd as? Subscription<SP, [String]>
                    addSubToCache(sub: sub!)
                }
                listener?.onMetaSub(sub: sub!)
            }
        }
        listener?.onSubsUpdated()
    }

    override public func getSubscriptions() -> [Subscription<SP, [String]>]? {
        guard let v = subs?.values else { return nil }
        return Array(v)
    }

    override func addSubToCache(sub: Subscription<SP, [String]>) {
        guard let unique = sub.user ?? sub.topic else { return }

        if subs == nil {
            subs = [:]
        }
        subs![unique] = sub
    }
}
