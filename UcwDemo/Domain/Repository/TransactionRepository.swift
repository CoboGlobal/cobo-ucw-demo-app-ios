//
//  TransactionRepository.swift
//  UcwDemo
//
//  Created by Yang.Bai on 2024/8/25.
//

import Foundation
import UcwGeneratedClient


protocol TransactionRepository {
    func estimateTransactionFee(req: TransactionDetail) async throws -> EstimateFee
    func createTransaction(req: TransactionDetail) async throws -> String
    func reportTransaction(transactionID: String, action: Int) async throws
    func listTransactions(walletID: String, tokenID: String, type: TransactionType) async throws -> [TransactionDetail]
    func getTransaction(transactionID: String) async throws -> TransactionDetail
}

extension EstimateFee {
    static func fromResult(result: Components.Schemas.ucw_period_v1_period_EstimateTransactionFeeReply?) -> EstimateFee {
        guard let fast = result?.fast else {
            return EstimateFee()
        }
        guard let slow = result?.slow else {
            return EstimateFee()
        }
        guard let recommend = result?.recommend else {
            return EstimateFee()
        }
        return EstimateFee(Fast: Fee.fromResult(result: fast), Recommend: Fee.fromResult(result: recommend), Slow: Fee.fromResult(result: slow))
    }
}

extension Fee {
    static func fromResult(result: Components.Schemas.ucw_period_v1_period_Fee?) -> Fee {
        guard let fee = result else {
            return Fee()
        }
        return Fee(level: FeeRateLevel.FromInt(l: fee.level ?? 0), feePerByte: Decimal(string: fee.fee_per_byte ?? "0") ?? Decimal.zero, feeAmount: Decimal(string: fee.fee_amount ?? "0") ?? Decimal.zero, gasPrice: Decimal(string: fee.gas_price ?? "0") ?? Decimal.zero, gasLimit: Decimal(string: fee.gas_limit ?? "0") ?? Decimal.zero, tokenID: fee.token_id ?? "", maxFee: Decimal(string: fee.max_fee ?? "0") ?? Decimal.zero, maxPriorityFee: Decimal(string: fee.max_priority_fee ?? "0") ?? Decimal.zero)

    }
}

extension TransactionDetail {
    static func fromResult(result: Components.Schemas.ucw_period_v1_period_Transaction?) -> TransactionDetail {
        guard let transaction = result else {
            return TransactionDetail()
        }
        
        return TransactionDetail(
            id: transaction.transaction_id ?? "",
            status: TransactionStatus(rawValue: transaction.status ?? 0) ?? .statusUnspecified,
            subStatus: TransactionSubSatus(rawValue: transaction.sub_status ?? 0) ?? .subStatusUnspecified,
            amount: transaction.amount?.value ?? "0", 
            transactionType: TransactionType(rawValue: transaction._type ?? 0) ?? .typeUnspecified,
            txHash: transaction.tx_hash ?? "",
            token: Token.fromResult(result: transaction.amount?.token),
            createTimestamp: transaction.create_timestamp ?? "",
            chain: transaction.chain ?? "",
            from: transaction.from ?? "",
            to: transaction.to ?? "",
            fee: Fee.fromResult(result: transaction.fee), 
            walletID: transaction.wallet_id ?? "",
            externalID: transaction.external_id ?? "")
    }
}

extension BackendClient: TransactionRepository {
    public func estimateTransactionFee(req: TransactionDetail) async throws -> EstimateFee {
        let response = try await self.client().UserControlWallet_EstimateTransactionFee(path: .init(wallet_id: req.walletID), body: .json(Components.Schemas.ucw_period_v1_period_EstimateTransactionFeeRequest(from: req.from, to: req.to, token_id: req.token?.tokenID, amount: req.amount, _type: req.transactionType.rawValue)))
        switch response {
        case .ok(let okResponse):
            switch okResponse.body {
            case .json(let result):
                return EstimateFee.fromResult(result: result)
            }
        case .default(let statusCode, let defaultResponse):
            switch defaultResponse.body {
            case .json(let result):
                throw APIError.From(statusCode: statusCode, result: result)
            }
        }
    }
    
    public func listTransactions(walletID: String, tokenID: String, type: TransactionType) async throws -> [TransactionDetail] {
        let response = try await self.client().UserControlWallet_ListTransaction(path: .init(wallet_id: walletID), query: .init(token_id: tokenID, transaction_type: type.rawValue))
        switch response {
        case .ok(let okResponse):
            switch okResponse.body {
            case .json(let result):
                let list = result.list ?? []
                let transactions = list.map {each in
                    TransactionDetail.fromResult(result: each)
                }
                return transactions
            }
        case .default(let statusCode, let defaultResponse):
            switch defaultResponse.body {
            case .json(let result):
                throw APIError.From(statusCode: statusCode, result: result)
            }
        }
    }
    
    public func getTransaction(transactionID: String) async throws -> TransactionDetail {
        let response = try await self.client().UserControlWallet_GetTransaction(path: .init(transaction_id: transactionID))
        switch response {
        case .ok(let okResponse):
            switch okResponse.body {
            case .json(let result):
                return TransactionDetail.fromResult(result: result.transaction)
            }
        case .default(let statusCode, let defaultResponse):
            switch defaultResponse.body {
            case .json(let result):
                throw APIError.From(statusCode: statusCode, result: result)
            }
        }
    }
    
    public func createTransaction(req: TransactionDetail) async throws -> String {
        let response = try await self.client().UserControlWallet_CreateTransaction(path: .init(wallet_id: req.walletID), body: .json(.init(from: req.from, to: req.to, amount: req.amount, token_id: req.token?.tokenID, chain: req.chain, _type: req.transactionType.rawValue, fee: req.fee?.toClientFee)))
        switch response {
        case .ok(let okResponse):
            switch okResponse.body {
            case .json(let result):
                return result.transaction_id ?? ""
            }
        case .default(let statusCode, let defaultResponse):
            switch defaultResponse.body {
            case .json(let result):
                throw APIError.From(statusCode: statusCode, result: result)
            }
        }
    }
    
    func reportTransaction(transactionID: String, action: Int) async throws {
        let response = try await self.client().UserControlWallet_TransactionReport(path: .init(transaction_id: transactionID), body: .json(.init(action: action)))
        switch response {
        case .ok(let okResponse):
            switch okResponse.body {
            case .json( _): break
            }
        case .default(let statusCode, let defaultResponse):
            switch defaultResponse.body {
            case .json(let result):
                throw APIError.From(statusCode: statusCode, result: result)
            }
        }
    }
}
