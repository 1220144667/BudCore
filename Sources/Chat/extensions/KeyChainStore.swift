//
//  KeyChainStore.swift
//
//
//  Created by 文伍 on 2024/9/7.
//

import Foundation

struct KeyChainStore {
    
    static let instance = KeyChainStore()
    private init() {}
    
    func getKeychainQuery(_ service: String) -> [String: Any] {
        let service = kSecAttrService as String
        let account = kSecAttrAccount as String
        let object = kSecClass as String
        return [service: service, account: service, object: service]
    }
    
}
