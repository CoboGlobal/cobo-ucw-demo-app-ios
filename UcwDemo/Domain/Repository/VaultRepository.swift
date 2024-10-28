//
//  VaultRepository.swift
//  UcwDemo
//
//  Created by Yang.Bai on 2024/8/25.
//

import Foundation
import UcwGeneratedClient


protocol VaultRepository {
    func initVault() async throws -> Vault
    func generateMainGroup(vaultID: String, nodeID: String) async throws -> String
    func generateRecoveryGroup(vaultID: String, nodeIDs: [String]) async throws -> String
    func recoverMainGroup(vaultID: String, nodeID: String, sourceGroupID: String) async throws -> String
    func listTssRequests(vaultID: String, nodeID: String, status: Int) async throws -> [TssRequest]
    func getTssRequest(vaultID: String, tssRequestID: String) async throws -> TssRequest
    func reportTssRequestAction(requestID: String, action: Int) async throws
    func listGroups(vaultID: String, groupType: Int) async throws -> [Group]
    func getGroupInfo(vaultID: String, groupID: String) async throws -> GroupInfo
}

extension Vault {
    static func fromResult(vault: Components.Schemas.ucw_period_v1_period_Vault?) -> Vault {
        guard let vault = vault else {
                  return Vault(
                    vaultID:  "",
                    name:  "",
                    mainGroupID:  "",
                    projectID:  "",
                    coboNodeID:  "",
                    status: .statusUnspecified
                )
              }
      return Vault(
          vaultID: vault.vault_id ?? "",
          name: vault.name ?? "",
          mainGroupID: vault.main_group_id ?? "",
          projectID: vault.project_id ?? "",
          coboNodeID: vault.cobo_node_id ?? "",
          status: VaultStatus(rawValue: vault.status ?? 0) ?? .statusUnspecified
      )
    }
}

extension BackendClient: VaultRepository {
    func listGroups(vaultID: String, groupType: Int) async throws -> [Group] {
        let response = try await self.client().UserControlWallet_ListGroups(path: .init(vault_id: vaultID), query: .init(group_type: groupType))
        switch response {
        case .ok(let okResponse):
            switch okResponse.body {
            case .json(let result):
                let rawResult = result.groups ?? []
                let groups = rawResult.map {each in
                    Group(groupID: each.group_id ?? "", groupType: UCWGroupType(rawValue: each.group_type ?? 0) ?? .groupTypeUnspecified)
                }
                return groups
            }
        case .default(let statusCode, let defaultResponse):
            switch defaultResponse.body {
            case .json(let result):
                throw APIError.From(statusCode: statusCode, result: result)
            }
        }
    }
    
    func getGroupInfo(vaultID: String, groupID: String) async throws -> GroupInfo {
        let response = try await self.client().UserControlWallet_GetGroup(path: .init(vault_id: vaultID, group_id: groupID))
        switch response {
        case .ok(let okResponse):
            switch okResponse.body {
            case .json(let result):
                
                let nodesRaw = result.group?.group_nodes ?? []
                let groupNodes = nodesRaw.map {each in
                    GroupNode(nodeID: each.node_id ?? "", groupID: each.group_id ?? "", holderName: each.holder_name ?? "", userID: each.user_id ?? "" )
                }
                let info = GroupInfo(group: Group(groupID: result.group?.group?.group_id ?? "", groupType: UCWGroupType(rawValue: result.group?.group?.group_type ?? 0) ?? .groupTypeUnspecified), groupNodes: groupNodes)
                return info
            }
        case .default(let statusCode, let defaultResponse):
            switch defaultResponse.body {
            case .json(let result):
                throw APIError.From(statusCode: statusCode, result: result)
            }
        }
    }
    
 
    
    public func initVault() async throws -> Vault {
        let response = try await self.client().UserControlWallet_InitVault(body: .json(.init()))
        switch response {
        case .ok(let okResponse):
            switch okResponse.body {
            case .json(let result):
                return Vault.fromResult(vault: result.vault)
            }
        case .default(let statusCode, let defaultResponse):
            switch defaultResponse.body {
            case .json(let result):
                throw APIError.From(statusCode: statusCode, result: result)
            }
        }
    }
    
    public func generateMainGroup(vaultID: String, nodeID: String) async throws -> String {
        let response = try await self.client().UserControlWallet_GenerateMainGroup(path: .init(vault_id: vaultID), body: .json(.init(node_id: nodeID)))
        switch response {
        case .ok(let okResponse):
            switch okResponse.body {
            case .json(let result):
                return result.tss_request_id ?? ""
            }
        case .default(let statusCode, let defaultResponse):
            switch defaultResponse.body {
            case .json(let result):
                throw APIError.From(statusCode: statusCode, result: result)
            }
        }
    }
    
    public func generateRecoveryGroup(vaultID: String, nodeIDs: [String]) async throws -> String {
        let response = try await self.client().UserControlWallet_GenerateRecoveryGroup(path: .init(vault_id: vaultID), body: .json(.init(node_ids: nodeIDs)))
        switch response {
        case .ok(let okResponse):
            switch okResponse.body {
            case .json(let result):
                return result.tss_request_id ?? ""
            }
        case .default(let statusCode, let defaultResponse):
            switch defaultResponse.body {
            case .json(let result):
                throw APIError.From(statusCode: statusCode, result: result)
            }
        }
    }
    
    public func recoverMainGroup(vaultID: String, nodeID: String, sourceGroupID: String) async throws -> String {
        let response = try await self.client().UserControlWallet_RecoverMainGroup(path: .init(vault_id: vaultID), body: .json(.init(node_id: nodeID, source_group_id: sourceGroupID)))
        switch response {
        case .ok(let okResponse):
            switch okResponse.body {
            case .json(let result):
                return result.tss_request_id ?? ""
            }
        case .default(let statusCode, let defaultResponse):
            switch defaultResponse.body {
            case .json(let result):
                throw APIError.From(statusCode: statusCode, result: result)
            }
        }
    }
    
    public func listTssRequests(vaultID: String, nodeID: String, status: Int) async throws -> [TssRequest] {
        let response = try await self.client().UserControlWallet_ListTssRequest(path: .init(vault_id: vaultID), query: .init(node_id: nodeID, status: status))
        switch response {
        case .ok(let okResponse):
            switch okResponse.body {
            case .json(let result):
                let rawResult = result.tss_requests ?? []
                let tssRequests = rawResult.map {each in
                    TssRequest(info: each, status: TssRequestStatus(rawValue: each.status ?? 0) ?? .TssRequestStatusUnspecified, tssType: TssType(rawValue: each._type ?? 0) ?? .TssTypeUnspecified)
                }
                return tssRequests
            }
        case .default(let statusCode, let defaultResponse):
            switch defaultResponse.body {
            case .json(let result):
                throw APIError.From(statusCode: statusCode, result: result)
            }
        }
    }
    
    public func getTssRequest(vaultID: String, tssRequestID: String) async throws -> TssRequest {
        let response = try await self.client().UserControlWallet_GetTssRequest(path: .init(vault_id: vaultID, tss_request_id: tssRequestID))
        switch response {
        case .ok(let okResponse):
            switch okResponse.body {
            case .json(let result):
                return TssRequest(info: result.tss_request, status: TssRequestStatus(rawValue:  result.tss_request?.status ?? 0) ?? .TssRequestStatusUnspecified, tssType: TssType(rawValue:  result.tss_request?._type ?? 0) ?? .TssTypeUnspecified)
            }
        case .default(let statusCode, let defaultResponse):
            switch defaultResponse.body {
            case .json(let result):
                throw APIError.From(statusCode: statusCode, result: result)
            }
        }
    }
    
    public func reportTssRequestAction(requestID tssRequestID: String, action: Int) async throws {
        let response = try await self.client().UserControlWallet_TssRequestReport(path: .init(tss_request_id: tssRequestID), body: .json(.init(action: action)))
        switch response {
        case .ok(let okResponse):
            switch okResponse.body {
            case .json(let result):
                print(result)
            }
        case .default(let statusCode, let defaultResponse):
            switch defaultResponse.body {
            case .json(let result):
                throw APIError.From(statusCode: statusCode, result: result)
            }
        }
    }
}
