//
//  ParticipantVIew.swift
//  ucw-ios-demo
//
//  Created by Yang.Bai on 2024/2/26.
//

import Combine
import SwiftUI

struct ParticipantView: View {
    let screenBackgroundColor = Color(red: 247/255, green: 247/255, blue: 249/255)
    @StateObject var viewModel = ViewModel()

    var body: some View {
        NavigationView {
            ZStack {
                self.screenBackgroundColor.edgesIgnoringSafeArea(.all)
                VStack(alignment: .leading) {
                    HStack {
                        Text("Send the following information to the initiator")
                    }
                    
                    VStack(alignment: .leading) {
                        HStack {
                            Text("My Account")
                                .font(.system(size: 14))
                                .foregroundColor(Color.secondary)
                        }
                        HStack {
                            Text(self.viewModel.account)
                                .font(.system(size: 15))
                                .padding(12)
                            Spacer()
                        }
                        
                        HStack {
                            Text("My TSS Node ID")
                                .font(.system(size: 14))
                                .foregroundColor(Color.secondary)
                        }
                        HStack {
                            Text(self.viewModel.tssNodeId)
                                .font(.system(size: 15))
                                .padding(12)
                                .padding(.trailing, 15)
                                .overlay(
                                    Button(action: {
                                        UIPasteboard.general.string = self.viewModel.tssNodeId
                                    }) {
                                        Image(systemName: "doc.on.clipboard")
                                            .foregroundColor(.blue)
                                    }
                                    .padding(.trailing, 5),
                                    alignment: .trailing
                                )
                            Spacer()
                        }
                    }
                    .padding()
                    .background(Color.white)
                    .cornerRadius(8)
                    .edgesIgnoringSafeArea(.all)
                    .onAppear {
                        self.viewModel.reloadNodeID()
                    }
                    HStack {
                        Text("Recovery key request")
                    }.padding(.top, 20)
                        .onAppear {
                            self.viewModel.fetchTssRequests()
                        }
                        .onDisappear {
                            self.viewModel.cancel()
                        }
                    
                    VStack(alignment: .leading) {
                        if self.viewModel.tssRequests.isEmpty {
                            HStack {
                                Text("After the initiator initiates, you will receive the key gen request")
                                    .font(.system(size: 14))
                                    .foregroundColor(Color.secondary)
                                    .padding()
                            }
                        } else {
                            VStack {
                                HStack {
                                    VStack(alignment: .leading) {
                                        Text("A new Recovery Key group Request")
                                            .foregroundStyle(Color(red: 31/255, green: 50/255, blue: 214/255))
                                        NavigationLink(destination: GenerateRecoveryKeyView(viewModel: .init(reshareRole: .participant, tssRequestID: self.viewModel.tssRequests[0].id, groupID: ""))) {
                                            Text("View")
                                                .foregroundColor(.blue)
                                        }
                                    }
                                }
                                .padding()
                                .background(Color.white)
                                .cornerRadius(10)
                            }
                        }
                    }
                    .padding()
                    .background(Color.white)
                    .cornerRadius(8)
                    
                    Spacer()
                }.padding()
            }
        }
    }
}

extension ParticipantView {
    @MainActor
    class ViewModel: ObservableObject {
        @Published var account: String = ""
        @Published var tssNodeId: String = ""
        @Published var isPresentingGroupDetailView: Bool = false
        @Published var tssRequests: [TssRequest] = []
                
        var nodeManager = NodeManager.shared
        var vaultUsecase = VaultUsecase()
        var userLocalStorage = UsersLocalStorage.shared
        private var pollingManager = PollingManager()
        private var cancellables = Set<AnyCancellable>()

        init() {
            self.tssNodeId = nodeManager.getNodeId()
            self.account = userLocalStorage.userInfo?.user.email ?? ""
        }
        
        public func cancel() {
            print("MyViewModel is being deinitialized")
            pollingManager.stopPolling()
        }

        func reloadNodeID() {
            tssNodeId = nodeManager.getNodeId()
        }
        
        public func fetchTssRequests() {
            pollTssRequest(condition: { _ in
                true
            })
            .receive(on: DispatchQueue.main)
            .sink { completion in
                switch completion {
                case .finished:
                    print("estimateTransactionFee Completion")
                case .failure(let error):
                    print("estimateTransactionFee err \(error)")
                }
            } receiveValue: { res in
                for each in res {
                    if each.tssType.rawValue == TssType.TssGenerateRecoveryKeySecret.rawValue {
                        if !self.tssRequests.contains(where: { $0.id == each.id }) {
                            self.tssRequests.append(each)
                        }
                    }
                }
            }
            .store(in: &cancellables)
        }
        
        private func pollTssRequest(
            condition: @escaping ([TssRequest]) -> Bool
        ) -> AnyPublisher<[TssRequest], UsecaseError> {
            return pollingManager.poll(
                interval: 5,
                maxAttempts: -1,
                shouldContinue: { condition($0) },
                operation: {
                    self.vaultUsecase.listTssRequests(vaultID: self.userLocalStorage.userInfo?.vault.vaultID ?? "", nodeID: self.tssNodeId, status: TssRequestStatus.KeyGenerating.rawValue)
                }
            )
        }
    }
}

#Preview {
    ParticipantView()
}
