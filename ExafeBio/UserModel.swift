//
//  UserModel.swift
//  ExafeBio
//
//  Created by ExTrus on 11/15/23.
//

import Foundation

final class UserModel{
    struct User{
        var username: String
        var password: String
    }
    
    var model: [User] = [
        User(username: "suhun", password: "1234")
    ]
    
    func hasUser(name: String, pwd: String) -> Bool {
        for user in model {
            if user.username == name && user.password == pwd {
                return true
            }
        }
        return false
    }
}
