//
//  BaseViewModel.swift
//  UcwDemo
//
//  Created by Yang.Bai on 2024/10/21.
//

import Foundation
import SwiftUI

struct ErrorView: View {
    let message: String
    @Binding var isPresented: Bool
    
    var body: some View {
        VStack {
            Text(message)
                .foregroundColor(.white)
                .padding()
                .background(Color.red)
                .cornerRadius(10)
            
            Button("Dismiss") {
                isPresented = false
            }
            .foregroundColor(.white)
            .padding()
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(Color.black.opacity(0.4))
        .edgesIgnoringSafeArea(.all)
        .onTapGesture {
            isPresented = false
        }
    }
}
