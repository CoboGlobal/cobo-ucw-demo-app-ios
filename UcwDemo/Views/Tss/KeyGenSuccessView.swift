//
//  KeyGenSuccessView.swift
//  ucw-ios-demo
//
//  Created by Yang.Bai on 2024/1/29.
//

import SwiftUI

struct KeyGenSuccessView: View {
    @State private var backUp = false
    @State private var doThisLater = false

    var body: some View {
        VStack(spacing: 20) {
            Image(systemName: "checkmark.circle")
                          .resizable()
                          .scaledToFit()
                          .frame(width: 50, height: 50)
                          .foregroundColor(.green)

            
                     Text("MPC key generated successfully \nPlease back up your MPC key")
                         .fontWeight(.semibold)
                         .multilineTextAlignment(.center)
                         .font(.system(size: 16))
                         .padding(.horizontal)

                     
                     Text("    If your current device is lost or the App is uninstalled, you will need to use the backup file to restore your MPC key")
                         .multilineTextAlignment(.center)
                         .font(.system(size: 14))
                         .padding(.horizontal, 20)
            Spacer()
            Button(action: {
                backUp = true
            }) {
                Text("Backup Key")
                    .frame(minWidth: 0, maxWidth: .infinity)
                    .padding()
                    .background(Color.blue)
                    .foregroundColor(Color.white)
                    .cornerRadius(10)
            }
            .padding(.horizontal)

            NavigationLink(destination: HomeTabView()) {
                Text("I'll do this later")
                    .foregroundColor(.blue)
            }
            .padding(.horizontal)

            Spacer()
        }
        .navigationDestination(isPresented: $backUp) {
            BackUpView()
        }
        .padding(.top, 20)
        
        .navigationBarBackButtonHidden(true)
        .interactiveDismissDisabled(true)
    }
}

#Preview {
    NavigationView{
        KeyGenSuccessView()
    }
}
