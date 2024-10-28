//
//  TssNodeID.swift
//  UcwDemo
//
//  Created by Yang.Bai on 2024/8/26.
//

import SwiftUI
import CoreImage.CIFilterBuiltins

struct TssNodeID: View {
    
    var nodeId: String = ""
    let screenBackgroundColor = Color(red: 247/255, green: 247/255, blue: 249/255)
    @State private var showingAlert = false

    
    init() {
        nodeId = NodeManager.shared.getNodeId()
    }
    
    private func copyToClipboard() {
          UIPasteboard.general.string = nodeId
          showingAlert = true
    }
    
    var body: some View {
        NavigationView{
            ZStack {
                screenBackgroundColor.edgesIgnoringSafeArea(.all)
                VStack {
                    HStack {
                        Text("The TSS node ID serves as the unique identifier for the key holder during the generation of MPC key-shares")
                    }.padding()
                    
                    HStack {
                        Image(uiImage: generateQRCode(from: nodeId))
                            .interpolation(.none)
                            .resizable()
                            .scaledToFit()
                            .frame(width: 240, height: 240)
                    }
                    
                    VStack {
                        
                              HStack {
                                  Spacer()
                                  Text(nodeId)
                                      .padding(20)
                                      .background(screenBackgroundColor)
                                      .cornerRadius(8)
                                      .foregroundColor(.black)
                                      .padding(.trailing, 10)
                                      .padding(.horizontal, 20)

                                      .overlay(
                                  Button(action: copyToClipboard) {
                                      Image(systemName: "doc.on.doc")
                                  }
                                  .alert(isPresented: $showingAlert) {
                                      Alert(title: Text("Copied"), message: Text("\(nodeId) has been copied to clipboard."), dismissButton: .default(Text("OK")))
                                  }
                                .padding(.trailing, 5),
                                   alignment: .trailing
                                  )
                                  Spacer()

                              }.padding()
                          }
                          .background(Color.white)
                          .cornerRadius(12)
                          .padding()
                }.navigationTitle("TSS Node ID")
                    .padding(.horizontal)
            }
        }
    }
}


#Preview {
    TssNodeID()
}
