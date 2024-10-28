//
//  PinCode.swift
//  UcwDemo
//
//  Created by Yang.Bai on 2024/8/23.
//

import SwiftUI

enum FocusField: Hashable {
    case field
}

struct OTPTextField: View {
    @Binding var verificationCode: String
    @State var isAllNumbersFilled: Bool = false
    
    var pinLength = 6
    var keyboardType: UIKeyboardType = .numberPad
    var onComplete: () -> ()
    
    var body: some View {
        ZStack {
            TextField("", text: $verificationCode)
                .frame(width: 0, height: 0, alignment: .center)
                .font(Font.system(size: 0))
                .accentColor(.white)
                .foregroundColor(.white)
                .multilineTextAlignment(.center)
                .keyboardType(keyboardType)
                .padding()
        }
    }
}

struct OTPTextView: View {
    @State private var verificationCode = ""
    @FocusState private var focusField: FocusField?
    
    var pinLength = 6
    var keyboardType: UIKeyboardType = .numberPad
    var onComplete: (String) -> ()
    
    var body: some View {
        ZStack(alignment: .center) {
            OTPTextField(verificationCode: $verificationCode, pinLength: pinLength, keyboardType: keyboardType) {
                onComplete(verificationCode)
            }
            HStack {
                ForEach(0..<pinLength, id: \.self) { i in
                    ZStack {
                        Text(getPin(at: i))
                            .font(.custom("AmericanTypewriter", size: 35))
                            .fontWeight(.semibold)
                            .foregroundColor(.white)
                        
                        Rectangle()
                            .frame(height: 3)
                            .foregroundColor(.white)
                            .padding(.trailing, 5)
                            .padding(.leading, 5)
                            .opacity(verificationCode.count <= i ? 1 : 0)
                    }
                }
            }
            
        }
        .onAppear{
            UITextField.appearance().clearButtonMode = .never
            UITextField.appearance().tintColor = UIColor.clear
        }
    }
    
    func getPin(at index: Int) -> String {
        guard self.verificationCode.count > index else {
            return ""
        }
        
        return verificationCode
    }
}

#Preview {
    OTPTextView { value in
                    print(value)
                }
}
