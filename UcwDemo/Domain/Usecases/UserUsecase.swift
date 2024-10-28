//
//  UserUsecase.swift
//  UcwDemo
//
//  Created by Yang.Bai on 2024/8/26.
//

import Combine
import Foundation

protocol UserUsecaseProtocol {
    func login(email: String) -> Future<String, UsecaseError>
    func bindNode(nodeID: String) -> Future<UserNode, UsecaseError>
    func getUserInfo() -> Future<UserInfo, UsecaseError>
}

struct UserUsecase: UserUsecaseProtocol {
    var repo: UserRepository = BackendClient.shared

    func login(email: String) -> Future<String, UsecaseError> {
        return Future(
            asyncFunc: {
                let token = try await self.repo.login(email: email)
                _ = KeychainManager.standard.setToken(token: token)
                return token
            },
            mapError: UsecaseError.mapError
        )
    }

    func bindNode(nodeID: String) -> Future<UserNode, UsecaseError> {
        return Future(
            asyncFunc: {
                try await self.repo.bindNode(nodeID: nodeID)
            },
            mapError: UsecaseError.mapError
        )
    }

    func getUserInfo() -> Future<UserInfo, UsecaseError> {
        return Future(
            asyncFunc: {
                try await self.repo.getUserInfo()
            },
            mapError: UsecaseError.mapError
        )
    }
}
