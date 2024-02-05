//
//  UserListFeatureTests.swift
//  GithubUsersTests
//
//  Created by Yuri on 04.02.2024.
//

import ComposableArchitecture
import XCTest

@testable import GithubUsers

@MainActor
final class UserListFeatureTests: XCTestCase {
    
    func testSearchAndClearQuery() async {
        let store = TestStore(initialState: UserListFeature.State()) {
            UserListFeature()
        } withDependencies: {
            $0.coreDataClient = .failed()
            $0.githubClient = .mock()
        }
        
        await store.send(.searchQueryChanged("TES")) {
            $0.searchQuery = "TES"
        }
        await store.send(.searchQueryChangeDebounced)
        await store.receive(\.loadNext) {
            $0.isLoading = true
            $0.page = 1
        }
        await store.receive(\.loadFromCache) {
            $0.source = .cache
        }
        await store.receive(\.loadFromServer) {
            $0.source = .remote
        }
        await store.receive(\.searchResponse) {
            $0.isLoading = false
            $0.isMoreDataAvailable = false
            var expectedUsers: IdentifiedArrayOf<User> = []
            expectedUsers.append(contentsOf: SearchResult.mock.items)
            $0.items = expectedUsers
        }
        
        await store.send(.searchQueryChanged("")) {
            $0.items = []
            $0.searchQuery = ""
            $0.isMoreDataAvailable = true
            $0.page = 0
        }
    }
    
    func testCachedSearch() async {
        let store = TestStore(initialState: UserListFeature.State()) {
            UserListFeature()
        } withDependencies: {
            $0.coreDataClient = .mock()
            $0.githubClient = .mock()
        }
        await store.send(.searchQueryChanged("TES")) {
            $0.searchQuery = "TES"
        }
        
        await store.send(.searchQueryChangeDebounced)
        
        await store.receive(\.loadNext) {
            $0.isLoading = true
            $0.page = 1
        }
        await store.receive(\.loadFromCache) {
            $0.source = .cache
        }
        await store.receive(\.searchResponse) {
            $0.isLoading = false
            $0.isMoreDataAvailable = false
            var expectedUsers: IdentifiedArrayOf<User> = []
            expectedUsers.append(contentsOf: SearchResult.mock.items)
            $0.items = expectedUsers
        }
    }
    
    func testSearchFailure() async {
        let store = TestStore(initialState: UserListFeature.State()) {
            UserListFeature()
        } withDependencies: {
            $0.coreDataClient = .failed()
            $0.githubClient = .failed()
        }
        
        await store.send(.searchQueryChanged("TES")) {
            $0.searchQuery = "TES"
        }
        await store.send(.searchQueryChangeDebounced)
        await store.receive(\.loadNext) {
            $0.isLoading = true
            $0.page = 1
        }
        await store.receive(\.loadFromCache) {
            $0.source = .cache
        }
        await store.receive(\.loadFromServer) {
            $0.source = .remote
        }
        await store.receive(\.searchResponse.failure) {
            $0.isLoading = false
            $0.isMoreDataAvailable = true
            $0.items = []
            $0.isNoData = true
        }
    }
    
    func testNoConnection() async {
        let store = TestStore(initialState: UserListFeature.State()) {
            UserListFeature()
        } withDependencies: {
            $0.coreDataClient = .failed()
            $0.githubClient = .noConnection()
        }
        
        await store.send(.searchQueryChanged("TES")) {
            $0.searchQuery = "TES"
        }
        await store.send(.searchQueryChangeDebounced)
        await store.receive(\.loadNext) {
            $0.isLoading = true
            $0.page = 1
        }
        await store.receive(\.loadFromCache) {
            $0.source = .cache
        }
        await store.receive(\.loadFromServer) {
            $0.source = .remote
        }
        await store.receive(\.searchResponse.failure) {
            $0.isInternetConnectionErrorShown = true
            $0.isLoading = false
            $0.isMoreDataAvailable = true
            $0.items = []
            $0.isNoData = false
        }
    }

    
    func testClearQueryCancelsInFlightSearchRequest() async {
        let store = TestStore(initialState: UserListFeature.State()) {
            UserListFeature()
        } withDependencies: {
            $0.coreDataClient = .failed()
            $0.githubClient = .mock()
        }
        let searchQueryChanged = await store.send(.searchQueryChanged("S")) {
               $0.searchQuery = "S"
             }
        await searchQueryChanged.cancel()
        await store.send(.searchQueryChanged("")) {
            $0.searchQuery = ""
        }
    }
    
    func testCachAndnextPagesRemote() async {
        let store = TestStore(initialState: UserListFeature.State()) {
            UserListFeature()
        } withDependencies: {
            $0.coreDataClient = .pagination()
            $0.githubClient = .pagination()
        }
        
        await store.send(.searchQueryChanged("TES")) {
            $0.searchQuery = "TES"
        }
        
        await store.send(.searchQueryChangeDebounced)
        
        await store.receive(\.loadNext) {
            $0.isLoading = true
            $0.page = 1
        }
        await store.receive(\.loadFromCache) {
            $0.source = .cache
        }
        await store.receive(\.searchResponse) {
            $0.isLoading = false
            $0.isMoreDataAvailable = true
            var expectedUsers: IdentifiedArrayOf<User> = []
            expectedUsers.append(contentsOf: SearchResult.mockPage(1).items)
            $0.items = expectedUsers
        }
        await store.send(.loadNext) {
            $0.isLoading = true
            $0.page = 2
        }
        await store.receive(\.loadFromCache)
        await store.receive(\.loadFromServer) {
            $0.source = .remote
        }
        await store.receive(\.searchResponse) {
            $0.isLoading = false
            $0.isMoreDataAvailable = false
            $0.isNoData = false
            var expectedUsers: IdentifiedArrayOf<User> = []
            expectedUsers.append(contentsOf: SearchResult.mockPage(1).items)
            expectedUsers.append(contentsOf: SearchResult.mockPage(2).items)
            $0.items = expectedUsers
        }
    }
}
