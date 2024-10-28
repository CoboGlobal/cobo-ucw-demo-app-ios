//
//  ReceiveView.swift
//  ucw-ios-demo
//
//  Created by Yang.Bai on 2024/1/29.
//

import CoreImage.CIFilterBuiltins
import SwiftUI

struct ReceiveView: View {
    let tokenAddress: TokenAddress?
    @State private var showingAlert = false

    func copyToClipboard(address: String) {
        UIPasteboard.general.string = address
        showingAlert = true
    }
    var body: some View {
        VStack {
            Spacer().frame(height: 120)

            VStack {
                Text("Only receive \(tokenAddress?.tokenID ?? "")")
                    .font(.subheadline)
                    .padding(.vertical, 15)

                ZStack {
                    Image(uiImage: generateQRCode(from: tokenAddress?.firstAddress ?? ""))
                        .interpolation(.none)
                        .resizable()
                        .scaledToFit()
                        .frame(width: 240, height: 240)
                }
                Text(tokenAddress?.firstAddress ?? "")
                    .font(.subheadline)
                    .padding()
                    .foregroundColor(.black)

                HStack {
                    Button(action: {
                        self.copyToClipboard(address: tokenAddress?.firstAddress ?? "")
                    }) {
                        HStack {
                            Image(systemName: "doc.on.doc")
                            Text("Copy")
                        }
                        .foregroundColor(.black)
                        .padding()
                    }
                    .background(Color(red: 220/255, green: 221/255, blue: 224/255))
                    .alert(isPresented: $showingAlert) {
                        Alert(title: Text("Copied!"), message: Text("The address has been copied to your clipboard."), dismissButton: .default(Text("OK")))
                    }
                }
                .background(Color(red: 244/255, green: 245/255, blue: 248/255))
                .padding(.horizontal, 40)
            }
            .padding(.horizontal, 40)
            .padding()
            .background(Color.white)
            .cornerRadius(10)

            Spacer()
        }
        .navigationBarTitle("Receive", displayMode: .inline)
        .navigationBarBackButtonHidden(false)
        .navigationBarItems(trailing: Button(action: {}) {
            Image(systemName: "questionmark.circle")
                .foregroundColor(.white)
        })
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(Color(red: 255/255, green: 157/255, blue: 0/255))
        .edgesIgnoringSafeArea(.all)
    }
}

// #Preview {
//    ReceiveView(asset: Asset(icon: "", name: "String", chainName: "", amount: "String", dollarValue: "String", address: "wwwqeq", coin: "coin", walletId: ""))
// }
