//
//  Vault.swift
//  UcwDemo
//
//  Created by Yang.Bai on 2024/8/26.
//

import Foundation


enum VaultStatus: Int {
    case statusUnspecified = 0
    case statusCreated = 1
    case statusMainGroupCreated = 20
    case statusMainGenerated = 30
}

public struct Vault {
    let vaultID: String
    let name: String
    let mainGroupID: String
    let projectID: String
    var coboNodeID: String
    let status: VaultStatus
    
    public func KeyGenSuccess() -> Bool {
        return self.status == .statusMainGenerated
    }
}

enum UCWGroupType: Int {
    case groupTypeUnspecified = 0
    case mainGroup = 1
    case recoveryGroup = 2
}

public struct Group {
    var groupID: String = "";
    var groupType: UCWGroupType = .groupTypeUnspecified
}

public struct GroupInfo {
    var group: Group = Group()
    var groupNodes: [GroupNode] = []
}

public struct GroupNode: Identifiable {
    public var id: String { nodeID.appending(groupID) }

    
    var nodeID: String = ""
    var groupID: String = ""
    var holderName: String = ""
    var userID: String = ""
}
