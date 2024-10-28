//
//  KeyGanView.swift
//  ucw-ios-demo
//
//  Created by Yang.Bai on 2024/1/29.
//

import Combine
import Foundation
import SwiftUI
import UCWSDK

struct KeyGenView: View {
    @StateObject var viewModel = ViewModel()

    let screenBackgroundColor = Color(red: 247/255, green: 247/255, blue: 249/255)

    var body: some View {
        ZStack {
            self.screenBackgroundColor.edgesIgnoringSafeArea(.all)

            VStack(alignment: .leading) {
                InfoBoxView()

                KeyGroupBoxView(groupTitle: "Key Holder 1",
                                holderName: self.$viewModel.holderNameTwo, nodeId: self.$viewModel.coboTssNodeId)

                KeyGroupBoxView(groupTitle: "Key Holder 2",
                                holderName: self.$viewModel.email,
                                nodeId: self.$viewModel.appTssNodeId)
                Spacer()
                Button(action: {
                    self.startKeyGen()
                }) {
                    Text("Start Key Gen")
                        .fontWeight(.bold)
                }.modifier(ButtonModifier())
            }
            .padding()
            .navigationDestination(isPresented: self.$viewModel.keyGenSuccess) {
                KeyGenSuccessView()
            }
            .alert(isPresented: self.$viewModel.showError, content: {
                Alert(title: Text("Error"), message: Text(self.viewModel.errorMessage ?? "Unknown error"), dismissButton: .default(Text("OK")))
            })
            if self.viewModel.isPresentingProgress {
                Color.black.opacity(0.5)
                    .edgesIgnoringSafeArea(.all)
                ProgressViewOverlay(progressText: self.$viewModel.progressText, showButton: self.$viewModel.showButton)
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
            }
        }

        .navigationBarBackButtonHidden(true)
        .interactiveDismissDisabled(true)
    }

    func startKeyGen() {
        self.viewModel.keygen()
    }
}

extension KeyGenView {
    static var id: String { "KeyGenView" }
}

extension KeyGenView {
    class ViewModel: ObservableObject {
        @Published var errorMessage: String?
        @Published var showError: Bool = false
        @Published var isPresentingProgress = false
        @Published var showButton = false
        @Published var progressText = "MPC Key Generating \nPlease don't close app"
        @Published var holderNameTwo = "Cobo"
        @Published var keyGenSuccess: Bool = false
        @Published var coboTssNodeId: String = ""
        @Published var appTssNodeId: String = ""
        @Published var appKeyHolderName: String = ""
        @Published var email: String = ""
        
        
        private var pollingManager =  PollingManager()
        private var vaultUsecase: VaultUsecaseProtocol
        private var nodeManager: NodeProtocol = NodeManager.shared
        private var userLocalStorage = UsersLocalStorage.shared
        private var vaultID: String = ""
        private var keychainManager = KeychainManager.standard
        private var cancellables = Set<AnyCancellable>()

        init() {
            let userID = self.userLocalStorage.userInfo?.user.userID ?? ""
            self.appTssNodeId = self.nodeManager.initUCWSDK(database: userID, passphrase: self.keychainManager.getPassword(userID: userID) ?? "")
            self.coboTssNodeId = self.userLocalStorage.userInfo?.vault.coboNodeID ?? ""
            self.email = self.userLocalStorage.userInfo?.user.email ?? ""
            self.vaultUsecase = VaultUsecase()
        }

        public func keygen() {
            let vault = self.userLocalStorage.userInfo?.vault
            if vault?.KeyGenSuccess() == true {
                self.keyGenSuccess = true
                return
            }
            self.isPresentingProgress = true
            self.vaultID = vault?.vaultID ?? ""
            self.generateMainGroup(vaultID: self.vaultID)
        }

        private func generateMainGroup(vaultID: String) {
            self.vaultUsecase.generateMainGroup(vaultID: vaultID, nodeID: self.appTssNodeId)
                .flatMap { requestID in
                    self.pollTssRequest(vaultID: vaultID, tssRequestID: requestID, condition: {
                        return $0.info?.status != TssRequestStatus.MpcProcessing.rawValue })
                }
                .flatMap { tssRequest -> AnyPublisher<TssRequest, UsecaseError> in
                    do {
                        try self.nodeManager.approveTssRequest(tssRequestIDs: tssRequest.info?.request_id ?? "")
                        return self.pollTssRequest(vaultID: vaultID, tssRequestID: tssRequest.info?.request_id ?? "", condition: { $0.info?.status != TssRequestStatus.Success.rawValue && $0.info?.status != TssRequestStatus.KeyGeneratingFailed.rawValue })
                    } catch let error as SDKError {
                        return Fail(error: UsecaseError.from(sdkError: error)).eraseToAnyPublisher()
                    } catch {
                        return Fail(error: UsecaseError.otherError(error)).eraseToAnyPublisher()
                    }
                }
                .receive(on: DispatchQueue.main)
                .sink { completion in
                    self.isPresentingProgress = false
                    switch completion {
                    case .finished:
                        print("KeyGen Completion")
                    case .failure(let error):
                        print("KeyGen err \(error)")
                        self.showError = true
                        self.errorMessage = error.localizedDescription
                    }
                } receiveValue: { tssRequest in
                    switch tssRequest.status.rawValue {
                    case TssRequestStatus.KeyGeneratingFailed.rawValue:
                        self.keyGenSuccess = false
                        self.isPresentingProgress = false
                    case TssRequestStatus.Success.rawValue:
                        print("key gen success\(tssRequest)")
                        self.keyGenSuccess = true
                        self.isPresentingProgress = false
                    default:
                      print("\(String(describing: tssRequest.status.rawValue))")
                    }
                }
                .store(in: &self.cancellables)
        }
        
        
        private func pollTssRequest(
            vaultID: String,
            tssRequestID: String,
            condition: @escaping (TssRequest) -> Bool
        ) -> AnyPublisher<TssRequest, UsecaseError> {
            return pollingManager.poll(
                   interval: 3,
                   maxAttempts: -1,
                   shouldContinue: { condition($0) },
                   operation: {
                       self.vaultUsecase.getTssRequest(vaultID: vaultID, tssRequestID: tssRequestID)
                   }
               )
        }
    }
}
#Preview {
    NavigationView {
        KeyGenView()
    }
}
