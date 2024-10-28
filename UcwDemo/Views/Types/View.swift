//
//  View.swift
//  UcwDemo
//
//  Created by Yang.Bai on 2024/8/22.
//

import SwiftUI

struct BackgroundColorModifier: ViewModifier {
    let screenBackgroundColor = Color(red: 247/255, green: 247/255, blue: 249/255)

    func body(content: Content) -> some View {
        content
            .background(Color.yellow)
    }
}

extension View {
    func withBackgroundColor() -> some View {
        self.modifier(BackgroundColorModifier())
    }
}
