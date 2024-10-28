//
//  Error.swift
//  UcwDemo
//
//  Created by Yang.Bai on 2024/10/17.
//

import Foundation
import UCWSDK

enum UsecaseError: Error {
    case sdkError(code: Int, reason: String, message: String)
    case apiError(code: Int, reason: String, message: String)
    case otherError(Error)
    case transactionFailed
    case unknownError(String)
    case ignored

    static func from(sdkError: SDKError) -> UsecaseError {
        switch sdkError {
        case .commonError(let code, let message):
            return .sdkError(code: Int(code.rawValue), reason: "SDK Common Error", message: message)
        case .apiError(let code, let message):
            return .sdkError(code: Int(code), reason: "SDK API Error", message: message ?? "No message provided")
        }
    }

    static func from(apiError: APIError) -> UsecaseError {
        switch apiError {
        case .badRequest(let code, let reason, let message),
             .unauthorized(let code, let reason, let message),
             .forbidden(let code, let reason, let message),
             .notFound(let code, let reason, let message),
             .internalErr(let code, let reason, let message),
             .unknown(let code, let reason, let message):
            return .apiError(code: code, reason: reason, message: message)
        }
    }
    
    
    static func mapError(_ error: Error) -> UsecaseError {
            switch error {
            case let sdkError as SDKError:
                return from(sdkError: sdkError)
            
            case let apiError as APIError:
                return from(apiError: apiError)

            case let usecaseError as UsecaseError:
                return usecaseError
            default:
                return .otherError(error)
            }
        }
}


extension UsecaseError: LocalizedError {
    public var errorDescription: String? {
        switch self {
        case .sdkError(code: let code, reason: let reason, message: let message):
            return "SDK Error - Code: \(code), Reason: \(reason), Message: \(message)"
        case .apiError(code: let code, reason: let reason, message: let message):
            return "API Error - Code: \(code), Reason: \(reason), Message: \(message)"
        case .otherError(let error):
            return "Other Error - \(error.localizedDescription)"
        case .transactionFailed:
            return "Transaction failed without specific error"
        case .unknownError(let description):
            return "Unknown error occurred: \(description)"
        case .ignored:
            return "Ignored error"
        }
    }
}




