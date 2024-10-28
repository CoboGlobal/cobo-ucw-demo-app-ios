//
//  RecoveryView.swift
//  ucw-ios-demo
//
//  Created by Yang.Bai on 2024/2/29.
//

import Combine
import SwiftUI

struct RecoveryView: View {
    @ObservedObject var viewModel = ViewModel()

    let screenBackgroundColor = Color(red: 247/255, green: 247/255, blue: 249/255)
    var body: some View {
        NavigationView {
            ZStack {
                self.screenBackgroundColor.edgesIgnoringSafeArea(.all)
                VStack {
                    Spacer()
                    HStack {
                        Text("Select which group to use for recovery")
                    }
                    Spacer()
                    VStack {
                        ForEach(self.viewModel.tssGroups, id: \.groupID) { tssGroup in
                            OptionView(nodeId: tssGroup.groupID, title: tssGroup.groupID, isSelected: self.viewModel.selectedGroup == tssGroup.groupID) {
                                self.viewModel.selectedGroup = tssGroup.groupID
                            }
                        }
                    }
                    .background(Color.white)
                    .cornerRadius(10)
                    Spacer()
                    Button(action: {
                        self.viewModel.toRecoveryDetail = true
                    }) {
                        Text("Continue")
                            .fontWeight(.bold)
                    }.modifier(ButtonModifier())
                        .navigationDestination(isPresented: self.$viewModel.toRecoveryDetail) {
                            GenerateRecoveryKeyView(viewModel: .init(reshareRole: .recoveryTo, tssRequestID: "", groupID: self.viewModel.selectedGroup))
                        }
                }.padding()
                    .onAppear {
                        self.viewModel.load()
                    }

                if self.viewModel.progressing {
                    LoadingView(progressText: "SDK initializing ...")
                }
            }
        }
    }
}

extension RecoveryView {
    class ViewModel: ObservableObject {
        @Published var tssGroups: [Group] = []
        @Published public var selectedGroup: String = ""
        @Published public var toRecoveryDetail: Bool = false
        @Published var nodeID: String = ""
        @Published var progressing: Bool = false

        var vaultUsecase = VaultUsecase()
        var userStorage = UsersLocalStorage.shared
        var nodeManager: NodeProtocol = NodeManager.shared
        var userLocalStorage = UsersLocalStorage.shared
        var keychainManager = KeychainManager.standard
        var usecase: UserUsecaseProtocol = UserUsecase()
        private var cancellables = Set<AnyCancellable>()

        init() {
            self.selectedGroup = self.tssGroups.first?.groupID ?? ""
        }

        public func load() {
            self.initNode()
            self.queryRecoveryGroup()
        }

        func initNode() {
            let userID = self.userLocalStorage.userInfo?.user.userID ?? ""
            if self.nodeManager.isDBInitialized(database: userID) {
                return
            }
            self.progressing = true
            let password = self.keychainManager.getPassword(userID: userID)

            self.nodeManager.initDB(database: userID, passphrase: password ?? "")
                .flatMap { nodeID in self.usecase.bindNode(nodeID: nodeID)}
                .receive(on: DispatchQueue.main)
                .sink { completion in
                    self.progressing = false
                } receiveValue: { userNode in
                    let nodeID = self.nodeManager.initUCWSDK(database: userID, passphrase: password ?? "")
                    self.nodeID = nodeID
                }
                .store(in: &self.cancellables)
        }

        func queryRecoveryGroup() {
            self.vaultUsecase.listGroups(vaultID: self.userStorage.userInfo?.vault.vaultID ?? "", groupType: UCWGroupType.recoveryGroup.rawValue)
                .receive(on: DispatchQueue.main)
                .sink { completion in
                } receiveValue: { groups in
                    self.tssGroups = groups
                }
                .store(in: &self.cancellables)
        }
    }
}

#Preview {
    RecoveryView()
}
