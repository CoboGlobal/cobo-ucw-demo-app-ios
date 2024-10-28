//
//  WalletRepository.swift
//  UcwDemo
//
//  Created by Yang.Bai on 2024/8/23.
//

import Foundation
import UcwGeneratedClient


protocol WalletRepository {
    func listWalletTokens(walletID: String) async throws -> [TokenBalance]
    func getWalletToken(walletID: String, tokenID: String) async throws -> TokenAddress
    func createWallet(vaultID: String, name: String) async throws -> String
    func getWalletInfo(walletID: String) async throws -> Wallet
    func addWalletAddress(walletID: String, chainID: String) async throws -> Address
}

extension Token {
    static func fromResult(result: Components.Schemas.ucw_period_v1_period_Token?) -> Token {
        guard let token = result else {
            return Token()
        }
        
        return Token(tokenID: token.token_id ?? "", iconURL: token.icon_url ?? "", chain: token.chain ?? "", decimals: Int(token.decimal ?? 0))
    }
}

extension BackendClient: WalletRepository {
    public func createWallet(vaultID: String, name: String) async throws -> String {
        let response = try await self.client().UserControlWallet_CreateWallet(path: .init(vault_id: vaultID), body: .json(.init(name: name)))
        switch response {
        case .ok(let okResponse):
            switch okResponse.body {
            case .json(let result):
                return result.wallet_id ?? ""
            }
        case .default(let statusCode, let defaultResponse):
            switch defaultResponse.body {
            case .json(let result):
                throw APIError.From(statusCode: statusCode, result: result)
            }
        }
    }
    
    public func listWalletTokens(walletID: String) async throws -> [TokenBalance] {
        let response = try await self.client().UserControlWallet_ListWalletToken(path: .init(wallet_id: walletID))
        switch response {
        case .ok(let okResponse):
            switch okResponse.body {
            case .json(let result):
                let list = result.list ?? []
                let tokenBalanceList = list.map {each in
                    TokenBalance(walletID: walletID, token: Token.fromResult(result: each.token), balance: Balance(avaiable: each.available ?? "", total:  each.balance ?? ""))
                }
                return tokenBalanceList
            }
        case .default(let statusCode, let defaultResponse):
            switch defaultResponse.body {
            case .json(let result):
                throw APIError.From(statusCode: statusCode, result: result)
            }
        }
    }
    
    public func addWalletAddress(walletID: String, chainID: String) async throws -> Address {
        let response = try await self.client().UserControlWallet_AddWalletAddress(path: .init(wallet_id: walletID), body: .json(.init(chain_id: chainID)))
        switch response {
        case .ok(let okResponse):
            switch okResponse.body {
            case .json(let result):
                return Address(address: result.address!)
            }
        case .default(let statusCode, let defaultResponse):
            switch defaultResponse.body {
            case .json(let result):
                throw APIError.From(statusCode: statusCode, result: result)
            }
        }
    }
    
    public func getWalletToken(walletID: String, tokenID: String) async throws -> TokenAddress {
        let response = try await self.client().UserControlWallet_GetWalletToken(path: .init(wallet_id: walletID, token_id: tokenID))
        switch response {
        case .ok(let okResponse):
            switch okResponse.body {
            case .json(let result):
                let balance = Balance(avaiable: result.token_addresses?.token?.available ?? "", total:  result.token_addresses?.token?.balance ?? "")
                let addressList = result.token_addresses?.addresses ?? []
                let list = addressList.map {each in
                    Address(address: each)
                }
                let token = result.token_addresses?.token?.token
                return TokenAddress(tokenBalance: TokenBalance(walletID: walletID, token: Token.fromResult(result: token), balance: balance), addressList: list)
            }
        case .default(let statusCode, let defaultResponse):
            switch defaultResponse.body {
            case .json(let result):
                throw APIError.From(statusCode: statusCode, result: result)
            }
        }
    }
    
    public func getWalletInfo(walletID: String) async throws -> Wallet {
        let response = try await self.client().UserControlWallet_GetWalletInfo(path: .init(wallet_id: walletID))
        switch response {
        case .ok(let okResponse):
            switch okResponse.body {
            case .json(let result):
                return Wallet(walletID: result.wallet_info?.wallet?.wallet_id ?? "", name: result.wallet_info?.wallet?.name ?? "")
            }
        case .default(let statusCode, let defaultResponse):
            switch defaultResponse.body {
            case .json(let result):
                throw APIError.From(statusCode: statusCode, result: result)
            }
        }
    }
}
