//
//  WalletUsecase.swift
//  UcwDemo
//
//  Created by Yang.Bai on 2024/8/23.
//

import Combine
import Foundation

protocol WalletUsecaseProtocol {
    func loadWalletTokens(walletID: String) -> Future<[TokenBalance], UsecaseError>
    func getWalletToken(walletID: String, tokenID: String) -> Future<TokenAddress, UsecaseError>
    func createWallet(vaultID: String, name: String) -> Future<String, UsecaseError>
    func getWalletInfo(walletID: String) -> Future<Wallet, UsecaseError>
    func addWalletAddress(walletID: String, chainID: String) -> Future<Address, UsecaseError>
}

struct WalletUsecase: WalletUsecaseProtocol {
    var repo: WalletRepository = BackendClient.shared

    func loadWalletTokens(walletID: String) -> Future<[TokenBalance], UsecaseError> {
        return Future(
            asyncFunc: {
                try await self.repo.listWalletTokens(walletID: walletID)
            },
            mapError: UsecaseError.mapError
        )
    }

    func getWalletToken(walletID: String, tokenID: String) -> Future<TokenAddress, UsecaseError> {
        return Future(
            asyncFunc: {
                try await repo.getWalletToken(walletID: walletID, tokenID: tokenID)
            },
            mapError: UsecaseError.mapError
        )
    }

    func createWallet(vaultID: String, name: String) -> Future<String, UsecaseError> {
        return Future(
            asyncFunc: {
                try await self.repo.createWallet(vaultID: vaultID, name: name)
            },
            mapError: UsecaseError.mapError
        )
    }

    func getWalletInfo(walletID: String) -> Future<Wallet, UsecaseError> {
        return Future(
            asyncFunc: {
                try await repo.getWalletInfo(walletID: walletID)
            },
            mapError: UsecaseError.mapError
        )
    }

    func addWalletAddress(walletID: String, chainID: String) -> Future<Address, UsecaseError> {
        return Future(
            asyncFunc: {
                try await repo.addWalletAddress(walletID: walletID, chainID: chainID)
            },
            mapError: UsecaseError.mapError
        )
    }
}
