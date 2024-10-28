//
//  UcaBackendClient.swift
//  UcwGeneratedClient
//
//  Created by Yang.Bai on 2024/8/22.
//

import Foundation
import HTTPTypes
import OpenAPIRuntime
import OpenAPIURLSession
import UcwGeneratedClient

struct AuthenticationMiddleware: ClientMiddleware {
    var bearerToken: String
    func intercept(
        _ request: HTTPRequest,
        body: HTTPBody?,
        baseURL: URL,
        operationID: String,
        next: (HTTPRequest, HTTPBody?, URL) async throws -> (HTTPResponse, HTTPBody?)
    ) async throws -> (HTTPResponse, HTTPBody?) {
        var request = request
        request.headerFields[.authorization] = "Bearer \(self.bearerToken)"
        return try await next(request, body, baseURL)
    }
}

public enum ApiEnv: Int {
    case local = 1
    case sandbox = 2
}

public enum APIError: Error {
    case badRequest(code: Int, reason: String, message: String)
    case unauthorized(code: Int, reason: String, message: String)
    case forbidden(code: Int, reason: String, message: String)
    case notFound(code: Int, reason: String, message: String)
    case internalErr(code: Int, reason: String, message: String)
    case unknown(code: Int, reason: String, message: String)
}


extension APIError {
    static func From(statusCode: Int, result: Components.Schemas.ucw_period_v1_period_ErrorResponse?) -> APIError {
        switch statusCode {
        case 400:
            return .badRequest(code: statusCode, reason: result?.reason ?? "", message: result?.message ?? "")
        case 401:
            return .unauthorized(code: statusCode, reason: result?.reason ?? "", message: result?.message ?? "")
        case 403:
            return .forbidden(code: statusCode, reason: result?.reason ?? "", message: result?.message ?? "")
        case 404:
            return .notFound(code: statusCode, reason: result?.reason ?? "", message: result?.message ?? "")
        case 500:
            return .internalErr(code: statusCode, reason: result?.reason ?? "", message: result?.message ?? "")
        default:
            return .unknown(code: statusCode, reason: result?.reason ?? "unknow error", message: result?.message ?? "")
        }
    }
}



public struct BackendClient {
    static let shared = BackendClient()
    
    let apiEnv: ApiEnv = .sandbox
    var serverURL: Foundation.URL = try! Servers.server2()

    private init() {
        if self.apiEnv == .local {
            self.serverURL = try! Servers.server1()
        }
    }

    public func client() -> Client {
        let token = KeychainManager.standard.readToken()
        return Client(
            serverURL: self.serverURL,
            transport: URLSessionTransport(),
            middlewares: [
                AuthenticationMiddleware(bearerToken: token ?? ""),
            ]
        )
    }
}
