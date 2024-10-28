//
//  UserLocalStorge.swift
//  UcwDemo
//
//  Created by Yang.Bai on 2024/8/27.
//

import SwiftUI

class UsersLocalStorage: ObservableObject {
    
    static let shared = UsersLocalStorage()
    
    private init() {
    }
    
    @Published var userInfo: UserInfo?
    
    
    public func setUserInfo(userInfo: UserInfo?) {
        self.userInfo = userInfo
    }
}

