//
//  KeyGroup.swift
//  ucw-ios-demo
//
//  Created by Yang.Bai on 2024/2/27.
//

import Foundation
import SwiftUI

struct InfoBoxView: View {
    var GroupType: String = "Signing Key group"
    var body: some View {
        VStack(alignment: .leading)  {
            HStack {
                Text("Key Group").foregroundColor(Color.secondary)
                    .font(.system(size: 14))

                Spacer()
                Text(GroupType)
                    .font(.system(size: 14))
            }
            .padding([.top], 14)
            .padding([.leading, .trailing], 20)
            HStack {
                Text("Quorum").foregroundColor(Color.secondary)
                    .font(.system(size: 14))

                Spacer()
                Text("2/2")
                    .font(.system(size: 14))
            }
            .padding([.top, .bottom], 14)
            .padding([.leading, .trailing], 20)
        }
        .frame(maxWidth: .infinity)
        .background(Color.white)
        .cornerRadius(8)
    }
}

struct KeyGroupBoxView: View {
    let groupTitle: String
    @Binding var holderName: String
    @Binding var nodeId: String
  

    var body: some View {
        VStack(alignment: .leading) {
            HStack {
                Text(groupTitle)
                    .font(.system(size: 14))
                    .bold()
                    .padding([.top, .bottom], 5)
            }
            HStack {
                Text("Holder")
                    .font(.system(size: 14))
                    .foregroundColor(Color.secondary)
            }
            HStack {
                TextField("Holder name", text: $holderName)
                    .font(.system(size: 15))

                    .padding(12)
                Spacer()
            }.padding(.horizontal)
                .background(Color(red: 19/255, green: 25/255, blue: 46/255).opacity(0.03))
                .cornerRadius(12)



            HStack {
                Text("Tss Node ID")
                    .padding(.top, 10)
                    .font(.system(size: 14))
                    .foregroundColor(Color.secondary)
            }
                  HStack {
                      TextField("Node ID", text: $nodeId)
                        .font(.system(size: 15))
                        .padding(10)
                        .padding(.trailing, 10)
                        Spacer()

                          .overlay(
                              Button(action: {
                                  // Copy the nodeID to the clipboard
                                  UIPasteboard.general.string = nodeId
                              }) {
                                  Image(systemName: "doc.on.clipboard") // This is the copy icon
                                      .foregroundColor(.blue)
                              }
                              .padding(.trailing, 5),
                              alignment: .trailing
                          )
                  }
                  .padding(.horizontal)
                .background(Color(red: 19/255, green: 25/255, blue: 46/255).opacity(0.03))
                .cornerRadius(12)
              
        }
        .padding()
        .background(Color.white)
        .cornerRadius(8)
        .edgesIgnoringSafeArea(.all)
    }
}
