//
//  InitializeView.swift
//  ucw-ios-demo
//
//  Created by Yang.Bai on 2024/1/29.
//

import SwiftUI

struct ReSetupIndexVIew: View {
    let screenBackgroundColor = Color(red: 247/255, green: 247/255, blue: 249/255)
    @StateObject private var viewModel = ViewModel()

    var body: some View {
        ZStack {
            screenBackgroundColor.edgesIgnoringSafeArea(.all)
            VStack {
                NavigationLink(destination: GenerateRecoveryKeyStartView(), isActive: $viewModel.toReshareBackup) {
                    HStack {
                        Text("Generate Recovery Key")
                        Spacer()
                    }
                    .modifier(ResetUpPanel())
                }
                NavigationLink(destination: RestoreView()) {
                    HStack {
                        Text("Restore From Backup File")
                        Spacer()
                    }
                    .modifier(ResetUpPanel())
                }
                NavigationLink(destination: RecoveryView(), isActive: $viewModel.toRecovery) {
                    HStack {
                        Text("Perform Recovery From Recovery Key Group")
                        Spacer()
                    }
                    .modifier(ResetUpPanel())
                }
                Spacer()
            }
            .padding()
            .navigationTitle("Generate MPC Key")
            .navigationBarTitleDisplayMode(.inline)
        }
    }
}

extension ReSetupIndexVIew {
    static var id: String { "ReSetupIndexVIew" }
}

enum ReSetupAction: Int {
    case GenerateBackUpGroup = 1
    case Restore = 2
    case Recovery = 3
}

extension ReSetupIndexVIew {
    class ViewModel: ObservableObject {
        @Published var toRecovery: Bool = false
        @Published var toReshareBackup: Bool = false
    }
}

#Preview {
    NavigationView {
        ReSetupIndexVIew()
    }
}
