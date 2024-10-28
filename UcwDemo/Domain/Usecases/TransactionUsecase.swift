//
//  TransactionUsecase.swift
//  UcwDemo
//
//  Created by Yang.Bai on 2024/8/25.
//

import Combine
import Foundation
import UcwGeneratedClient

protocol TransactionUsecaseProtocol {
    func estimateTransactionFee(req: TransactionDetail) -> Future<EstimateFee, UsecaseError>
    func createTransaction(req: TransactionDetail) -> Future<String, UsecaseError>
    func getTransaction(transactionID: String) -> Future<TransactionDetail, UsecaseError>
    func cancelTransaction(transactionID: String) -> Future<String, UsecaseError>
    func approveTransaction(transactionID: String) -> Future<String, UsecaseError>
    func rejectTransaction(transactionID: String) -> Future<String, UsecaseError>
    func listTransactions(walletID: String, tokenID: String, type: TransactionType) -> Future<[TransactionDetail], UsecaseError>
}

enum TransactionRepostAction: Int {
    case actionUnspecified = 0
    case actionApproved = 1
    case actionRejected = 2
}

struct TransactionUsecase: TransactionUsecaseProtocol {
    var repo: TransactionRepository = BackendClient.shared
    func estimateTransactionFee(req: TransactionDetail) -> Future<EstimateFee, UsecaseError> {
        return Future(
            asyncFunc: {
                try await repo.estimateTransactionFee(req: req)
            },
            mapError: UsecaseError.mapError
        )
    }
    
    func createTransaction(req: TransactionDetail) -> Future<String, UsecaseError> {
        return Future(
            asyncFunc: {
                try await repo.createTransaction(req: req)
            },
            mapError: UsecaseError.mapError
        )
    }
    
    func getTransaction(transactionID: String) -> Future<TransactionDetail, UsecaseError> {
        return Future(
            asyncFunc: {
                try await repo.getTransaction(transactionID: transactionID)
            },
            mapError: UsecaseError.mapError
        )
    }
    
    func cancelTransaction(transactionID: String) -> Future<String, UsecaseError> {
        return Future(
            asyncFunc: {
                try await repo.reportTransaction(transactionID: transactionID, action: TransactionRepostAction.actionRejected.rawValue)
                return ""
            },
            mapError: UsecaseError.mapError
        )
    }
    
    func approveTransaction(transactionID: String) -> Future<String, UsecaseError> {
        return Future(
            asyncFunc: {
                try await repo.reportTransaction(transactionID: transactionID, action: TransactionRepostAction.actionApproved.rawValue)
                return ""
            },
            mapError: UsecaseError.mapError
        )
    }
    
    func rejectTransaction(transactionID: String) -> Future<String, UsecaseError> {
        return Future(
            asyncFunc: {
                try await repo.reportTransaction(transactionID: transactionID, action: TransactionRepostAction.actionRejected.rawValue)
                return ""
            },
            mapError: UsecaseError.mapError
        )
    }
    
    func listTransactions(walletID: String, tokenID: String, type: TransactionType) -> Future<[TransactionDetail], UsecaseError> {
        return Future(
            asyncFunc: {
                try await repo.listTransactions(walletID: walletID, tokenID: tokenID, type: type)
            },
            mapError: UsecaseError.mapError
        )
    }
}
