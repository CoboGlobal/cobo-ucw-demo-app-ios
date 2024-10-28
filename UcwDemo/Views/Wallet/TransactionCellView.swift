//
//  TxListView.swift
//  ucw-ios-demo
//
//  Created by Yang.Bai on 2024/1/29.
//

import SwiftUI

struct TransactionCellView: View {
    var transaction: TransactionDetail
    
    var body: some View {
        HStack {
            Image(systemName: "arrow.right.arrow.left")
                .frame(width: 30, height: 30)
                .background(Color.blue)
                .foregroundColor(.white)
                .cornerRadius(15)

            VStack(alignment: .leading) {
                Text(transaction.id)
                    .font(.headline)
                    .foregroundColor(.black)
                Text(transaction.formattedDate)
                    .font(.caption)
                    .foregroundColor(.gray)
            }

            if transaction.status == .statusPendingSignature {
                              Spacer()
                              Text("Sign")
                                  .font(.caption)
                                  .padding(5)
                                  .background(Color.blue)
                                  .foregroundColor(.white)
                                  .cornerRadius(5)
                          }

            Spacer()
            
            Text(transaction.transactionType == .typeDeposit ? "+\(transaction.amount)" : "-\(transaction.amount)")
                .foregroundColor(transaction.transactionType == .typeWithdrawal ? .green : .red)
        }        .padding(.vertical, 5)

    }
}

//#Preview {
////    TransactionCellView()
//}
