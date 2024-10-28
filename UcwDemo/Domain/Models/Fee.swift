//
//  Fee.swift
//  UcwDemo
//
//  Created by Yang.Bai on 2024/8/25.
//

import Foundation
import UcwGeneratedClient

enum FeeRateLevel: String, CaseIterable, Identifiable {
    case customize = "Customize"
    case slow = "Slow"
    case recommend = "Recommend"
    case fast = "Fast"
    case unspecified = ""
    
    var id: String { self.rawValue }
     
      
  var title: String {
      switch self {
      case .fast:
          return "Fast"
      case .recommend:
          return "Recommend"
      case .slow:
          return "Slow"
      default:
          return "Customize"
      }
  }
    var level: Int {
        switch self {
        case .customize:
            return 4
        case .fast:
            return 3
        case .recommend:
            return 2
        case .slow:
            return 1
        case .unspecified:
            return 0
        }
    }
    
    static func FromInt(l: Int) -> FeeRateLevel {
        var level: FeeRateLevel {
            switch l {
            case 4:
                return .customize
            case 3:
                return .fast
            case 2:
                return .recommend
            case 1:
                return .slow
            default:
                return .unspecified
            }
        }
        return level
    }
}

public struct EstimateFee {
    var Fast: Fee = Fee()
    var Recommend: Fee = Fee()
    var Slow: Fee = Fee()
}


public struct Fee {
    var level: FeeRateLevel = .unspecified
    var feePerByte: Decimal = Decimal()
    var feeAmount: Decimal = Decimal()
    var gasPrice: Decimal = Decimal()
    var gasLimit: Decimal = Decimal()
    var tokenID: String = ""
    var maxFee: Decimal = Decimal()
    var maxPriorityFee: Decimal = Decimal()

    
    var toClientFee: Components.Schemas.ucw_period_v1_period_Fee {
        return Components.Schemas.ucw_period_v1_period_Fee(fee_per_byte: self.feePerByte.description, gas_price: self.gasPrice.description, gas_limit: self.gasLimit.description, level: self.level.level, max_fee: self.maxFee.description, max_priority_fee: self.maxPriorityFee.description, token_id: self.tokenID, fee_amount: self.feeAmount.description)
    }
    
    func getFee() -> String {
        if !self.gasPrice.isZero {
            let fee = self.gasPrice / Decimal(100_000_000_000_000_0000) * self.gasLimit
            return fee.description
        }
        
        if self.feePerByte.isZero {
            return self.feePerByte.description
        }
        
        return "0"
    }
}
