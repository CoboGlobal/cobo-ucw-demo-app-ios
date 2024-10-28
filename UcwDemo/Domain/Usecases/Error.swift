//
//  Error.swift
//  UcwDemo
//
//  Created by Yang.Bai on 2024/8/25.
//

import Foundation

struct UseCaseError: Error {
    var statusCode: Int
    var message: String
    var reason: String
    
    
    static func fromApiError(error: APIError) -> UseCaseError {
        switch error {
        case .badRequest(let code, let reason, let message):
            return UseCaseError(statusCode: code, message: message, reason: reason)
        case .unauthorized(let code, let reason, let message):
            return UseCaseError(statusCode: code, message: message, reason: reason)
        case .forbidden(let code, let reason, let message):
            return UseCaseError(statusCode: code, message: message, reason: reason)
        case .notfound(let code, let reason, let message):
            return UseCaseError(statusCode: code, message: message, reason: reason)
        case .internalErr(let code, let reason, let message):
            return UseCaseError(statusCode: code, message: message, reason: reason)
        case .unknow(let code, let reason, let message):
            return UseCaseError(statusCode: code, message: message, reason: reason)
        }
    }
    
    static func generalError(error: Error) -> UseCaseError {
        return UseCaseError(statusCode: 500, message: error.localizedDescription, reason: "")
    }
}
