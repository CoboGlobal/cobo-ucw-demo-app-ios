//
//  SendView.swift
//  ucw-ios-demo
//
//  Created by Yang.Bai on 2024/1/29.
//

import SwiftUI
import Combine

struct SendView: View {
    @StateObject var viewModel: ViewModel
    @State private var isPresentingScanner = false
    
    init(token: TokenBalance) {
        _viewModel = StateObject(wrappedValue: ViewModel(token: token))
    }

    var body: some View {
        NavigationView {
            ScrollView {
                VStack(alignment: .leading, spacing: 16) {
                    Section(header: Text("To")
                        .foregroundColor(Color(red: 35/255, green: 44/255, blue: 77/255, opacity: 0.6))
                    ) {
                        HStack {
                            TextField("\(self.viewModel.tokenAddress.chain) address", text: self.$viewModel.transactionDetail.to)
                            
                            Button(action: {
                                self.isPresentingScanner = true
                            }) {
                                Image(systemName: "qrcode.viewfinder")
                                    .foregroundColor(.gray)
                            }
                            .sheet(isPresented: self.$isPresentingScanner) {
                                QRCodeScanner(presentScanner: self.$isPresentingScanner, scannedCode: self.$viewModel.transactionDetail.to)
                            }
                        }
                        .padding()
                        .background(Color.white)
                        .cornerRadius(10)
                    }
                    
                    Section(header: HStack {
                        Text("Amount")
                            .foregroundColor(Color(red: 35/255, green: 44/255, blue: 77/255, opacity: 0.6))
                        
                        Spacer()
                        Text("available \(self.viewModel.tokenAddress.available) \(self.viewModel.tokenAddress.tokenID)")
                            .foregroundColor(.gray)
                    }) {
                        TextEditor(text: self.$viewModel.transactionDetail.amount)
                            .frame(minHeight: 3 * 40)
                            .padding()
                            .keyboardType(.decimalPad)
                            .background(Color.white)
                            .cornerRadius(10)
                            .font(.system(size: 40))
                    }
                    
                    Section(header: Text("Miner Fee")
                        .foregroundColor(Color(red: 35/255, green: 44/255, blue: 77/255, opacity: 0.6))
                    ) {
                        VStack(alignment: .leading) {
                            HStack {
                                VStack {
                                    let minerFee = self.viewModel.minerFee
                                    let feeAmount = minerFee.getFee()
                                    Text("\(feeAmount) \(self.viewModel.tokenAddress.tokenID)").font(.system(size: 15)).foregroundColor(.secondary)
                                }
                                Spacer()
                                HStack {
                                    Text(self.viewModel.minerFee.level.rawValue).font(.system(size: 15))
                                        .foregroundColor(.secondary)
                                    Image(systemName: "chevron.right")
                                        .foregroundColor(.secondary)
                                }
                            }
                        }
                        .padding()
                        .background(Color.white)
                        .cornerRadius(10)
                        .onTapGesture {
                            self.viewModel.navigateToFeeView = true
                        }
                    }
                    Spacer()
                    Button(action: {
                        self.viewModel.validateAndSend()
                    }) {
                        Text("Next")
                            .fontWeight(.bold)
                    }.modifier(ButtonModifier())
                    .navigationDestination(isPresented: self.$viewModel.isPresentingSignView) {
                        TransactionDetailView(transactionDetail: self.viewModel.transactionDetail)
                    }
                    .navigationDestination(isPresented: $viewModel.navigateToFeeView) {
                        if viewModel.transactionDetail.canEstimateFee {
                            FeeView(viewModel: FeeView.ViewModel(fee: $viewModel.minerFee, toTransfer: viewModel.transactionDetail))
                        }
                    }
                    .alert(isPresented: self.$viewModel.showAlert) {
                        Alert(
                            title: Text(self.viewModel.alertTitle),
                            message: Text(self.viewModel.alertMessage),
                            dismissButton: .default(Text("OK"))
                        )
                    }
                }
                
                .padding()
            }
          
            .background(Color(red: 247/255, green: 247/255, blue: 249/255))
            .navigationBarTitleDisplayMode(.inline)
            .edgesIgnoringSafeArea(.bottom)
            .onAppear {
                self.viewModel.setWalletToken()
            }
        }
    }
}

extension SendView {
    class ViewModel: ObservableObject {
        @Published var minerFee: Fee
        @Published var isPresentingSignView = false    
        @Published var navigateToFeeView: Bool = false
        @Published var transactionDetail: TransactionDetail
        @Published var showAlert = false
        @Published var alertMessage = "Invalid amount. Please enter a value greater than 0 and ensure the total does not exceed your asset balance."
        @Published var alertTitle = "Invalid To Address"
        @Published var estimateFee: EstimateFee?
        @Published var tokenAddress: TokenAddress = TokenAddress(tokenBalance: TokenBalance(walletID: "", token: Token(), balance: Balance()), addressList: [])
        
        
        private var transactionUsecase = TransactionUsecase()
        private var walletUsecase = WalletUsecase()
        private var userLocalStorage = UsersLocalStorage.shared
        private var cancellables = Set<AnyCancellable>()
        private var token: TokenBalance
        
        init(token: TokenBalance) {
            self.minerFee = Fee()
            self.token = token
            self.transactionDetail = TransactionDetail(transactionType:.typeWithdrawal, token: token.token, walletID: token.walletID)
        }
        
        
        func validateAndSend() {
            if self.transactionDetail.to == "" {
                self.showAlert = true
                self.alertMessage = "Invalid To Address"
                return
            }
            if self.isAmountValid() {
                self.transactionDetail.fee = self.minerFee
                self.isPresentingSignView = true
                self.transactionDetail.from = self.tokenAddress.firstAddress
                self.transactionDetail.chain = self.tokenAddress.chain
                self.transactionDetail.transactionType = .typeWithdrawal
                return
            }
        }
        
        public func setWalletToken() {
            self.walletUsecase.getWalletToken(walletID: self.token.walletID, tokenID: self.token.id)
                .receive(on: DispatchQueue.main)
                .sink { completion in
                } receiveValue: { tokenAddress in
                    self.tokenAddress = tokenAddress
                    self.transactionDetail.from = self.tokenAddress.firstAddress
                }
                .store(in: &self.cancellables)
        }
        
        func isAmountValid() -> Bool {
            guard let amountValue = Decimal(string: self.transactionDetail.amount), amountValue > 0 else {
                print("invalid amountValue")
                self.showAlert = true
                return false
            }
            
            let feeAmount = self.minerFee.feeAmount
             
            // 检验资产总额是否大于或等于用户输入的金额和矿工费之和
            guard let totalAssetAmount = Decimal(string: self.tokenAddress.available), totalAssetAmount >= amountValue + feeAmount else {
                self.showAlert = true
                print("invalid totalAssetAmount")
                self.alertTitle = "Insufficient balance"
                return false
            }

            return true
        }
    }
}

//#Preview {
//    NavigationView {
//        SendView(asset: Asset(icon: "", name: "BTC", chainName: "Bitcoin", amount: "1.2", dollarValue: "3.333", address: "wwwqeq", coin: "", walletId: ""))
//    }
//}
