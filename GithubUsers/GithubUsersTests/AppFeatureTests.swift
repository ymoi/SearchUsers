//
//  AppFeatureTests.swift
//  GithubUsersTests
//
//  Created by Yuri on 04.02.2024.
//

import ComposableArchitecture
import XCTest

@testable import GithubUsers

@MainActor
final class AppFeatureTests: XCTestCase {
    
    func testDetails() async throws {
        let user = User.mock
        let store = TestStore(initialState: AppFeature.State()) {
            AppFeature()
        } withDependencies: {
            $0.coreDataClient = .mock()
        }
        
        await store.send(.path(.push(id: 0, state: .details(UserDetailsFeature.State(user: user))))) {
            $0.requireSetup = false
            $0.path[id: 0] = .details(UserDetailsFeature.State(user: user))
        }
    }
    
}
