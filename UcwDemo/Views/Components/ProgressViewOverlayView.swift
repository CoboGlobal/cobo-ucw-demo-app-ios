//
//  ProgressViewOverlay.swift
//  ucw-ios-demo
//
//  Created by Yang.Bai on 2024/2/23.
//

import Foundation

import SwiftUI

struct ProgressViewOverlay: View {
    @Binding var progressText: String
    @Binding var showButton: Bool
    var buttonLabel: String?
    var buttonAction: (() -> Void)?

    var body: some View {
        VStack {
            if showButton {
                Image(systemName: "doc.fill")
                    .resizable()
                    .aspectRatio(contentMode: .fit)
                    .foregroundColor(.blue)
                    .frame(width: 50, height: 50)
                    .padding()
            } else {
                ProgressView()
                    .progressViewStyle(CircularProgressViewStyle(tint: Color.blue))
                    .scaleEffect(1.5)
            }
            Text(progressText)
                .padding()

            if let label = buttonLabel, let action = buttonAction, showButton {
                     Button(label, action: action)
                         .foregroundColor(.white)
                         .frame(maxWidth: .infinity)
                         .padding()
                         .background(Color.blue)
                         .cornerRadius(8)
                 }
        }
        .frame(width: UIScreen.main.bounds.width - 60,
               height: UIScreen.main.bounds.width - 100)
        .background(Color.white)
        .cornerRadius(20)
        .shadow(radius: 10)
        .padding()
    }
}


struct LoadingView: View {
    var progressText: String
    var body: some View {
        ZStack {
            Color.black.opacity(0.4)
                .edgesIgnoringSafeArea(.all)

            ProgressView(self.progressText)
                .progressViewStyle(CircularProgressViewStyle(tint: .white))
                .scaleEffect(1.5)
        }
    }
}
