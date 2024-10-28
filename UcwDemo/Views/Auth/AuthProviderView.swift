//
//  AuthProviderView.swift
//  UcwDemo
//
//  Created by Yang.Bai on 2024/8/22.
//

import Combine
import SwiftUI
import UcwGeneratedClient

struct AuthProviderView: View {
    @StateObject var viewModel = ViewModel()
    var body: some View {
        NavigationStack(path: self.$viewModel.navigationPath) {
            ZStack {
                VStack {
                    TextField("Email", text: self.$viewModel.email)
                        .textFieldStyle(.roundedBorder)
                        .padding()
                        .keyboardType(.emailAddress)
                        .autocapitalization(.none)

                    Button("Sign In") {
                        self.viewModel.SignIn()
                    }
                    .modifier(ButtonModifier())
                    .padding()
                }
                .navigationDestination(for: String.self) { target in
                    switch target {
                    case KeyGenView.id:
                        KeyGenView()
                    case PinCodeView.id:
                        PinCodeView()
                    case HomeTabView.id:
                        HomeTabView()
                    case ReSetupIndexVIew.id:
                        ReSetupIndexVIew()
                    case WalletView.id:
                        WalletView()
                    default:
                        EmptyView()
                    }
                }
                .alert(isPresented: self.$viewModel.showError, content: {
                    Alert(title: Text("Error"), message: Text(self.viewModel.errorMessage ?? "Unknown error"), dismissButton: .default(Text("OK")))
                })
                if self.viewModel.progressing {
                    LoadingView(progressText: "")
                }
            }
        }
    }
}

enum AuthAction {
    case signIn
    case signUp
}

enum DestinationIdentifier {
    case keygenView
    case reSetupView
    case none
    case pinCodeView
    case walletView
}

extension AuthProviderView {
    class ViewModel: ObservableObject {
        @Published var errorMessage: String?
        @Published var showError: Bool = false
        @Published var email: String = ""
        @Published var progressing = false
        @Published var keyGenSuccess = false
        @Published var navigationPath = NavigationPath()
        
        private var userInfo: UserInfo?
        private var usecase: UserUsecaseProtocol = UserUsecase()
        private var vaultUsecase: VaultUsecaseProtocol = VaultUsecase()
        private var nodeManager = NodeManager.shared
        private var keychainManager = KeychainManager.standard
        private var userLocalStorage = UsersLocalStorage.shared
        private var cancellables = Set<AnyCancellable>()

        public func SignIn() {
            self.progressing = true
            self.usecase.login(email: self.email)
                .flatMap { _ in self.vaultUsecase.initVault() }
                .flatMap { _ in self.usecase.getUserInfo() }
                .receive(on: DispatchQueue.main)
                .sink { completion in
                    self.progressing = false
                    if case .failure(let error) = completion {
                        print("SignIn err \(error)")
                        self.errorMessage = error.localizedDescription
                        self.showError = true
                    }
                } receiveValue: { userInfo in
                    self.signInSuccess(userInfo: userInfo)
                }
                .store(in: &self.cancellables)
        }

        func signInSuccess(userInfo: UserInfo) {
            self.userInfo = userInfo
            self.userLocalStorage.setUserInfo(userInfo: userInfo)
            if self.keychainManager.readPINCode(userID: userInfo.user.userID) == nil {
                self.navigate(to: .pinCodeView)
                return
            }

            let userID = userInfo.user.userID
            let nodeID = self.nodeManager.initUCWSDK(database: userID, passphrase: self.keychainManager.getPassword(userID: userID) ?? "")

            self.progressing = false
            if nodeID == "" && userInfo.KeyGenSuccess() {
                self.navigate(to: .reSetupView)
                return
            }

            if userInfo.KeyGenSuccess() {
                if let node = userInfo.userNodes.first(where: { $0.nodeID == nodeID }) {
                    if node.userRole == .Unspecified {
                        self.navigate(to: .reSetupView)
                    } else {
                        self.navigate(to: .walletView)
                    }
                } else {
                    self.navigate(to: .reSetupView)
                }
            } else {
                self.navigate(to: .keygenView)
            }
        }

        func navigate(to destination: DestinationIdentifier) {
            self.progressing = false
            switch destination {
            case .keygenView:
                self.navigationPath.append(KeyGenView.id)
            case .reSetupView:
                self.navigationPath.append(ReSetupIndexVIew.id)
            case .pinCodeView:
                self.navigationPath.append(PinCodeView.id)
            case .walletView:
                self.navigationPath.append(HomeTabView.id)
            default:
                return
            }
        }
    }
}

#Preview {
    AuthProviderView()
}
