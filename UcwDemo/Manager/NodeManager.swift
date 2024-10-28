//
//  NodeManager.swift
//  UcwDemo
//
//  Created by Yang.Bai on 2024/8/22.
//

import Combine
import Foundation
import UCWSDK

protocol NodeProtocol {
    func initDB(database: String, passphrase: String) -> Future<String, UsecaseError>
    func initUCWSDK(database: String, passphrase: String) -> String
    func isOpend() -> Bool
    func getNodeId() -> String
    func isDBInitialized(database: String) -> Bool
    func getTssRequest(requestID: String) -> Future<TSSRequest?, UsecaseError>
    func approveTssRequest(tssRequestIDs: String) throws
    func rejectTssRequest(tssRequestIDs: String, reason: String) throws
    func getTransaction(transactionID: String) -> Future<Transaction?, UsecaseError>
    func approveTransactions(transactionIDs: String) throws
    func rejectTransactions(transactionIDs: String, reason: String) throws
    func restore(database: String, passphrase: String, backupPassphrase: String, secrets: String) throws
    func export(backupPassphrase: String) throws -> String
    func pollTransactionFromSDK(
        interval: TimeInterval,
        transactionID: String,
        condition: @escaping (Transaction?) -> Bool
    ) -> AnyPublisher<Transaction?, UsecaseError>
}

class NodeManager: NodeProtocol {
    static let shared: NodeProtocol = NodeManager()
    private var database = ""
    private var ucwSDKInstance: UCW?
    private var pollingManager = PollingManager()

    private init() {}
    
    func getHomePath() -> String {
        let home = NSHomeDirectory()
        return home.appending("/Documents/")
    }
    
    func isDBInitialized(database: String) -> Bool {
        let homePath = self.getHomePath()
        let secretsFile = homePath + database

        return FileManager.default.fileExists(atPath: secretsFile)
    }
    
    func initDB(database: String, passphrase: String) -> Future<String, UsecaseError> {
        let homePath = self.getHomePath()
        let secretsFile = homePath + database
        return Future(
            asyncFunc: {
                try await initializeSecrets(secretsFile: secretsFile, passphrase: passphrase)
            },
            mapError: UsecaseError.mapError
        )
    }
    
    func initUCWSDK(database: String, passphrase: String) -> String {
        if self.isOpend() {
            return self.getNodeId()
        }
        let homePath = self.getHomePath()
        let sdkConfig = SDKConfig(env: Env.sandbox, timeout: 0, debug: false)

        do {
            self.ucwSDKInstance = try UCW(config: sdkConfig, secretsFile: homePath + database, passphrase: passphrase)
        } catch {
            print("initUCWSDK err \(error)")
        }
        self.database = database
        return self.getNodeId()
    }
    
    func isOpend() -> Bool {
        if let (status, _) = self.ucwSDKInstance?.getConnStatus() {
            switch status {
            case .CodeConnected:
                return true
            default:
                return false
            }
        } else {
            return false
        }
    }
        
    func approveTssRequest(tssRequestIDs: String) throws {
        try self.ucwSDKInstance?.approveTSSRequests(tssRequestIDs: [tssRequestIDs])
    }
    
    func rejectTssRequest(tssRequestIDs: String, reason: String) throws {
        try self.ucwSDKInstance?.rejectTSSRequests(tssRequestIDs: [tssRequestIDs], reason: reason)
    }
    
    func approveTransactions(transactionIDs: String) throws {
        try self.ucwSDKInstance?.approveTransactions(transactionIDs: [transactionIDs])
    }
    
    func rejectTransactions(transactionIDs: String, reason: String) throws {
        try self.ucwSDKInstance?.rejectTransactions(transactionIDs: [transactionIDs], reason: reason)
    }
    
    func pollTransactionFromSDK(
        interval: TimeInterval,
        transactionID: String,
        condition: @escaping (Transaction?) -> Bool
    ) -> AnyPublisher<Transaction?, UsecaseError> {
        return self.pollingManager.poll(
            interval: interval,
            maxAttempts: -1,
            shouldContinue: { condition($0) },
            operation: {
                self.getTransaction(transactionID: transactionID)
            }
        )
    }
    
    func getNodeId() -> String {
        do {
            if let nodeID = try self.ucwSDKInstance?.getTSSNodeID() {
                return nodeID
            }
        } catch {
            print("getNodeId Error: \(error)")
        }
        return ""
    }
    
    func getTssRequest(requestID: String) -> Future<TSSRequest?, UsecaseError> {
        return Future(
            asyncFunc: {
                if let requests = try await self.ucwSDKInstance?.getTSSRequests(tssRequestIDs: [requestID]) {
                    if !requests.isEmpty {
                        return requests[0]
                    }
                }
                return nil
            },
            mapError: UsecaseError.mapError
        )
    }
    
    func getTransaction(transactionID: String) -> Future<Transaction?, UsecaseError> {
        return Future(
            asyncFunc: {
                do {
                    if let transactions = try await self.ucwSDKInstance?.getTransactions(transactionIDs: [transactionID]) {
                        if !transactions.isEmpty {
                            return transactions[0]
                        }
                    }
                    return nil
                } catch {
                    let mappedError = UsecaseError.mapError(error)
                    if case let UsecaseError.sdkError(code, _, _) = mappedError, code == 2101 {
                        return nil
                    }
                    throw mappedError
                }
            },
            mapError: { $0 as! UsecaseError }
        )
    }

    func restore(database: String, passphrase: String, backupPassphrase: String, secrets: String) throws {
        let homePath = self.getHomePath()
        let result = try importSecrets(jsonRecoverySecrets: secrets, exportPassphrase: backupPassphrase, newSecretsFile: homePath + database, newPassphrase: passphrase)
        print("restore \(result)")
    }
    
    func export(backupPassphrase: String) throws -> String {
        let result = try self.ucwSDKInstance?.exportSecrets(exportPassphrase: backupPassphrase)
        return result ?? ""
    }
}
