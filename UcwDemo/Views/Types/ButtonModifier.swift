//
//  ButtonModifier.swift
//  UcwDemo
//
//  Created by Yang.Bai on 2024/8/22.
//

import SwiftUI

struct ButtonModifier: ViewModifier {
    func body(content: Content) -> some View {
        content
            .foregroundColor(.white)
            .padding(.vertical)
            .padding(.horizontal, 16)
            .frame(maxWidth: .infinity)
            .background(Color(red: 31/255, green: 50/255, blue: 214/255, opacity: 1))
    }
}

struct ResetUpPanel: ViewModifier {
    func body(content: Content) -> some View {
        content
            .padding(.vertical, 50)
            .padding(.leading, 20)
            .background(Color.white)
            .foregroundColor(.black)
            .cornerRadius(8)
    }
}
