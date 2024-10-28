//
//  VaultUsecase.swift
//  UcwDemo
//
//  Created by Yang.Bai on 2024/8/26.
//

import Combine
import Foundation

enum TssRequestRepostAction: Int {
    case actionUnspecified = 0
    case actionApproved = 1
    case actionRejected = 2
}

protocol VaultUsecaseProtocol {
    func initVault() -> Future<Vault, UsecaseError>
    func generateMainGroup(vaultID: String, nodeID: String) -> Future<String, UsecaseError>
    func generateRecoveryGroup(vaultID: String, nodeIDs: [String]) -> Future<String, UsecaseError>
    func recoverMainGroup(vaultID: String, nodeID: String, sourceGroupID: String) -> Future<String, UsecaseError>
    func listTssRequests(vaultID: String, nodeID: String, status: Int) -> Future<[TssRequest], UsecaseError>
    func getTssRequest(vaultID: String, tssRequestID: String) -> Future<TssRequest, UsecaseError>
    func reportTssRequest(requestID: String, action: Int) -> Future<String, UsecaseError>
    func listGroups(vaultID: String, groupType: Int) -> Future<[Group], UsecaseError>
    func getGroupInfo(vaultID: String, groupID: String) -> Future<GroupInfo, UsecaseError>
}

struct VaultUsecase: VaultUsecaseProtocol {
    var repo: VaultRepository = BackendClient.shared

    func getGroupInfo(vaultID: String, groupID: String) -> Future<GroupInfo, UsecaseError> {
        return Future(
            asyncFunc: {
                try await repo.getGroupInfo(vaultID: vaultID, groupID: groupID)
            },
            mapError: UsecaseError.mapError
        )
    }
    
    func listGroups(vaultID: String, groupType: Int) -> Future<[Group], UsecaseError> {
        return Future(
            asyncFunc: {
                try await repo.listGroups(vaultID: vaultID, groupType: groupType)
            },
            mapError: UsecaseError.mapError
        )
    }
    
    func initVault() -> Future<Vault, UsecaseError> {
        return Future(
            asyncFunc: {
                try await repo.initVault()
            },
            mapError: UsecaseError.mapError
        )
    }
    
    func generateMainGroup(vaultID: String, nodeID: String) -> Future<String, UsecaseError> {
        return Future(
            asyncFunc: {
                try await repo.generateMainGroup(vaultID: vaultID, nodeID: nodeID)
            },
            mapError: UsecaseError.mapError
        )
    }
    
    func generateRecoveryGroup(vaultID: String, nodeIDs: [String]) -> Future<String, UsecaseError> {
        return Future(
            asyncFunc: {
                try await repo.generateRecoveryGroup(vaultID: vaultID, nodeIDs: nodeIDs)
            },
            mapError: UsecaseError.mapError
        )
    }
    
    func recoverMainGroup(vaultID: String, nodeID: String, sourceGroupID: String) -> Future<String, UsecaseError> {
        return Future(
            asyncFunc: {
                try await repo.recoverMainGroup(vaultID: vaultID, nodeID: nodeID, sourceGroupID: sourceGroupID)
            },
            mapError: UsecaseError.mapError
        )
    }
    
    func listTssRequests(vaultID: String, nodeID: String, status: Int) -> Future<[TssRequest], UsecaseError> {
        return Future(
            asyncFunc: {
                try await repo.listTssRequests(vaultID: vaultID, nodeID: nodeID, status: status)
            },
            mapError: UsecaseError.mapError
        )
    }
    
    func getTssRequest(vaultID: String, tssRequestID: String) -> Future<TssRequest, UsecaseError> {
        return Future(
            asyncFunc: {
                try await repo.getTssRequest(vaultID: vaultID, tssRequestID: tssRequestID)
            },
            mapError: UsecaseError.mapError
        )
    }
    
    func reportTssRequest(requestID: String, action: Int) -> Future<String, UsecaseError> {
        return Future(
            asyncFunc: {
                try await repo.reportTssRequestAction(requestID: requestID, action: action)
                return ""
            },
            mapError: UsecaseError.mapError
        )
    }
}
