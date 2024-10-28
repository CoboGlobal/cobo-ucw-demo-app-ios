//
//  WalletView.swift
//  UcwDemo
//
//  Created by Yang.Bai on 2024/8/23.
//

import Combine
import SwiftUI

struct WalletView: View {
    @StateObject var viewModel = ViewModel()
    var body: some View {
        NavigationView {
            VStack(alignment: .leading) {
                VStack(alignment: .leading) {
                    HStack {
                        Text("My Wallet")
                            .font(.subheadline)
                            .foregroundColor(Color.black)
                        Text(self.viewModel.userRole)
                            .foregroundColor(Color.white)
                            .padding(.horizontal, 2)
                            .padding(.vertical, 8)
                            .background(Color(red: 0/255, green: 232/255, blue: 23/255))
                            .cornerRadius(6)
                            .font(.caption)
                    }
                    .padding([.leading, .trailing, .top])

                    if !self.viewModel.hasCompletedBackup {
                        VStack(alignment: .leading) {
                            HStack {
                                Image(systemName: "exclamationmark.triangle")
                                    .font(.caption)
                                    .foregroundColor(.red)
                                Text("Back up Your Wallet")
                                    .foregroundColor(.red)
                                    .font(.caption)
                            }
                            .padding()
                            Text("For the safety of your assets, please back up your wallet in time. In case of device loss, app uninstallation, etc., your assets will be lost!")
                                .font(.caption)
                                .padding([.leading, .trailing, .bottom])
                            NavigationLink(destination: BackUpView()) {
                                HStack {
                                    Text("Back up Now ->")
                                        .foregroundColor(.red)
                                        .font(.caption)
                                    Spacer()
                                }
                                .padding([.leading, .trailing, .bottom])
                                .padding(.top, -10)
                            }
                        }
                        .background(Color.white)
                        .padding(.bottom, 12)
                    }
                    List {
                        Section(header:
                            Text("Assets (\(self.viewModel.walletTokens.count))").padding(.leading, 10)
                                .font(.subheadline)
                                .bold()
                        ) {
                            ForEach(self.viewModel.walletTokens, id: \.id) { token in
                                NavigationLink(destination: TokenView(token: token)) {
                                    TokenCell(tokenBalance: token)
                                        .listRowInsets(EdgeInsets())
                                }
                                .buttonStyle(PlainButtonStyle())
                            }
                        }
                        .headerProminence(.increased)
                    }
                    .listStyle(PlainListStyle())
                    .background(Color.white)
                    .padding(.top, -8)
                }
            }

            .navigationBarBackButtonHidden(true)
            .interactiveDismissDisabled(true)
        }
        .onAppear {
            self.viewModel.load()
        }
        .alert(isPresented: self.$viewModel.showError, content: {
            Alert(title: Text("Error"), message: Text(self.viewModel.errorMessage ?? "Unknown error"), dismissButton: .default(Text("OK")))
        })
    }
}

struct TokenCell: View {
    var tokenBalance: TokenBalance
    var url: URL
    init(tokenBalance: TokenBalance) {
        self.tokenBalance = tokenBalance
        if let url = URL(string: tokenBalance.token.iconURL) {
            self.url = url
        } else {
            self.url = URL(fileURLWithPath: "/")
        }
    }

    var body: some View {
        HStack {
            VStack(alignment: .leading) {
                Text(self.tokenBalance.token.tokenID).font(.title2)
                Text(self.tokenBalance.token.chain)
                    .font(.caption)
                    .foregroundColor(.gray)
            }
            Spacer()
            VStack(alignment: .trailing) {
                Text("\(self.tokenBalance.balance.total)").font(.title2)
                Text("available \(self.tokenBalance.balance.avaiable)")
                    .font(.caption)
                    .foregroundColor(.gray)
            }
        }
        .padding(.vertical, 5)
    }
}

extension WalletView {
    static var id: String { "WalletView" }
}

extension WalletView {
    class ViewModel: ObservableObject {
        @Published var walletTokens: [TokenBalance] = []
        @Published var hasCompletedBackup: Bool = false
        @Published var userRole: String = UserRole.Unspecified.rawValue
        @Published var errorMessage: String?
        @Published var showError: Bool = false
        
        private var wallet: Wallet?
        private var nodeID: String = ""
        private let usecase = WalletUsecase()
        private let userUsecase = UserUsecase()
        private let userLocalStorage = UsersLocalStorage.shared
        private let nodeManager = NodeManager.shared
        private var cancellables = Set<AnyCancellable>()

        init() {
            self.nodeID = self.nodeManager.getNodeId()
            self.userRole = self.userLocalStorage.userInfo?.NodeRole(nodeID: self.nodeID).rawValue ?? ""
            self.wallet = self.userLocalStorage.userInfo?.wallet
        }

        func load() {
            self.createWallet()
            self.listWalletTokens(walletID: self.wallet?.walletID ?? "")
        }

        func refresh(userInfo: UserInfo) {
            self.userRole = userInfo.NodeRole(nodeID: self.nodeManager.getNodeId()).rawValue
            self.wallet = userInfo.wallet
            self.userLocalStorage.setUserInfo(userInfo: userInfo)
        }

        func createWallet() {
            let id = NanoID.new(15)
            let name = "wallet".appending(id)
            self.usecase.createWallet(vaultID: self.userLocalStorage.userInfo?.vault.vaultID ?? "", name: name)
                .flatMap { _ in self.userUsecase.getUserInfo() }
                .receive(on: DispatchQueue.main)
                .sink { completion in
                    switch completion {
                    case .finished:
                        print("createWallet Completion")
                    case .failure(let error):
                        print("createWallet err \(error)")
                        self.errorMessage = error.localizedDescription
                        self.showError = true
                    }
                } receiveValue: { userInfo in
                    self.refresh(userInfo: userInfo)
                    self.listWalletTokens(walletID: self.wallet?.walletID ?? "")
                }
                .store(in: &self.cancellables)
        }

        public func listWalletTokens(walletID: String) {
            if walletID == "" {
                return
            }
            self.usecase.loadWalletTokens(walletID: walletID)
                .receive(on: DispatchQueue.main)
                .sink { completion in
                    switch completion {
                    case .finished:
                        print("loadWalletTokens Completion")
                    case .failure(let error):
                        print("loadWalletTokens Failed \(error)")
                    }
                } receiveValue: { tokenBalance in
                    self.walletTokens = tokenBalance
                }
                .store(in: &self.cancellables)
        }
    }
}

#Preview {
    WalletView()
}
