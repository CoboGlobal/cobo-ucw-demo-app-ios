//
//  BackUpView.swift
//  ucw-ios-demo
//
//  Created by Yang.Bai on 2024/1/29.
//

import SwiftUI

struct BackUpView: View {
    @StateObject var viewModel = ViewModel()
    @State private var showingAlert = false

    func copyToClipboard(text: String) {
        UIPasteboard.general.string = text
        showingAlert = true
    }
    
    var body: some View {
        ZStack {
            Color.gray.opacity(0.1).edgesIgnoringSafeArea(.all)

            VStack {
                HStack {
                    Text("Set Passphrase")
                    Spacer()
                }
              
                TextFieldBox(placeholder: "Please enter passphrase", title: "Passphrase", text: $viewModel.passphrase)
                TextFieldBox(placeholder: "Please re-enter passphrase", title: "Confirm Passphrase", text: $viewModel.confirmPassphrase)
                
                Spacer()
                
                Button(action: {
                    viewModel.verifyAndUpload()
                }) {
                    Text("Confirm")
                }.alert(isPresented: $viewModel.showAlert) {
                    Alert(
                        title: Text(viewModel.alertTitle),
                        message: Text(viewModel.alertMessage),
                        dismissButton: .default(Text("OK"))
                    )
                }.modifier(ButtonModifier())
            }
            .padding()
            .navigationTitle("Back Up MPC Key")
            .navigationDestination(isPresented: $viewModel.done) {
                HomeTabView()
            }
            
            if viewModel.uploadSuccess {
                HStack {
                    Button(action: {
                        copyToClipboard(text:viewModel.secrets)
                    }) {
                
                        Text("Copy your secrets")
                    }
                    .modifier(ButtonModifier())
                }           
                .padding()
                .alert(isPresented: $showingAlert) {
                    Alert(title: Text("Copied!"), message: Text("The secrets has been copied to your clipboard."), dismissButton: .default(Text("OK")))
                }

            }
            
            if viewModel.isUploading {
                Color.black.opacity(0.5)
                    .edgesIgnoringSafeArea(.all)
                ProgressViewOverlay(progressText: $viewModel.progressText, showButton: $viewModel.showButton, buttonLabel: "ok", buttonAction: viewModel.goToWalletView)
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
            }
        }
    }
}

extension BackUpView {
    class ViewModel: ObservableObject {
        @Published var passphrase: String = ""
        @Published var confirmPassphrase: String = ""
        @Published var isUploading: Bool = false
        @Published var uploadSuccess: Bool = false
        @Published var showAlert: Bool = false
        @Published var alertMessage: String = "Invalid passphrase"
        @Published var alertTitle: String = "Invalid passphrase"
        @Published var progressText: String = "Backing up \nPlease don't close app"
        @Published var showButton: Bool = false
        @Published var done: Bool = false
        @Published var secrets: String = ""
        
        var nodeManager = NodeManager.shared
        func verifyAndUpload() {
            if passphrase == confirmPassphrase && !passphrase.isEmpty {
                self.isUploading = true
                self.simulateUpload(passphrase: passphrase)
                self.isUploading = false
            } else {
                self.alertMessage = "two inputs is not match"
                self.alertTitle = "Invalid passphrase,"
                self.showAlert = true
            }
        }
        
        private func simulateUpload(passphrase: String) {
            do {
                let secrets = try nodeManager.export(backupPassphrase: passphrase)
                self.uploadSuccess = true
                self.showButton = true
                self.progressText = "Backup Success"
                self.secrets = secrets
            } catch {
                print("backupKeys \(error)")
                self.alertMessage = "\(error)"
                self.alertTitle = "Export failed,"
                self.showAlert = true
            }
        }
           
        func goToWalletView() {
            self.showButton = false
            self.progressText = "Backing up \nPlease don't close app"
            self.isUploading = false
            self.done = true
        }
    }
}

struct TextFieldBox: View {
    var placeholder: String
    var title: String
    @Binding var text: String
    
    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text(title)
                .font(.system(size: 14))
                .fontWeight(.bold)
            SecureField(placeholder, text: $text)
                .padding()
                .background(Color.white)
                .cornerRadius(12)
                .shadow(radius: 1)
        }
        .padding()
        .background(Color.white)
        .cornerRadius(10)
    }
}

struct ConfirmButton: View {
    var action: () -> Void
    
    var body: some View {
        Button(action: action) {
            Text("Confirm")
                .foregroundColor(.white)
                .padding()
                .frame(minWidth: 0, maxWidth: .infinity)
                .background(Color.blue)
                .cornerRadius(10)
        }
        .padding([.bottom, .horizontal])
    }
}

#Preview {
    NavigationView {
        BackUpView()
    }
}
