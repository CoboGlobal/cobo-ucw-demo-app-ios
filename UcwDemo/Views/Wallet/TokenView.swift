//
//  AssetView.swift
//  ucw-ios-demo
//
//  Created by Yang.Bai on 2024/2/8.
//

import Combine
import SwiftUI

struct TokenView: View {
    @StateObject var viewModel: ViewModel
    init(token: TokenBalance) {
        _viewModel = StateObject(wrappedValue: ViewModel(token: token))
    }

    var body: some View {
        VStack(alignment: .leading) {
            TokenCell(tokenBalance: self.viewModel.tokenBalance)
                .padding()

            Spacer()
            Divider()
            Text("Transactions History")
                .font(.system(size: 16, weight: .medium))
                .padding([.leading, .top])
                .foregroundColor(Color(red: 115/255, green: 121/255, blue: 139/255, opacity: 1))
            ScrollView {
                if self.viewModel.transactions.isEmpty {
                    VStack {
                        Text("No transactions yet")
                            .foregroundColor(Color(red: 151/255, green: 151/255, blue: 151/255, opacity: 1))
                            .padding(.top, 200)

                    }.frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .center)
                } else {
                    VStack {
                        ForEach(self.viewModel.transactions, id: \.id) { transaction in
                            NavigationLink(destination: TransactionDetailView(transactionDetail: transaction)) {
                                TransactionCellView(transaction: transaction)
                                    .padding(.horizontal)
                            }
                            Divider()
                        }
                    }
                }
            }

            Spacer()

            HStack {
                NavigationLink(destination: ReceiveView(tokenAddress: self.viewModel.tokenAddress)) {
                    Text("Receive")
                        .foregroundColor(.white)
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(Color.black)
                }
                if self.viewModel.role == .Main || self.viewModel.role == .Admin {
                    NavigationLink(destination: SendView(token: self.viewModel.tokenBalance)) {
                        Text("Send")
                            .foregroundColor(.white)
                            .frame(maxWidth: .infinity)
                            .padding()
                            .background(Color(red: 31/255, green: 50/255, blue: 214/255))
                    }
                }
            }
            .padding([.leading, .trailing, .bottom])
        }
        .navigationBarTitleDisplayMode(.inline)
        .navigationTitle("Asset")
        .onAppear {
            self.viewModel.load()
        }
    }
}

extension TokenView {
    class ViewModel: ObservableObject {
        @Published var transactions: [TransactionDetail]
        @Published var tokenAddress: TokenAddress = .init(tokenBalance: TokenBalance(walletID: "", token: Token(), balance: Balance()), addressList: [])
        @Published var role: UserRole = .Unspecified
        @Published var tokenBalance: TokenBalance

        private var cancellables = Set<AnyCancellable>()
        private var transactionUsecase = TransactionUsecase()
        private var walletUsecase = WalletUsecase()
        private var userUsecase = UserUsecase()
        private var userLocalStorage = UsersLocalStorage.shared
        private var nodeManager = NodeManager.shared
        private var fee = Fee()
        private var nodeID: String = ""
        
        init(token: TokenBalance) {
            self.transactions = []
            self.tokenBalance = token
            self.role = self.getUserRole()
        }

        public func load() {
            self.fetchTransactions()
            self.getWalletToken()
        }

        func refresh(userInfo: UserInfo) {
            self.role = userInfo.NodeRole(nodeID: self.nodeManager.getNodeId())
            self.userLocalStorage.setUserInfo(userInfo: userInfo)
        }

        public func getUserRole() -> UserRole {
            self.nodeID = self.nodeManager.getNodeId()
            return self.userLocalStorage.userInfo?.NodeRole(nodeID: self.nodeID) ?? .Unspecified
        }

        public func fetchTransactions() {
            self.transactionUsecase.listTransactions(walletID: self.tokenBalance.walletID, tokenID: self.tokenBalance.token.tokenID, type: .typeUnspecified)
                .receive(on: DispatchQueue.main)
                .sink { completion in
                } receiveValue: { txList in
                    self.transactions = txList
                }
                .store(in: &self.cancellables)
        }

        public func getWalletToken() {
            self.walletUsecase.getWalletToken(walletID: self.tokenBalance.walletID, tokenID: self.tokenBalance.token.tokenID)
                .receive(on: DispatchQueue.main)
                .sink { completion in
                } receiveValue: { tokenAddress in
                    self.tokenAddress = tokenAddress
                    self.addWalletAddress()
                }
                .store(in: &self.cancellables)
        }

        public func addWalletAddress() {
            let addressList: [Address] = self.tokenAddress.addressList
            if !addressList.isEmpty {
                return
            }
            self.walletUsecase.addWalletAddress(walletID: self.tokenBalance.walletID, chainID: self.tokenBalance.token.tokenID)
                .receive(on: DispatchQueue.main)
                .sink { completion in
                } receiveValue: { address in
                    self.tokenAddress = TokenAddress(tokenBalance: self.tokenBalance, addressList: [address])
                }
                .store(in: &self.cancellables)
        }
    }
}

// #Preview {
//    NavigationView {
//        AssetView(asset: Asset(icon: "", name: "BTC", chainName: "Bitcoin", amount: "1245.33", dollarValue: "8099901", address: "123123asdasdasdasd", coin: "", walletId: ""))
//    }
// }
