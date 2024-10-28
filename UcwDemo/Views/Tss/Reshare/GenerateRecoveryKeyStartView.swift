//
//  GenerateRecoveryKeyStartView.swift
//  ucw-ios-demo
//
//  Created by Yang.Bai on 2024/2/26.
//

import SwiftUI
import Combine


struct GenerateRecoveryKeyStartView: View {
    let screenBackgroundColor = Color(red: 247/255, green: 247/255, blue: 249/255)
    @StateObject var viewModel = ViewModel()

    var body: some View {
        NavigationView {
            ZStack {
                self.screenBackgroundColor.edgesIgnoringSafeArea(.all)
                VStack(spacing: 20) {
                    NavigationLink(destination: GenerateRecoveryKeyView(viewModel: GenerateRecoveryKeyView.ViewModel(reshareRole: .initiator, tssRequestID: "", groupID: ""))) {
                        VStack(alignment: .leading, spacing: 14) {
                            Text("I'm the initiator")
                                .font(.system(size: 20))
                                .foregroundStyle(.black)
                                .fontWeight(.medium)
                            Text("The initiator collects information from each participant and initiates a key gen (The initiator is also a participant)")
                                .font(.system(size: 15))
                                .foregroundStyle(Color(red: 121/255, green: 119/255, blue: 131/255))
                                .multilineTextAlignment(.leading)
                        }
                        .padding()
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .background(Color(red: 205/255, green: 217/255, blue: 255/255))
                        .cornerRadius(10)
                    }
                    NavigationLink(destination: ParticipantView()) {
                        VStack(alignment: .leading, spacing: 14) {
                            Text("I'm a participant")
                                .font(.system(size: 20))
                                .foregroundStyle(.black)
                                .fontWeight(.medium)
                            Text("Participant receives key gen request and participates in key gen")
                                .font(.system(size: 15))
                                .foregroundStyle(Color(red: 121/255, green: 119/255, blue: 131/255))
                                .multilineTextAlignment(.leading)
                        }
                        .padding()
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .background(Color(red: 255/255, green: 179/255, blue: 117/255))
                        .cornerRadius(10)
                    }
                    Spacer()
                }
                .onAppear {
                    self.viewModel.load()
                }
                .padding()
                .navigationTitle("Generate MPC Key")
                .navigationBarTitleDisplayMode(.inline)
                if self.viewModel.progressing {
                    LoadingView(progressText: "SDK initializing ...")
                }
            }
        }
    }
}

extension GenerateRecoveryKeyStartView {
    class ViewModel: ObservableObject {
        @Published var progressing: Bool = false
        @Published var nodeID: String = ""
        @Published var showButton: Bool = false

        private var nodeManager = NodeManager.shared
        private var userLocalStorage = UsersLocalStorage.shared
        private var keychainManager = KeychainManager.standard
        private var usecase = UserUsecase()
        private var cancellables = Set<AnyCancellable>()

        init() {}

        public func load() {
            self.initNode()
        }

        func initNode() {
            let userID = self.userLocalStorage.userInfo?.user.userID ?? ""
            if self.nodeManager.isDBInitialized(database: userID) {
                return
            }
            let password = self.keychainManager.getPassword(userID: userID)
            self.progressing = true

            self.nodeManager.initDB(database: userID, passphrase: password ?? "")
                .flatMap { nodeID in self.usecase.bindNode(nodeID: nodeID) }
                .receive(on: DispatchQueue.main)
                .sink { completion in
                    self.progressing = false
                } receiveValue: { userNode in
                    print("bindNode node success\(userNode)")
                    let nodeID = self.nodeManager.initUCWSDK(database: userID, passphrase: password ?? "")
                    self.nodeID = nodeID
                }
                .store(in: &self.cancellables)
        }
    }
}

#Preview {
    GenerateRecoveryKeyStartView()
}
