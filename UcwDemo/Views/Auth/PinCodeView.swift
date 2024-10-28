//
//  PinCodeView.swift
//  UcwDemo
//
//  Created by Yang.Bai on 2024/8/22.
//

import SwiftUI
import Combine

struct PinCodeView: View {
    @StateObject var viewModel: ViewModel = ViewModel()
        
    var body: some View {
        NavigationView {
            ZStack {
                VStack {
                    if !viewModel.showingConfirmation {
                        Text("Create PIN Code")
                        SecureField("Enter PIN", text: $viewModel.pinCode)
                            .keyboardType(.numberPad)
                    } else {
                        Text("Re-type PIN Code")
                        SecureField("Enter PIN", text: $viewModel.confirmedPinCode)
                            .keyboardType(.numberPad)
                    }
                    
                    Button(viewModel.showingConfirmation ? "Confirm" : "Next") {
                         viewModel.handleButtonPress(userID: viewModel.localStorge.userInfo?.user.userID ?? "", checkPinMatch: { isMatch in
                            if isMatch {
                                print("checkPinMatch", true)
                            }
                        })
                    }
                    .disabled((viewModel.showingConfirmation ? viewModel.confirmedPinCode.count : viewModel.pinCode.count) < 6)
                    .padding()
                    .alert(isPresented: $viewModel.showAlert) {
                        Alert(
                            title: Text(viewModel.alertTitle),
                            message: Text(viewModel.alertMessage),
                            dismissButton: .default(Text("OK"))
                        )
                    }
                }
                .navigationBarTitleDisplayMode(.inline)
                .navigationDestination(isPresented: $viewModel.pinCodeSetted) {
                    if viewModel.localStorge.userInfo?.KeyGenSuccess() == true {
                        ReSetupIndexVIew()
                    } else {
                        KeyGenView()
                    }
                }
                if self.viewModel.progressing {
                    LoadingView(progressText: "SDK initializing ...")
                }
            }
        }
        .navigationBarBackButtonHidden(true)
        .interactiveDismissDisabled(true)
    }
}

struct PinCodeSquare: View {
    var isFilled: Bool
    
    var body: some View {
        Rectangle()
            .frame(width: 20, height: 20)
            .foregroundColor(isFilled ? .black : .clear)
            .border(Color.black)
    }
}

extension PinCodeView {
    static var id: String { "PinCodeView" }
}

extension PinCodeView {
    class ViewModel: ObservableObject {
        @Published var pinCode: String = ""
        @Published var confirmedPinCode: String = ""
        @Published var showingConfirmation = false
        @Published var pinCodeSetted = false
        @Published var progressing = false
        @Published var showAlert: Bool = false
        @Published var alertMessage: String = "BindFailed"
        @Published var alertTitle: String = "Invalid passphrase"
        
        private var cancellables = Set<AnyCancellable>()

        var nodeManager: NodeProtocol
        var keychainManager = KeychainManager.standard
        var localStorge = UsersLocalStorage.shared
        var userUsecase: UserUsecaseProtocol
        var navigateTo: DestinationIdentifier = .keygenView
        
        init () {
            self.nodeManager = NodeManager.shared
            self.userUsecase = UserUsecase()
        }
        
        var randomPassword = ""
        private func generateRandomPassword(length: Int) -> String {
            let characters = "abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789"
            let randomCharacters = (0 ..< length).compactMap { _ in characters.randomElement() }
            return String(randomCharacters)
        }
        
        func handleButtonPress(userID: String, checkPinMatch: (Bool) -> Void) {
            if showingConfirmation {
                if pinCode == confirmedPinCode {
                    self.progressing = true
                    _ = keychainManager.setPINCode(userID: userID , pin: pinCode)
                    self.randomPassword = generateRandomPassword(length: 22)
                    _ = keychainManager.setPassword(userID: userID, password: self.randomPassword)
                    checkPinMatch(true)
                    if localStorge.userInfo?.KeyGenSuccess() == true {
                        self.pinCodeSetted = true
                        self.progressing = false
                    } else {
                        self.nodeManager.initDB(database: userID, passphrase: self.randomPassword)
                            .flatMap { nodeID in self.userUsecase.bindNode(nodeID: nodeID)}
                            .receive(on: DispatchQueue.main)
                            .sink { completion in
                                switch completion {
                                case .finished:
                                    self.pinCodeSetted = true
                                    self.progressing = false
                                case .failure(let error):
                                    self.progressing = false
                                    self.showAlert = true
                                    self.alertMessage = error.localizedDescription
                                }
                            } receiveValue: { userNode in
                                print("bindNode node success\(userNode)")
                            }
                            .store(in: &self.cancellables)
                    }
                  
                } else {
                    checkPinMatch(false)
                }
            } else {
                showingConfirmation = true
            }
        }
    }
}

//#Preview {
//    PinCodeView()
//}
