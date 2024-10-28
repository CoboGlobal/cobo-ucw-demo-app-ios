//
//  SwiftUIView.swift
//  UcwDemo
//
//  Created by Yang.Bai on 2024/8/22.
//

import SwiftUI

struct LaunchView: View {
    var body: some View {
        NavigationStack {
            Spacer()
                .frame(height: 180)
            VStack {
                HStack {
                    Text("MPC Wallet")
                        .fontWeight(.heavy)
                        .frame(height: 22, alignment: .center)
                        .font(.largeTitle)
                }
                Spacer().frame(height: 20)
                Text("Cobo UCW Demo App").font(.subheadline)
                Spacer()
                HStack {
                    NavigationLink(destination: AuthProviderView()) {
                        Text("Sign In")
                            .modifier(ButtonModifier())
                    }

                    NavigationLink(destination: AuthProviderView()){
                        Text("Sign Up")
                            .modifier(ButtonModifier())
                    }
                }
            }
            .padding(30)
        }.withBackgroundColor()
    }
}

#Preview {
    LaunchView()
}
