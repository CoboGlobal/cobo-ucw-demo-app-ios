//
//  HomeTabView.swift
//  UcwDemo
//
//  Created by Yang.Bai on 2024/8/23.
//

import SwiftUI

import SwiftUI

struct HomeTabView: View {
    var body: some View {
        TabView {
            WalletView().tabItem {
                Label("Wallet", systemImage: "wallet.pass.fill")
            }
            ApprovalsView().tabItem {
                Label("Approvals", systemImage: "checkmark.seal.fill")
            }
            SettingsView().tabItem {
                Label("Settings", systemImage: "gearshape.fill")
            }
        }
    }
}


extension HomeTabView {
    static var id: String { "HomeTabView" }
}

#Preview {
    HomeTabView()
}
