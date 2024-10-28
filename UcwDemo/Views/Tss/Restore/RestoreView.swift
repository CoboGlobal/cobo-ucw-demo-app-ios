//
//  RestoreView.swift
//  ucw-ios-demo
//
//  Created by Yang.Bai on 2024/2/26.
//

import SwiftUI

struct RestoreView: View {
    @State private var selectedOption: SelectedOption = .optionOne
    @StateObject var viewModel = ViewModel()
    let screenBackgroundColor = Color(red: 247/255, green: 247/255, blue: 249/255)

    var body: some View {
        NavigationView {
            ZStack {
                self.screenBackgroundColor.edgesIgnoringSafeArea(.all)
                VStack {
                    Spacer()
                    HStack(alignment: /*@START_MENU_TOKEN@*/ .center/*@END_MENU_TOKEN@*/) {
                        Text("Please select the TSS Node IDs to restore the MPC Key Shares associated with them.").font(.system(size: 15))
                    }
                    VStack {
                        ForEach(viewModel.userNodes, id: \.id) { userNode in
                            OptionView(nodeId: userNode.nodeID, title: userNode.userRole.rawValue, isSelected: viewModel.selectedNodeId == userNode.nodeID) {
                                viewModel.selectedNodeId = userNode.nodeID
                            }
                        }
                    }.background(.white)
                    Spacer()
                    Button(action: {
                        if viewModel.selectedNodeId != "" {
                            self.viewModel.showModal = true
                        }
                    }) {
                        Text("Continue")
                            .fontWeight(.bold)
                    }.modifier(ButtonModifier())
                }.padding()
                .navigationDestination(isPresented: self.$viewModel.done) {
                    HomeTabView()
                }
            }
            .overlay {
                ZStack {
                    if self.viewModel.showModal {
                        Color.black.opacity(0.5)
                            .edgesIgnoringSafeArea(.all)
                            .onTapGesture {
                                self.viewModel.showModal = false
                            }
                        ModalView(viewModel: self.viewModel)
                            .frame(maxWidth: .infinity, maxHeight: .infinity)
                            .cornerRadius(12)
                            .padding()
                    }
                    ZStack {
                        if self.viewModel.restoreProgressing {
                            Color.black.opacity(0.5)
                                .edgesIgnoringSafeArea(.all)
                            ProgressViewOverlay(progressText: self.$viewModel.progressText, showButton: self.$viewModel.showButton, buttonLabel: "ok", buttonAction: self.viewModel.goToWalletView)
                                .frame(maxWidth: .infinity, maxHeight: .infinity)
                        }
                    }
                }
            }
        }
    }
}

enum SelectedOption {
    case none
    case optionOne
    case optionTwo
}

struct OptionView: View {
    let nodeId: String
    let title: String
    var isSelected: Bool
    var action: () -> Void

    var body: some View {
        HStack {
            Image(systemName: self.isSelected ? "checkmark.circle.fill" : "circle")
                .resizable()
                .frame(width: 24, height: 24)
                .foregroundColor(self.isSelected ? .green : .gray)
                .onTapGesture { self.action() }

            VStack(alignment: .leading, spacing: 4) {
                HStack {
                    Text(self.title)
                        .font(.caption)
                        .foregroundColor(.gray)
                }
                HStack {
                    Text(self.nodeId)
                        .fontWeight(.bold)
                    Spacer()
                }
            }
            .padding()
            .background(Color(red: 248/255, green: 249/255, blue: 252/255))
            .cornerRadius(8)

            Spacer()

        }.padding()
    }
}

struct ModalView: View {
    @ObservedObject var viewModel: RestoreView.ViewModel

    var body: some View {
        ZStack {
            VStack(spacing: 20) {
                Text("Enter recovery passphrase")
                    .font(.headline)

                HStack {
                    if self.viewModel.showPassword {
                        TextField("Password", text: self.$viewModel.password)
                            .textFieldStyle(RoundedBorderTextFieldStyle())
                    } else {
                        SecureField("Password", text: self.$viewModel.password)
                            .textFieldStyle(RoundedBorderTextFieldStyle())
                    }

                    Button(action: {
                        self.viewModel.showPassword.toggle()
                    }) {
                        Image(systemName: self.viewModel.showPassword ? "eye.slash.fill" : "eye.fill")
                    }
                }

                HStack {
                    TextField("secrets", text: self.$viewModel.secrets)
                        .textFieldStyle(RoundedBorderTextFieldStyle())
                }

                HStack(spacing: 20) {
                    Button("Cancel") {
                        self.viewModel.showModal = false
                    }
                    .foregroundColor(.red)

                    Button("Confirm") {
                        self.viewModel.showModal = false
                        self.viewModel.restore(passphrase: self.viewModel.password)
                    }
                }
            }
         
            .frame(width: UIScreen.main.bounds.width - 60,
                   height: UIScreen.main.bounds.width - 100)
            .padding()
            .background(Color.white)
            .cornerRadius(10)
            .shadow(radius: 20)
            .padding(40)
        }
    }
}

extension RestoreView {
    class ViewModel: ObservableObject {
        @Published var isPresented = false
        @Published var showModal = false
        @Published var password = ""
        @Published var showPassword = false
        @Published var restoreProgressing = false
        @Published var selectedNodeId = ""
        @Published var secrets = ""
        @Published var showButton = false
        @Published var progressText: String = "MPC Key Restore \n Please don't close app"
        @Published var done: Bool = false
        @Published var userNodes: [UserNode] = []

        private var nodeManager = NodeManager.shared
        private var keychainManager = KeychainManager.standard
        private var userLocalStorage = UsersLocalStorage.shared
        private var userID = ""

        init() {
            self.userID = self.userLocalStorage.userInfo?.user.userID ?? ""
            self.userNodes = self.userLocalStorage.userInfo?.userNodes ?? []
        }

        public func restore(passphrase: String) {
            self.restoreProgressing = true
            do {
                try self.nodeManager.restore(database: self.userID, passphrase: self.keychainManager.getPassword(userID: self.userID) ?? "", backupPassphrase: passphrase, secrets: self.secrets)
                print("restore finished====")
                if let passphrase = keychainManager.getPassword(userID: self.userID) {
                    let nodeID = self.nodeManager.initUCWSDK(database: self.userID, passphrase: passphrase)
                    print("restore node", nodeID)
                    self.showButton = true
                    self.progressText = "Restore Success"
                }
            } catch {
                self.progressText = "Restore Failed \(error)"
                self.showButton = true
            }
        }

        func goToWalletView() {
            self.showButton = false
            self.restoreProgressing = false
            self.progressText = ""
            self.done = true
        }
    }
}

#Preview {
    RestoreView()
}
