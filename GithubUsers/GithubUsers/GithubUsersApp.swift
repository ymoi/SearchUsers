//
//  GithubUsersApp.swift
//  GithubUsers
//
//  Created by Yuri on 01.02.2024.
//

import SwiftUI

@main
struct GithubUsersApp: App {
    let persistenceController = PersistenceController.shared

    var body: some Scene {
        WindowGroup {
            ContentView()
                .environment(\.managedObjectContext, persistenceController.container.viewContext)
        }
    }
}
