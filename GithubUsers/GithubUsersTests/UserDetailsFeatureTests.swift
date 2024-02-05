//
//  UserDetailsFeatureTests.swift
//  GithubUsersTests
//
//  Created by Yuri on 04.02.2024.
//

import ComposableArchitecture
import XCTest

@testable import GithubUsers

@MainActor
final class UserDetailsFeatureTests: XCTestCase {
    func testLoadFailed() async {
        let store = TestStore(initialState: UserDetailsFeature.State(user: User.mock)) {
            UserDetailsFeature()
        } withDependencies: {
            $0.coreDataClient = .failed()
            $0.githubClient = .failed()
        }
        await store.send(.load) {
            $0.source = .cache
        }
        await store.receive(\.loadFromServer) {
            $0.source = .remote
        }
    }
    
    func testLoadSucceeded() async {
        let store = TestStore(initialState: UserDetailsFeature.State(user: User.mock)) {
            UserDetailsFeature()
        } withDependencies: {
            $0.coreDataClient = .failed()
            $0.githubClient = .mock()
        }
        await store.send(.load) {
            $0.source = .cache
        }
        await store.receive(\.loadFromServer) {
            $0.source = .remote
        }
        await store.receive(\.loaded) {
            $0.user = User.detailedMock
        }
    }
}


