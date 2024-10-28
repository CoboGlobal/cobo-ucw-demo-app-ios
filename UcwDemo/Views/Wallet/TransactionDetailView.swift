//
//  TransactionDetailView.swift
//  UcwDemo
//
//  Created by Yang.Bai on 2024/8/23.
//

import Combine
import SwiftUI
import UcwGeneratedClient
import UCWSDK

struct TransactionDetailView: View {
    @StateObject var viewModel: ViewModel
    @State private var showProgressButton = false

    init(transactionDetail: TransactionDetail) {
        _viewModel = StateObject(wrappedValue: ViewModel(transactionDetail: transactionDetail))
    }
    
    let fieldValueColor = Color(red: 35/255, green: 44/255, blue: 77/255, opacity: 0.6)
    let screenBackgroundColor = Color(red: 247/255, green: 247/255, blue: 249/255)
    let boxBackgroundColor = Color.white
    
    var body: some View {
        ZStack {
            self.screenBackgroundColor.edgesIgnoringSafeArea(.all)
            VStack(spacing: 24) {
                VStack {
                    self.DetailRow(label: "Transaction Type", value: self.viewModel.transactionDetail?.transactionType.description ?? "")
                    self.DetailRow(label: "Chain", value: self.viewModel.transactionDetail?.chain ?? "")
                    if let _ = self.viewModel.transactionDetail?.createTimestamp {
                        self.DetailRow(label: "Time Created", value: self.viewModel.transactionDetail?.formattedDate ?? "")
                    }
                    if let txHash = self.viewModel.transactionDetail?.txHash {
                        self.DetailRow(label: "TX Hash", value: txHash, action: {
                            self.viewModel.copyToClipboard(txHash)
                        })
                    }
                    if let status = self.viewModel.transactionDetail?.status {
                        self.DetailRow(label: "TX Status", value: status.description)
                    }
                }
                .padding(.vertical, 20)
                .background(self.boxBackgroundColor)
                .cornerRadius(16)
                
                VStack {
                    self.DetailRow(label: "From", value: self.viewModel.transactionDetail?.from ?? "", action: {
                        self.viewModel.copyToClipboard(self.viewModel.transactionDetail?.from ?? "")
                    })
                    
                    self.DetailRow(label: "To", value: self.viewModel.transactionDetail?.to ?? "", action: {
                        self.viewModel.copyToClipboard(self.viewModel.transactionDetail?.to ?? "")
                    })
                }
                .padding(.vertical, 20)
                .background(self.boxBackgroundColor)
                .cornerRadius(8)
                
                VStack {
                    self.DetailRow(label: "Token", value: self.viewModel.transactionDetail?.amount ?? "0.00")
                    if let fee = viewModel.transactionDetail?.fee {
                        self.DetailRow(label: "Fee", value: fee.getFee())
                    }
                }
                .padding(.vertical, 20)
                .background(self.boxBackgroundColor)
                .cornerRadius(8)
                
                if let status = self.viewModel.transactionDetail?.status {
                    switch status {
                    case .statusUnspecified, .statusCreated:
                        Button(action: {
                            self.viewModel.createSignTransaction()
                        }) {
                            Text("Sign")
                                .fontWeight(.bold)
                        }.modifier(ButtonModifier())
                    case .statusPendingSignature:
//                        if self.viewModel.transactionDetail?.subStatus == .subStatusPendingSignatureCanBeApproved {
                        HStack {
                            Button(action: {
                                self.viewModel.reject(transactionID: self.viewModel.transactionDetail?.externalID ?? "")
                            }) {
                                Text("Reject")
                                    .fontWeight(.bold)
                            }.modifier(ButtonModifier())
                            Button(action: {
                                self.viewModel.approval(transactionID: self.viewModel.transactionDetail?.externalID ?? "")
                            }) {
                                Text("Approval")
                                    .fontWeight(.bold)
                            }.modifier(ButtonModifier())
                        }
                    default:
                        EmptyView()
                    }
                }
            }
            .padding()
            .navigationDestination(isPresented: self.$viewModel.txBroadcasted) {
                TokenView(token: self.viewModel.tokenBalance)
            }
            .alert(isPresented: self.$viewModel.showError, content: {
                Alert(title: Text("Error"), message: Text(self.viewModel.errorMessage ?? "Unknown error"), dismissButton: .default(Text("OK")))
            })
            
            if self.viewModel.isPresentingProgress {
                Color.black.opacity(0.5)
                    .edgesIgnoringSafeArea(.all)
                ProgressViewOverlay(progressText: self.$viewModel.progressText, showButton: self.$showProgressButton)
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
            }
        }
    }
    
    private func DetailRow(label: String, value: String, action: (() -> Void)? = nil) -> some View {
        HStack {
            Text(label)
                .foregroundColor(Color.secondary)
                .font(.system(size: 14))

            Spacer()

            Text(value)
                .foregroundColor(.blue)
                .font(.system(size: 14))

            if let action = action {
                Button(action: action) {
                    Image(systemName: "doc.on.doc")
                }
            }
        }
        .padding([.top, .bottom], 4)
        .padding([.leading, .trailing], 20)
    }
}

typealias UCWTransaction = UCWSDK.Transaction

extension TransactionDetailView {
    class ViewModel: ObservableObject {
        @Published var transactionDetail: TransactionDetail?
        @Published var txBroadcasted: Bool = false
        @Published var isPresentingProgress: Bool = false
        @Published var progressText: String = "TSS Signing ..."
        @Published var errorMessage: String?
        @Published var showError: Bool = false
        
        private var cancellables = Set<AnyCancellable>()
        private var transactionUsecase = TransactionUsecase()
        private var nodeManager = NodeManager.shared
        private var pollingManager = PollingManager()

        init(transactionDetail: TransactionDetail? = nil) {
            self.transactionDetail = transactionDetail
        }
        
        func copyToClipboard(_ text: String) {
            UIPasteboard.general.string = text
        }
        
        var tokenBalance: TokenBalance {
            return TokenBalance(walletID: self.transactionDetail?.walletID ?? "", token: self.transactionDetail?.token ?? Token(), balance: Balance())
        }
        
        public func approval(transactionID: String) {
            self.isPresentingProgress = true

            do {
                try self.nodeManager.approveTransactions(transactionIDs: transactionID)
                print("transaction \(transactionID) approved")
                self.pollTransactionDetail(transactionID: self.transactionDetail?.id ?? "", condition: {
                    $0.status.rawValue < TransactionStatus.statusBroadcasting.rawValue
                })
                .receive(on: DispatchQueue.main)
                .sink { _ in
                    self.showError = false
                    self.txBroadcasted = false
                    self.isPresentingProgress = false
                } receiveValue: { transactionDetail in
                    if transactionDetail.status.rawValue >= TransactionStatus.statusBroadcasting.rawValue {
                        self.isPresentingProgress = false
                        self.transactionDetail = transactionDetail
                        
                        switch transactionDetail.status {
                        case .statusConfirming, .statusCompleted:
                            self.txBroadcasted = true
                        case .statusFailed:
                            self.txBroadcasted = false
                        default:
                            self.txBroadcasted = false
                        }
                    }
                }
                .store(in: &self.cancellables)
            } catch {
                self.errorMessage = error.localizedDescription
                self.showError = true
            }
        }
        
        public func reject(transactionID: String) {
            do {
                try self.nodeManager.rejectTransactions(transactionIDs: transactionID, reason: "")
                self.transactionUsecase.rejectTransaction(transactionID: self.transactionDetail?.id ?? "")
                    .receive(on: DispatchQueue.main)
                    .sink { completion in
                        self.showError = false
                        switch completion {
                        case .finished:
                            break
                        case .failure(let error):
                            self.errorMessage = error.localizedDescription
                            self.showError = true
                        }
                    } receiveValue: { _ in
                        self.isPresentingProgress = false
                    }
                    .store(in: &self.cancellables)

            } catch {
                self.errorMessage = error.localizedDescription
                self.showError = true
            }
        }
    
        private func pollTransactionDetail(
            transactionID: String,
            condition: @escaping (TransactionDetail) -> Bool
        ) -> AnyPublisher<TransactionDetail, UsecaseError> {
            return self.pollingManager.poll(
                interval: 5,
                maxAttempts: -1,
                shouldContinue: { condition($0) },
                operation: {
                    self.transactionUsecase.getTransaction(transactionID: transactionID)
                }
            )
        }
        
        var formattedAmount: String {
            switch self.transactionDetail?.transactionType {
            case .typeDeposit:
                return "+\(self.transactionDetail?.amount ?? "")"
            case .typeWithdrawal:
                return "-\(self.transactionDetail?.amount ?? "")"
            default:
                return ""
            }
        }
        
        public func createSignTransaction() {
            if let detail = self.transactionDetail {
                self.isPresentingProgress = true
                self.transactionUsecase.createTransaction(req: detail)
                    .flatMap {
                       transactionID -> AnyPublisher<(String, TransactionDetail), UsecaseError> in
                       let pollTxPublisher =  self.pollTransactionDetail(transactionID: transactionID, condition: {
                            $0.status != TransactionStatus.statusPendingSignature
                        })
                        return Publishers.Zip(Just(transactionID).setFailureType(to: UsecaseError.self), pollTxPublisher)
                            .eraseToAnyPublisher()
                    }
                    .flatMap {
                        transactionID, transactionDetail -> AnyPublisher<(String, UCWTransaction?), UsecaseError> in
                        if transactionDetail.status == TransactionStatus.statusFailed {
                            return Fail(error: UsecaseError.transactionFailed)
                                       .eraseToAnyPublisher()
                        }
                        return self.nodeManager.pollTransactionFromSDK(interval: 3, transactionID: transactionDetail.externalID, condition: {
                            return $0 == nil
                        }).compactMap { sdkTransaction -> (String, UCWTransaction)? in
                            guard let sdkTransaction = sdkTransaction else { return nil }
                            return (transactionID, sdkTransaction)
                        }
                        .eraseToAnyPublisher()
                    }
                    .flatMap { transactionID, sdkTransaction -> AnyPublisher<TransactionDetail, UsecaseError> in
                        print("\(transactionID), \(String(describing: sdkTransaction))")
                        do {
                            try self.nodeManager.approveTransactions(transactionIDs: sdkTransaction?.transactionID ?? "")
                            return self.pollTransactionDetail(transactionID: transactionID, condition: {
                                $0.status.rawValue < TransactionStatus.statusBroadcasting.rawValue
                            })
                        } catch let error as SDKError {
                            return Fail(error: UsecaseError.from(sdkError: error)).eraseToAnyPublisher()
                        } catch {
                            return Fail(error: UsecaseError.otherError(error)).eraseToAnyPublisher()
                        }
                    }
                    .receive(on: DispatchQueue.main)
                    .sink { completion in
                        self.isPresentingProgress = false
                        self.showError = false
                        
                        switch completion {
                        case .finished:
                            break
                        case .failure(let error):
                            let usecaseError = UsecaseError.mapError(error)
                            switch usecaseError {
                            case .ignored:
                                print("createSignTransaction error ignore \(error)")
                            default:
                                self.txBroadcasted = false
                                self.errorMessage = error.localizedDescription
                                self.showError = true
                            }
                        }
                    } receiveValue: { transactionDetail in
                        if transactionDetail.status.rawValue >= TransactionStatus.statusBroadcasting.rawValue {
                            self.isPresentingProgress = false
                            self.transactionDetail = transactionDetail
                            
                            switch transactionDetail.status {
                            case .statusConfirming, .statusCompleted:
                                self.txBroadcasted = true
                            case .statusFailed:
                                self.txBroadcasted = false
                            default:
                                self.txBroadcasted = false
                            }
                        }
                    }
                    .store(in: &self.cancellables)
            }
        }
    }
}

// #Preview {
//    TransactionDetailView()
// }
