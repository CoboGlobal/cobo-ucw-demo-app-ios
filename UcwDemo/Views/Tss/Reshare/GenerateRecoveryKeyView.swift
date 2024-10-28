//
//  GenerateBackupGroupView.swift
//  ucw-ios-demo
//
//  Created by Yang.Bai on 2024/1/29.
//

import Combine
import SwiftUI
import UcwGeneratedClient
import UCWSDK

enum ReshareRole {
    case participant
    case initiator
    case resharefrom
    case recoveryTo
}

struct GenerateRecoveryKeyView: View {
    @StateObject var viewModel: ViewModel

    let screenBackgroundColor = Color(red: 247/255, green: 247/255, blue: 249/255)

    var body: some View {
        ZStack {
            self.screenBackgroundColor.edgesIgnoringSafeArea(.all)

            VStack(alignment: .leading) {
                InfoBoxView(GroupType: "Recovery Key Group")
                KeyGroupBoxView(groupTitle: "Key Holder 1",
                                holderName: self.$viewModel.keyHolder1.holderName,
                                nodeId: self.$viewModel.keyHolder1.nodeID)

                KeyGroupBoxView(groupTitle: "Key Holder 2",
                                holderName: self.$viewModel.keyHolder2.holderName,
                                nodeId: self.$viewModel.keyHolder2.nodeID)
                Spacer()

                if self.viewModel.reshareRole == .initiator {
                    Button(action: {
                        self.viewModel.initiatorConfirm()
                    }) {
                        Text("Confirm")
                            .fontWeight(.bold)
                    }.modifier(ButtonModifier())

                } else if self.viewModel.reshareRole == .recoveryTo {
                    Button(action: {
                        self.viewModel.recoveryStart()
                    }) {
                        Text("Start Key Gen")
                            .fontWeight(.bold)
                    }.modifier(ButtonModifier())
                } else {
                    if let tssRequest = viewModel.tssRequest {
                        if tssRequest.status.rawValue == TssRequestStatus.MpcProcessing.rawValue {
                            HStack {
                                Button("Reject") {
                                    self.viewModel.rejectTssRequest(requestID: self.viewModel.tssRequestID)
                                }.modifier(ButtonModifier())
                                Button("Confirm") {
                                    self.viewModel.confirmTssRequest(requestID: self.viewModel.tssRequestID)
                                }.modifier(ButtonModifier())
                            }
                        }
                    }
                }
            }
            .padding()
            .navigationDestination(isPresented: self.$viewModel.keyGenSuccess) {
                if self.viewModel.reshareRole == .resharefrom {
                    HomeTabView()
                } else {
                    KeyGenSuccessView()
                }
            }
            .onAppear {
                self.viewModel.load()
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
        EmptyView()
    }
}

enum RecoveryRole: Int {
    case unspecified = 0
    case initiator = 1
    case participant = 2
    case from = 3
}

extension GenerateRecoveryKeyView {
    class ViewModel: ObservableObject {
        @Published var errorMessage: String?
        @Published var showError: Bool = false
        @Published var reshareRole: ReshareRole
        @Published var tssRequestID: String
        @Published var groupID: String
        @Published var myNodeID: String = ""
        @Published var isPresentingProgress = false
        @Published var showButton = false
        @Published var progressText = "MPC Key Generating \nPlease don't close app"
        @Published var keyGenSuccess: Bool = false
        @Published var tssRequest: TssRequest?
        @Published var group: Group?
        @Published var keyHolder1: GroupNode = .init()
        @Published var keyHolder2: GroupNode = .init()

        private var userLocalStorage = UsersLocalStorage.shared
        private var vaultUsecase = VaultUsecase()
        private var nodeManager = NodeManager.shared
        private var keychainManager = KeychainManager.standard
        private var userID = ""
        private var keyHolders: [GroupNode]?
        private var cancellables = Set<AnyCancellable>()
        private var pollingManager = PollingManager()

        init(reshareRole: ReshareRole, tssRequestID: String, groupID: String) {
            self.reshareRole = reshareRole
            self.tssRequestID = tssRequestID
            self.groupID = groupID
            self.userID = self.userLocalStorage.userInfo?.user.userID ?? ""

            self.myNodeID = self.nodeManager.getNodeId()
            if self.reshareRole == .initiator {
                self.keyHolder1 = GroupNode(nodeID: self.myNodeID, holderName: self.userLocalStorage.userInfo?.user.email ?? "")
            }
            if self.reshareRole == .recoveryTo {
                self.keyHolder1 = GroupNode(nodeID: self.myNodeID, holderName: self.userLocalStorage.userInfo?.user.email ?? "")
                self.keyHolder2 = GroupNode(nodeID: self.userLocalStorage.userInfo?.vault.coboNodeID ?? "", holderName: "Cobo")
            }
        }

        public func load() {
            if self.tssRequestID != "" {
                self.vaultUsecase.getTssRequest(vaultID: self.vaultID, tssRequestID: self.tssRequestID)
                    .flatMap { tssRequest -> AnyPublisher<(TssRequest, GroupInfo), UsecaseError> in
                        let groupInfoPublisher = self.vaultUsecase.getGroupInfo(vaultID: self.vaultID, groupID: tssRequest.info?.target_group_id ?? "")
                        return Publishers.Zip(Just(tssRequest).setFailureType(to: UsecaseError.self), groupInfoPublisher)
                            .eraseToAnyPublisher()
                    }
                    .receive(on: DispatchQueue.main)
                    .sink { _ in
                    } receiveValue: { tssRequest, groupInfo in
                        self.tssRequest = tssRequest
                        self.refreshGroupInfo(groupInfo: groupInfo)
                    }
                    .store(in: &self.cancellables)
            }

            if self.reshareRole != .recoveryTo && self.groupID != "" {
                self.vaultUsecase.getGroupInfo(vaultID: self.vaultID, groupID: self.groupID)
                    .receive(on: DispatchQueue.main)
                    .sink { _ in
                    } receiveValue: { groupInfo in
                        self.refreshGroupInfo(groupInfo: groupInfo)
                    }
                    .store(in: &self.cancellables)
            }
        }

        func refreshGroupInfo(groupInfo: GroupInfo) {
            self.group = groupInfo.group
            self.keyHolders = groupInfo.groupNodes
            if self.group?.groupType == .mainGroup {
                self.keyHolder1 = GroupNode(nodeID: self.userLocalStorage.userInfo?.vault.coboNodeID ?? "", groupID: self.group?.groupID ?? "", holderName: "Cobo", userID: "")
                self.keyHolder2 = self.keyHolders?[0] ?? GroupNode()
            } else {
                self.keyHolder1 = self.keyHolders?[0] ?? GroupNode()
                self.keyHolder2 = self.keyHolders?[1] ?? GroupNode()
            }
        }

        var vaultID: String {
            self.userLocalStorage.userInfo?.vault.vaultID ?? ""
        }

        var nodeID: String {
            self.nodeManager.getNodeId()
        }

        var email: String {
            self.userLocalStorage.userInfo?.user.email ?? ""
        }

        var mainKeyGroupID: String {
            self.userLocalStorage.userInfo?.vault.mainGroupID ?? ""
        }

        public func initiatorConfirm() {
            self.isPresentingProgress = true

            self.vaultUsecase.generateRecoveryGroup(vaultID: self.vaultID, nodeIDs: [self.keyHolder1.nodeID, self.keyHolder2.nodeID])
                .flatMap {
                    requestID in
                    self.pollTssRequest(vaultID: self.vaultID, tssRequestID: requestID, condition: {
                        $0.info?.status != TssRequestStatus.MpcProcessing.rawValue
                    })
                }
                .flatMap { tssRequest -> AnyPublisher<TssRequest, UsecaseError> in
                    do {
                        try self.nodeManager.approveTssRequest(tssRequestIDs: tssRequest.info?.request_id ?? "")
                        return self.pollTssRequest(vaultID: self.vaultID, tssRequestID: tssRequest.info?.request_id ?? "", condition: { $0.info?.status != TssRequestStatus.Success.rawValue && $0.info?.status != TssRequestStatus.KeyGeneratingFailed.rawValue })
                    } catch let error as SDKError {
                        return Fail(error: UsecaseError.from(sdkError: error)).eraseToAnyPublisher()
                    } catch {
                        return Fail(error: UsecaseError.otherError(error)).eraseToAnyPublisher()
                    }
                }
                .receive(on: DispatchQueue.main)
                .sink { completion in
                    self.showError = false
                    switch completion {
                    case .finished:
                        print("initiatorConfirm ")
                    case .failure(let error):
                        self.showError = true
                        self.errorMessage = error.localizedDescription
                    }
                } receiveValue: { tssRequest in
                    switch tssRequest.status.rawValue {
                    case TssRequestStatus.KeyGeneratingFailed.rawValue:
                        self.keyGenSuccess = false
                        print("initiatorConfirm err \(1)")
                        self.isPresentingProgress = false

                    case TssRequestStatus.Success.rawValue:
                        self.keyGenSuccess = true
                        print("initiatorConfirm Success ")
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
            return self.pollingManager.poll(
                interval: 3,
                maxAttempts: -1,
                shouldContinue: { condition($0) },
                operation: {
                    self.vaultUsecase.getTssRequest(vaultID: vaultID, tssRequestID: tssRequestID)
                }
            )
        }

        func confirmTssRequest(requestID: String) {
            self.isPresentingProgress = true
            self.pollTssRequest(vaultID: self.vaultID, tssRequestID: requestID, condition: {
                $0.info?.status != TssRequestStatus.MpcProcessing.rawValue
            })
            .flatMap { tssRequest -> AnyPublisher<TssRequest, UsecaseError> in
                do {
                    try self.nodeManager.approveTssRequest(tssRequestIDs: tssRequest.info?.request_id ?? "")
                    return self.pollTssRequest(vaultID: self.vaultID, tssRequestID: tssRequest.info?.request_id ?? "", condition: { $0.info?.status != TssRequestStatus.Success.rawValue && $0.info?.status != TssRequestStatus.KeyGeneratingFailed.rawValue })
                } catch let error as SDKError {
                    return Fail(error: UsecaseError.from(sdkError: error)).eraseToAnyPublisher()
                } catch {
                    return Fail(error: UsecaseError.otherError(error)).eraseToAnyPublisher()
                }
            }
            .sink { completion in
                switch completion {
                case .finished:
                    print("confirmTssRequest ")
                case .failure(let error):
                    self.showError = true
                    self.errorMessage = error.localizedDescription
                }
            } receiveValue: { tssRequest in
                switch tssRequest.status.rawValue {
                case TssRequestStatus.KeyGeneratingFailed.rawValue:
                    self.keyGenSuccess = false
                    print("confirmTssRequest failed \(1)")
                    self.isPresentingProgress = false

                case TssRequestStatus.Success.rawValue:
                    self.keyGenSuccess = true
                    print("confirmTssRequest Success ")
                    self.isPresentingProgress = false

                default:
                    print("\(String(describing: tssRequest.status.rawValue))")
                }
            }
            .store(in: &self.cancellables)
        }

        public func recoveryStart() {
            self.isPresentingProgress = true
            self.vaultUsecase.recoverMainGroup(vaultID: self.vaultID, nodeID: self.nodeID, sourceGroupID: self.groupID)
                .flatMap {
                    requestID in
                    self.pollTssRequest(vaultID: self.vaultID, tssRequestID: requestID, condition: {
                        $0.info?.status != TssRequestStatus.MpcProcessing.rawValue
                    })
                }
                .flatMap { tssRequest -> AnyPublisher<TssRequest, UsecaseError> in
                    do {
                        try self.nodeManager.approveTssRequest(tssRequestIDs: tssRequest.info?.request_id ?? "")
                        return self.pollTssRequest(vaultID: self.vaultID, tssRequestID: tssRequest.info?.request_id ?? "", condition: { $0.info?.status != TssRequestStatus.Success.rawValue && $0.info?.status != TssRequestStatus.KeyGeneratingFailed.rawValue })
                    } catch let error as SDKError {
                        return Fail(error: UsecaseError.from(sdkError: error)).eraseToAnyPublisher()
                    } catch {
                        return Fail(error: UsecaseError.otherError(error)).eraseToAnyPublisher()
                    }
                }
                .receive(on: DispatchQueue.main)
                .sink { completion in
                    switch completion {
                    case .finished:
                        print("recoveryStart ")
                    case .failure(let error):
                        self.showError = true
                        self.errorMessage = error.localizedDescription
                    }
                } receiveValue: { tssRequest in
                    switch tssRequest.status.rawValue {
                    case TssRequestStatus.KeyGeneratingFailed.rawValue:
                        self.keyGenSuccess = false
                        print("recoveryStart err \(1)")
                        self.isPresentingProgress = false

                    case TssRequestStatus.Success.rawValue:
                        self.keyGenSuccess = true
                        print("recoveryStart Success ")
                        self.isPresentingProgress = false

                    default:
                        print("\(String(describing: tssRequest.status.rawValue))")
                    }
                }
                .store(in: &self.cancellables)
        }

        public func rejectTssRequest(requestID: String) {
            do {
                try self.nodeManager.rejectTssRequest(tssRequestIDs: requestID, reason: "")
                self.vaultUsecase.reportTssRequest(requestID: requestID, action: TssRequestRepostAction.actionRejected.rawValue)
                    .sink { completion in
                        switch completion {
                        case .finished:
                            print("rejectTssRequest ")
                        case .failure(let error):
                            self.showError = true
                            self.errorMessage = error.localizedDescription
                        }
                    } receiveValue: { _ in
                    }
                    .store(in: &self.cancellables)
            } catch {
                print("rejectTssRequest err \(error)")
            }
        }
    }
}

// #Preview {
//    GenerateRecoveryKeyView(reshareRole: .participant, tssRequestId: "")
// }
