//
//  SettingsView.swift
//  ucw-ios-demo
//
//  Created by Yang.Bai on 2024/1/29.
//

import SwiftUI

struct SettingsView: View {
    
    @StateObject var viewModel = ViewModel()
    
    var body: some View {
        NavigationView {
            
            VStack {
                HStack {
                    Image("profilePicture")
                        .resizable()
                        .aspectRatio(contentMode: .fill)
                        .frame(width: 60, height: 60)
                        .clipShape(Circle())
                    Text(viewModel.userLocalStorage.userInfo?.user.email ?? "")
                        .font(.system(size: 18))
                        .fontWeight(.semibold)
                    Spacer()
                }
                .padding()
                List {
                    NavigationLink(destination: TssNodeID()) {
                        Text("TSS Node ID")
                    }
                    NavigationLink(destination: BackUpView()) {
                        Text("Backup Mpc Key (Export Key)")
                    }
                }
                .navigationTitle("Settings")
            }
        }
    }
}

extension SettingsView {
    class ViewModel: ObservableObject {
        var userLocalStorage = UsersLocalStorage.shared
    }
}

#Preview {
    SettingsView()
}
