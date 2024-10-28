//
//  File.swift
//  UcwDemo
//
//  Created by Yang.Bai on 2024/8/23.
//

import Foundation
import UcwGeneratedClient

public struct Token {
    var tokenID: String = ""
    var iconURL: String = ""
    var chain: String = ""
    var decimals: Int = 0
}

public struct TokenBalance: Identifiable {
    let walletID: String
    let token: Token
    let balance: Balance
    
    
    public var id: String { self.token.tokenID }
}

public struct TokenAddress {
    let tokenBalance: TokenBalance
    let addressList: [Address]
    
    var firstAddress: String {
        if !self.addressList.isEmpty {
            return self.addressList[0].address.address ?? ""
        }
        return "Empty Address"
    }
    
    var tokenID: String {
        return self.tokenBalance.token.tokenID
    }
    
    var available: String {
        return self.tokenBalance.balance.avaiable
    }
    
    var chain: String {
        return self.tokenBalance.token.chain
    }
}


public struct Address {
    let address: Components.Schemas.ucw_period_v1_period_Address
}
