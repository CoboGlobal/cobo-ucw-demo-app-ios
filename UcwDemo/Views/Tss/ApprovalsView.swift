//
//  ApprovalsView.swift
//  ucw-ios-demo
//
//  Created by Yang.Bai on 2024/2/27.
//

import SwiftUI
import Combine

struct ApprovalsView: View {
    @StateObject var viewModel = ViewModel()

    var body: some View {
        NavigationView {
            VStack {
                Picker("Filter", selection: self.$viewModel.selectedFilter) {
                    ForEach(self.viewModel.filters, id: \.self) {
                        Text($0)
                    }
                }
                .pickerStyle(SegmentedPickerStyle())
                .padding()
                List {
                    ForEach(self.viewModel.tssRequests, id: \.id) { tssRequest in
                        HStack {
                            VStack(alignment: .leading) {
                                Text(tssRequest.title)
                                    .fontWeight(.bold)
                                NavigationLink(destination: GenerateRecoveryKeyView(viewModel: .init(reshareRole: .resharefrom, tssRequestID: tssRequest.id, groupID: tssRequest.info?.source_group_id ?? "")))
                                {
                                    Text("View")
                                        .foregroundColor(.blue)
                                }
                            }
                        }
                        .padding()
                        .background(Color.white)
                        .cornerRadius(10)
                        .shadow(radius: 1)
                    }
                }
                .listStyle(PlainListStyle())
                .onAppear {
                        self.viewModel.fetchNodeTssRequest()
                }
            }
            .navigationBarTitle("Approvals", displayMode: .large)
        }
    }
}

extension ApprovalsView {
    class ViewModel: ObservableObject {
        @Published var tssRequests: [TssRequest] = []
        @Published var selectedFilter = "Pending"  {
            didSet {
                fetchNodeTssRequest()
            }
        }
        @Published var filters = ["Pending", "All"]
        var vaultUsecase = VaultUsecase()
        var nodeManager = NodeManager.shared
        var userLocalStorage = UsersLocalStorage.shared
        private var cancellables = Set<AnyCancellable>()

        public func fetchNodeTssRequest() {
            var requestStatus = TssRequestStatus.MpcProcessing.rawValue
             if self.selectedFilter == "All" {
                 requestStatus = 0
             }
            self.vaultUsecase.listTssRequests(vaultID: userLocalStorage.userInfo?.vault.vaultID ?? "", nodeID: nodeManager.getNodeId(), status: requestStatus)
                .receive(on: DispatchQueue.main)
                .sink { completion in
                    switch completion {
                    case .finished:
                        print("listTssRequests Completion")
                    case .failure(let error):
                        print("listTssRequests err \(error)")
                    }
                } receiveValue: { tssRequests in
                    self.tssRequests = tssRequests
                }
                .store(in: &self.cancellables)
        }
    }
}

#Preview {
    ApprovalsView()
}
