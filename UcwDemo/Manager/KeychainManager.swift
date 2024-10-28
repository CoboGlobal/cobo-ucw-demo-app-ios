//
//  KeyManager.swift
//  UcwDemo
//
//  Created by Yang.Bai on 2024/8/22.
//

import Foundation
import Security

class KeychainManager {
    static let standard = KeychainManager()
    
    func setPINCode(userID: String, pin: String) -> Bool {
        guard let data = pin.data(using: .utf8) else { return false }
        
        // Create query for new item
        let query: [CFString: Any] = [kSecClass: kSecClassGenericPassword,
                                kSecAttrAccount: "pinCode".appending(userID),
                                      kSecValueData: data]
        
        // Add new item to the Keychain
        let status = SecItemAdd(query as CFDictionary, nil)
        return status == errSecSuccess
    }
    
    func readPINCode(userID: String) -> String? {
        let query: [CFString: Any] = [kSecClass: kSecClassGenericPassword,
                                kSecAttrAccount: "pinCode".appending(userID),
                                      kSecReturnData: kCFBooleanTrue!,
                                      kSecMatchLimit: kSecMatchLimitOne]
        
        var item: CFTypeRef?
        let status = SecItemCopyMatching(query as CFDictionary, &item)
        
        if status == errSecSuccess, let data = item as? Data {
            return String(data: data, encoding: .utf8)
        }
        
        return nil
    }
    
    func setToken(token: String) -> Bool {
        guard let data = token.data(using: .utf8) else { return false }
        
        // Create query for new item
        let query: [CFString: Any] = [kSecClass: kSecClassGenericPassword,
                                      kSecAttrAccount: "token",
                                      kSecValueData: data]
        
        // Delete existing item if it exists
        let deletionStatus = SecItemDelete(query as CFDictionary)
        if deletionStatus != errSecSuccess && deletionStatus != errSecItemNotFound {
            print("Error deleting existing token: \(deletionStatus)")
            return false
        }
         
        // Create query for new item with data
        var newQuery = query
        newQuery[kSecValueData] = data
         
        // Add new item to the Keychain
        let addStatus = SecItemAdd(newQuery as CFDictionary, nil)
        return addStatus == errSecSuccess
    }
    
    func readToken() -> String? {
        let query: [CFString: Any] = [kSecClass: kSecClassGenericPassword,
                                      kSecAttrAccount: "token",
                                      kSecReturnData: kCFBooleanTrue!,
                                      kSecMatchLimit: kSecMatchLimitOne]
        
        var item: CFTypeRef?
        let status = SecItemCopyMatching(query as CFDictionary, &item)
        
        if status == errSecSuccess, let data = item as? Data {
            return String(data: data, encoding: .utf8)
        }
        
        return nil
    }
    
    func setPassword(userID: String, password: String) -> Bool {
        guard let data = password.data(using: .utf8) else { return false }

        // Create query for new item
        let passwordQuery: [CFString: Any] = [kSecClass: kSecClassGenericPassword,
                                        kSecAttrAccount: "nodePassword".appending(userID),
                                              kSecValueData: data]

        // Attempt to delete existing item if it exists
        SecItemDelete(passwordQuery as CFDictionary)

        // Add new item to the Keychain
        let status = SecItemAdd(passwordQuery as CFDictionary, nil)
           
        return status == errSecSuccess
    }

    func getPassword(userID: String) -> String? {
        let passwordQuery: [CFString: Any] = [kSecClass: kSecClassGenericPassword,
                                        kSecAttrAccount: "nodePassword".appending(userID),
                                              kSecReturnData: kCFBooleanTrue!,
                                              kSecMatchLimit: kSecMatchLimitOne]

        var item: CFTypeRef?
        let status = SecItemCopyMatching(passwordQuery as CFDictionary, &item)
           
        if status == errSecSuccess, let data = item as? Data {
            return String(data: data, encoding: .utf8)
        }
        return nil
    }
}
