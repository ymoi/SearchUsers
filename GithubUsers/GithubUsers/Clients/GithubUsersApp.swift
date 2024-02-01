//
//  GithubUsersApp.swift
//  GithubUsers
//
//  Created by Yuri on 01.02.2024.
//

import SwiftUI
import ComposableArchitecture

@main
struct GithubUsersApp: App {
    static let store = Store(initialState: UserListFeature.State()) {
        UserListFeature()
    }
    var body: some Scene {
        WindowGroup {
            UserListView(store: GithubUsersApp.store)
        }
    }
}
