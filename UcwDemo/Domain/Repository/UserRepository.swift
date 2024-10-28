//
//  UserRepository.swift
//  UcwDemo
//
//  Created by Yang.Bai on 2024/8/25.
//

import Foundation
import UcwGeneratedClient


protocol UserRepository {
    func login(email: String) async throws -> String
    func bindNode(nodeID: String) async throws -> UserNode
    func getUserInfo() async throws -> UserInfo
}


extension BackendClient: UserRepository {

    public func login(email: String) async throws -> String {
        let response = try await self.client().UserControlWallet_Login(.init(body: .json(.init(email: email))))
        switch response {
        case .ok(let okResponse):
            switch okResponse.body {
            case .json(let result):
                return result.token ?? ""
            }
            
        case .default(let statusCode, let defaultResponse):
            switch defaultResponse.body {
            case .json(let result):
                throw APIError.From(statusCode: statusCode, result: result)
            }
        }
    }
    
    public func bindNode(nodeID: String) async throws -> UserNode {
        let response = try await self.client().UserControlWallet_BindNode(.init(body: .json(.init(node_id: nodeID))))
        switch response {
        case .ok(let okResponse):
            switch okResponse.body {
            case .json(let result):
                print(result)
                return UserNode(userID: result.user_node?.user_id ?? "", nodeID: result.user_node?.node_id ?? "", userRole: UserRole.FromInt(l: result.user_node?.role ?? 0))
            }
        case .default(let statusCode, let defaultResponse):
            switch defaultResponse.body {
            case .json(let result):
                throw APIError.From(statusCode: statusCode, result: result)
            }
        }
    }

    public func getUserInfo() async throws -> UserInfo {
        
        let response = try await self.client().UserControlWallet_GetUserInfo()
        switch response {
        case .ok(let okResponse):
            switch okResponse.body {
            case .json(let result):
                let userNodes = result.user_nodes ?? []
                let nodes = userNodes.map {node in
                    UserNode(userID: node.user_id ?? "", nodeID: node.node_id ?? "", userRole: UserRole.FromInt(l: node.role ?? 0))
                }
                let userInfo = UserInfo(
                    user: User(userID: result.user?.user_id ?? "", email: result.user?.email ?? ""),
                    wallet: Wallet(walletID: result.wallet?.wallet_id ?? "", name: result.wallet?.name ?? ""),
                    vault: Vault.fromResult(vault: result.vault),
                    userNodes: nodes)
                return userInfo
                                        
            }
        case .default(let statusCode, let defaultResponse):
            switch defaultResponse.body {
            case .json(let result):
                throw APIError.From(statusCode: statusCode, result: result)
            }
        }
    }
}
