//
//  Transaction.swift
//  UcwDemo
//
//  Created by Yang.Bai on 2024/8/25.
//

import Foundation
import UcwGeneratedClient

public struct TransactionDetail {
    var id: String = ""
    var status: TransactionStatus = .statusUnspecified
    var subStatus: TransactionSubSatus = .subStatusUnspecified
    var amount: String = ""
    var transactionType: TransactionType = .typeUnspecified
    var txHash: String = ""
    var token: Token? = Token()
    var createTimestamp: String = ""
    var chain: String = ""
    var from: String = ""
    var to: String = ""
    var fee: Fee? = Fee()
    var walletID: String = ""
    var externalID: String = ""
    
    var formattedDate: String {
        guard let timestamp = TimeInterval(self.createTimestamp) else {
            let date = Date()
            let formatter = DateFormatter()
            formatter.dateFormat = "yyyy-MM-dd HH:mm:ss"
            return formatter.string(from: date)
        }
        let date = Date(timeIntervalSince1970: timestamp)
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd HH:mm:ss"
        return formatter.string(from: date)
    }
    
    var canEstimateFee: Bool {
        
        if self.to.isEmpty {
            return false
        }
        if self.from.isEmpty {
            return false
        }
        if self.amount.isEmpty {
            return false
        }
        return true
    }
}


public enum TransactionType: Int {
    case typeUnspecified = 0
    case typeWithdrawal = 1
    case typeDeposit = 2
    
    var description: String {
        switch self {
        case .typeUnspecified:
            return "Unspecified"
        case .typeDeposit:
            return "Deposit"
        case .typeWithdrawal:
            return "Withdraw"
        }
    }
}

public enum TransactionStatus: Int {
    case statusUnspecified = 0
    case statusCreated = 1
    case statusSubmitted = 2
    case statusPendingScreening = 3
    case statusPendingAuthorization = 4
    case statusQueued = 5
    case statusPendingSignature = 6
    case statusBroadcasting = 7
    case statusConfirming = 8
    case statusPending = 9
    case statusCompleted = 10
    case statusFailed = 11
    case statusRejected = 12
    
    var description: String {
        switch self {
        case .statusBroadcasting:
            return "Broadcasting"
        case .statusCompleted:
            return "Completed"
        case .statusFailed:
            return "Failed"
        case .statusConfirming:
            return "Confirming"
        case .statusCreated:
            return "Created"
        case .statusPending:
            return "Pending"
        case .statusPendingAuthorization:
            return "PendingAuthorization"
        case .statusPendingScreening:
            return "PendingScreening"
        case .statusPendingSignature:
            return "PendingSignature"
        case .statusQueued:
            return "Queued"
        case .statusUnspecified:
            return "Unspecified"
        case .statusSubmitted:
            return "Submitted"
        case .statusRejected:
            return "Rejected"
        }
    }
}

public enum TransactionSubSatus: Int {
    case subStatusUnspecified = 0
    case subStatusPendingSignatureCanBeApproved = 100
    case subStatusPendingSignatureHasApproved = 101
}
