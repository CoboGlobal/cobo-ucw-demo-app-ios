//
//  FeeView.swift
//  UcwDemo
//
//  Created by Yang.Bai on 2024/8/25.
//

import Combine
import SwiftUI

enum FeeOption: String, CaseIterable, Identifiable {
    case fast = "Fast"
    case recommend = "Recommend"
    case slow = "Slow"
  
    var id: String { self.rawValue }
    
    var title: String {
        switch self {
        case .fast:
            return "Fast"
        case .recommend:
            return "Recommend"
        case .slow:
            return "Slow"
        }
    }
}

struct FeeView: View {
    @ObservedObject var viewModel: ViewModel
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        VStack {
            self.minierFeeInfo()
            Picker("", selection: self.$viewModel.currentState) {
                Text("Set Priority").tag(FeeSelectState.SetPriority)
                Text("Customize").tag(FeeSelectState.Customize)
            }
            .pickerStyle(.segmented)
            .padding()
            
            if self.viewModel.currentState == .SetPriority {
                self.setPriority()
            } else if self.viewModel.currentState == .Customize {
                self.customize()
            }
        }
        .onAppear {
            self.viewModel.startPolling()
        }.onDisappear {
            self.viewModel.cancel()
        }
        .alert(isPresented: self.$viewModel.showError, content: {
            Alert(title: Text("Error"), message: Text(self.viewModel.errorMessage ?? "Unknown error"), dismissButton: .default(Text("OK")))
        })
    }
    
    private func minierFeeInfo() -> some View {
        var body: some View {
            VStack(alignment: .leading) {
                HStack {
                    Text("Miner Fee")
                        .font(.system(size: 15))

                    Spacer()
                    Text(viewModel.fee.feeAmount.description)
                        .font(.system(size: 15))
                }
                .padding([.top], 14)
                .padding([.leading, .trailing], 20)
                HStack {
                    Spacer()
                    Text(viewModel.fee.feeAmount.description)
                        .font(.system(size: 14))
                        .foregroundColor(Color.secondary)
                }
                .padding([.top, .bottom], 14)
                .padding([.leading, .trailing], 20)
            }
            .frame(maxWidth: .infinity)
            .background(Color.white)
            .cornerRadius(8)
        }
        return body
    }
    
    private func setPriority() -> some View {
        var body: some View {
            ForEach(FeeOption.allCases, id: \.self) { option in
                HStack {
                    ZStack {
                        Circle()
                            .strokeBorder(Color.gray, lineWidth: 2)
                            .frame(width: 24, height: 24)
                            .foregroundColor(.white)
                        if viewModel.selectedFeeOption == option {
                            Circle()
                                .fill(Color.blue)
                                .frame(width: 16, height: 16)
                        }
                    }
                    VStack(alignment: .leading, content: {
                        Text(option.title)
                            .fontWeight(.medium)
                        Text(viewModel.getFee(for: option))
                            .font(.subheadline)
                    })
                    Spacer()
                }
                .padding()
                .background(Color.white)
                .cornerRadius(8)
                .onTapGesture {
                    viewModel.selectedFeeOption = option
                    viewModel.selectFee()
                    dismiss()
                }
            }
        }
        return body
    }
            
    private func customize() -> some View {
        var body: some View {
            VStack {
                HStack {
                    VStack(alignment: .leading, spacing: 10) {
                        Text("Gas Fee Rate")
                            .fontWeight(.medium)
                            .foregroundColor(Color.secondary)
                            .font(.system(size: 15))

                        HStack {
                            TextField("0.00", text: $viewModel.customizeFee)
                                .textFieldStyle(RoundedBorderTextFieldStyle())
                                .keyboardType(.decimalPad)
                                .background(Color(red: 247/255, green: 247/255, blue: 249/255))
                            Spacer()
                        }
                    }
                    Spacer()
                }
                .padding()
                
                Button(action: {
                    dismiss()
                }) {
                    Text("Confirm")
                }
                .modifier(ButtonModifier())
            }.background(Color.white)
                .cornerRadius(8)
        }
        return body
    }
}

enum FeeSelectState {
    case SetPriority
    case Customize
}

extension FeeView {
    class ViewModel: ObservableObject {
        @Published var currentState: FeeSelectState = .SetPriority
        @Published var selectedFeeOption: FeeOption?
        @Binding var fee: Fee
        @Published var customizeFee: String = ""
        @Published var estimateFeeRes: EstimateFee = .init()
        @Published var errorMessage: String?
        @Published var showError: Bool = false
        
        private var pollingManager =  PollingManager()
        private let usecase = TransactionUsecase()
        private var timer: Timer?
        private var cancellables = Set<AnyCancellable>()
        private var toTransfer: TransactionDetail
        
        init(fee: Binding<Fee>, toTransfer: TransactionDetail) {
            _fee = fee
            self.toTransfer = toTransfer
        }
        
        public func cancel() {
            print("MyViewModel is being deinitialized")
            pollingManager.stopPolling()
        }
        
        func setCustomizeFee() {
            if !self.estimateFeeRes.Fast.feePerByte.isZero {
                self.fee = Fee(level: .customize, feePerByte: Decimal(string: self.customizeFee) ?? Decimal.zero, tokenID: self.toTransfer.token?.tokenID ?? "")
            } else {
                self.fee = Fee(level: .customize, gasPrice: Decimal(string: self.customizeFee) ?? Decimal.zero, gasLimit: 21000, tokenID: self.toTransfer.token?.tokenID ?? "")
            }
        }
        
        func startPolling() {
            self.pollFeeRequest(condition: { _ in
                    true
                })
                .receive(on: DispatchQueue.main)
                .sink { completion in
                    switch completion {
                    case .finished:
                        print("estimateTransactionFee Completion")
                    case .failure(let error):
                        self.errorMessage = error.localizedDescription
                        self.showError = true
                    }
                } receiveValue: { estimateFee in
                    self.estimateFeeRes = estimateFee
                }
                .store(in: &self.cancellables)
        }
        
        private func pollFeeRequest(
            condition: @escaping (EstimateFee) -> Bool
        ) -> AnyPublisher<EstimateFee, UsecaseError> {
            return pollingManager.poll(
                   interval: 30,
                   maxAttempts: -1,
                   shouldContinue: { condition($0) },
                   operation: {
                       self.usecase.estimateTransactionFee(req: self.toTransfer)
                   }
               )
        }
        
        public func getFee(for option: FeeOption) -> String {
            switch option {
            case .fast:
                return self.estimateFeeRes.Fast.getFee()
            case .recommend:
                return self.estimateFeeRes.Recommend.getFee()
            case .slow:
                return self.estimateFeeRes.Slow.getFee()
            }
        }
        
        public func selectFee() {
            switch self.selectedFeeOption {
            case .fast:
                self.fee = self.estimateFeeRes.Fast
            case .recommend:
                self.fee = self.estimateFeeRes.Recommend
            case .slow:
                self.fee = self.estimateFeeRes.Slow
            default:
                self.fee = Fee(level: .customize, feePerByte: Decimal.zero, feeAmount: Decimal.zero, gasPrice: Decimal.zero, gasLimit: Decimal.zero, tokenID: self.toTransfer.token?.tokenID ?? "", maxFee: Decimal.zero, maxPriorityFee: Decimal.zero)
            }
        }
    }
}

// #Preview {
//    FeeView()
// }
