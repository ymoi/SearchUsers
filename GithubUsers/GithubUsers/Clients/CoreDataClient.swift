//
//  CoreDataClient.swift
//  GithubUsers
//
//  Created by Yuri on 01.02.2024.
//

import ComposableArchitecture
import Foundation

protocol Database {
    var initialise: @Sendable () async throws -> Void { get }
}

protocol Reposotory {
    var saveSearchResult: @Sendable (
        _ result: SearchResult
    ) async -> Void { get }
    
    var saveUserDetails: @Sendable (
        _ user: User
    ) async -> Void { get }
}

@DependencyClient
struct CoreDataClient: Database, UserClient, Reposotory, Sendable {
    var initialise: @Sendable () async throws -> Void
    
    var searchByName: @Sendable (
        _ query: String,
        _ lastId: Int
    ) async throws -> SearchResult
    
    var fetchDetails: @Sendable (
        _ name: String
    ) async throws -> User
    
    var saveSearchResult: @Sendable (
        _ result: SearchResult
    ) async -> Void
    
    var saveUserDetails: @Sendable (
        _ user: User
    ) async -> Void
}


extension CoreDataClient: DependencyKey {
    static let liveValue: CoreDataClient = {
        let client = CoreDataClient {
            try await CoreDataStack.shared.loadPersistentStore()
        } searchByName: { query, page in
            let queryPredicate = NSPredicate(format: "ANY itemList.query == %@", query)
            let savedCount = await CoreDataStack.shared.mainContext.count(
                entityClass: ItemMO.self,
                predicate: queryPredicate
            )
            let neededCount = page * Defaults.itemsPerPage
            if savedCount == 0 || savedCount < neededCount {
                throw Failure()
            }
            let offset = neededCount - Defaults.itemsPerPage
            let sortDescriptor = NSSortDescriptor(key: "id", ascending: true)
            let items = await CoreDataStack.shared.mainContext.batchFetch(
                entityClass: ItemMO.self,
                offset: offset,
                fetchLimit: Defaults.itemsPerPage,
                predicate: queryPredicate,
                sortDescriptors: [sortDescriptor])
            
            let searchPredicate = NSPredicate(format: "query == %@", query)
            guard let searchResult = await CoreDataStack.shared.mainContext.fetchFirst(
                entityClass: ItemListMO.self,
                predicate: searchPredicate
            ) else {
                throw Failure()
            }
            
            let users = items.map({ item in
                User(from: item)
            })

            return SearchResult(
                total_count: Int(searchResult.totalCount),
                items: users,
                query: query
            )
        }
        fetchDetails: { name in
            let predicate = NSPredicate(format: "login == %@ AND hasDetails == YES", name)
            guard let userMO = await CoreDataStack.shared.mainContext.fetchFirst(
                entityClass: ItemMO.self,
                predicate: predicate
            ) else {
                throw Failure()
            }
            return User(from: userMO)
            
        }
        saveSearchResult: { searchResult in
            await CoreDataStack.shared.persistentContainer.performBackgroundTask { context in
                let searchResultPredicate = NSPredicate(format: "query == %@", searchResult.query)
                var result: ItemListMO = context.fetchOrCreate(by: searchResultPredicate)
                result.query = searchResult.query
                result.totalCount = Int32(searchResult.total_count)
                
                for item in searchResult.items {
                    let userId = item.id
                    let predicate = NSPredicate(format: "id == %d", userId)
                    var userMO: ItemMO = context.fetchOrCreate(by: predicate)
                    userMO.id = Int32(item.id)
                    userMO.login = item.login
                    userMO.imageLink = item.avatar_url
                    result.addToItems(userMO)
                }
                try? context.save()
            }
        } saveUserDetails: { user in
            await CoreDataStack.shared.persistentContainer.performBackgroundTask { context in
                let predicate = NSPredicate(format: "login == %@", user.login)
                let userMO = context.fetchFirst(entityClass: ItemMO.self, predicate: predicate)
                userMO?.company = user.company
                userMO?.location = user.location
                userMO?.bio = user.bio
                userMO?.repos = Int32(user.public_repos ?? 0)
                userMO?.followers = Int32(user.followers ?? 0)
                userMO?.following = Int32(user.following ?? 0)
                userMO?.hasDetails = true
                try? context.save()
            }
        }
            return client
        }()
        
    static let testValue = Self()
}

extension DependencyValues {
    var coreDataClient: CoreDataClient {
        get { self[CoreDataClient.self] }
        set { self[CoreDataClient.self] = newValue }
    }
}

extension CoreDataClient {
    static func mock() -> Self {
        Self {
        } searchByName: { query, lastId in
            SearchResult.mock
        } fetchDetails: { name in
            User.detailedMock
        } saveSearchResult: { _ in
        } saveUserDetails: { _ in
        }
    }
    
    static func failed() -> Self {
        struct MockError: Error {}
        return Self {
            throw MockError()
        } searchByName: { _, _ in
            throw MockError()
        } fetchDetails: { _ in
            throw MockError()
        } saveSearchResult: { _ in
        } saveUserDetails: { _ in
        }
    }
    
    static func pagination() -> Self {
        Self {
        } searchByName: { query, page in
            let result = SearchResult.mockPage(1)
            if page > result.items.count / Defaults.itemsPerPage {
                throw Failure()
            }
            return result 
        } fetchDetails: { _ in
            return User.detailedMock
        } saveSearchResult: { _ in
        } saveUserDetails: { _ in
        }
    }
}
