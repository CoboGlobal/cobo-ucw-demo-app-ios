//
//  TssRequest.swift
//  UcwDemo
//
//  Created by Yang.Bai on 2024/8/26.
//

import Foundation
import UcwGeneratedClient

enum TssRequestStatus: Int {
    case TssRequestStatusUnspecified = 0
    case PendingConfirmation = 10
    case KeyHolderConfirmationFailed = 20
    case KeyGenerating = 30
    case MpcProcessing = 35
    case KeyGeneratingFailed = 40
    case Success = 50
}

enum TssType: Int {
    case TssTypeUnspecified = 0
    case TssGenerateMainKeySecret = 1
    case TssGenerateRecoveryKeySecret = 2
    case TssRecoverMainKeySecret = 3
}

public struct TssRequest: Identifiable, Equatable {
    var info: Components.Schemas.ucw_period_v1_period_TssRequest?
    public var id: String { info?.request_id ?? "" }
    
    var status: TssRequestStatus = .TssRequestStatusUnspecified
    var tssType: TssType = .TssTypeUnspecified
    
    var title: String {
        switch info?._type {
        case TssType.TssGenerateRecoveryKeySecret.rawValue:
            return "Generate Recovery Key"
        case TssType.TssRecoverMainKeySecret.rawValue:
            return "Recovery Key"
        case TssType.TssGenerateMainKeySecret.rawValue:
            return "Generate Main Key"
        default:
            return ""
        }
    }
    
    public func finished() -> Bool {
        
        print("tssfinished \(self.id) finished? \(self.status) == \(String(describing: self.info?.status))")
        return self.status == .KeyGeneratingFailed || self.status == .Success
    }
}
