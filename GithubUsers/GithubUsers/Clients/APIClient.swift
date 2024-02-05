//
//  APIClient.swift
//  GithubUsers
//
//  Created by Yuri on 01.02.2024.
//

import Foundation
import ComposableArchitecture
import Alamofire

enum Defaults {
    static let itemsPerPage: Int = 30
}

protocol UserClient {
    var searchByName: @Sendable (
        _ query: String,
        _ lastId: Int
    ) async throws -> SearchResult { get }
    
    var fetchDetails: @Sendable (
        _ name: String
    ) async throws -> User { get }
}

@DependencyClient
struct GithubAPIClient: UserClient, Sendable {
    
    var searchByName: @Sendable (
        _ query: String,
        _ lastId: Int
    ) async throws -> SearchResult
    
    var fetchDetails: @Sendable (
        _ name: String
    ) async throws -> User
}

struct Failure: Error {}

struct InternetConnectionError: Error {}


extension GithubAPIClient: DependencyKey {
    
    
    static let liveValue: GithubAPIClient = {
        let manager = NetworkReachabilityManager(host: "www.apple.com")
        let baseURLString: String = "https://api.github.com"
        
        let client = GithubAPIClient { query, page in
            if manager?.status == .notReachable {
                throw InternetConnectionError()
            }
            let params = [
                "per_page": "\(Defaults.itemsPerPage)",
                "page": "\(page)",
                "q": "\(query)"
            ]
            let response = await AF.request("\(baseURLString)/search/users", parameters: params)
                .validate()
                .serializingDecodable(SearchResult.self)
                .response
            switch response.result {
            case .success(let result):
                return result
            case .failure(let error):
                throw error
            }
        } fetchDetails: { name in
            if manager?.status == .notReachable {
                throw InternetConnectionError()
            }
            let response = await AF.request("\(baseURLString)/users/\(name)")
                .validate()
                .serializingDecodable(User.self)
                .response
            switch response.result {
            case .success(let result):
                return result
            case .failure(let error):
                throw error
            }
        }
        return client
    }()
    
    static let testValue = Self()
}

extension DependencyValues {
    var githubClient: GithubAPIClient {
        get { self[GithubAPIClient.self] }
        set { self[GithubAPIClient.self] = newValue }
    }
}

extension GithubAPIClient {
    static func mock() -> GithubAPIClient {
        Self { query, lastId in
            SearchResult.mock
        } fetchDetails: { name in
            User.detailedMock
        }
    }
    
    static func failed() -> GithubAPIClient {
        struct MockError: Error {}
        return Self { _, _ in
            throw MockError()
        } fetchDetails: { _ in
            throw MockError()
        }
    }
    
    static func noConnection() -> GithubAPIClient {
        Self { _, _ in
            throw InternetConnectionError()
        } fetchDetails: { _ in
            throw InternetConnectionError()
        }
    }
    
    static func pagination() -> Self {
        Self  { query, lastId in
            SearchResult.mockPage(2)
        } fetchDetails: { _ in
            return User.detailedMock
        }

    }
}
