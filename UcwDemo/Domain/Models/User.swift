//
//  User.swift
//  UcwDemo
//
//  Created by Yang.Bai on 2024/8/23.
//

import SwiftUI

enum UserRole: String {
    case Admin = "Admin";
    case Recovery = "Recovery";
    case Main = "Main";
    case Unspecified = "Unspecified";
    
    static func FromInt(l: Int) -> UserRole {
        var level: UserRole {
            switch l {
            case 1:
                return .Admin
            case 2:
                return .Main
            case 3:
                return .Recovery
            default:
                return .Unspecified
            }
        }
        return level
    }
}



public struct User {
    let userID: String
    let email: String
    
}

public struct UserNode: Identifiable {
    public var id: String { nodeID.appending(userID) }

    let userID: String
    let nodeID: String
    
    var userRole: UserRole
}

public class UserInfo: ObservableObject {
    @Published var user: User
    @Published var wallet: Wallet
    @Published var vault: Vault
    @Published var userNodes: [UserNode]
    
    init(user: User, wallet: Wallet, vault: Vault, userNodes: [UserNode]) {
        self.user = user
        self.wallet = wallet
        self.vault = vault
        self.userNodes = userNodes
    }
    
    public func KeyGenSuccess() -> Bool {
        return self.vault.status == .statusMainGenerated
    }
    
    func NodeRole(nodeID: String) -> UserRole {
        if let matchedNode = self.userNodes.first(where: { $0.nodeID == nodeID }) {
            return matchedNode.userRole
        }
        return .Unspecified
    }
}

