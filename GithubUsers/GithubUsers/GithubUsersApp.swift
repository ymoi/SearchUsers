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
    let store = Store(initialState: AppFeature.State()) {
        AppFeature()
    }
    
    var body: some Scene {
        WindowGroup {
            if _XCTIsTesting {
                // NB: Don't run application when testing so that it doesn't interfere with tests.
                EmptyView()
            } else {
                AppView(store: store)
            }
        }
    }
}
