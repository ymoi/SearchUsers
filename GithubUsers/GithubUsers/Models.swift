//
//  Models.swift
//  GithubUsers
//
//  Created by Yuri on 04.02.2024.
//

import Foundation
import CoreData

//MARK: - User
struct User: Codable, Equatable, Identifiable, Sendable {
    var id: Int
    var avatar_url: String
    var login: String
    
    var company: String?
    var location: String?
    var bio: String?
    var public_repos: Int?
    var followers: Int?
    var following: Int?
}

extension User {
    init(from mo: ItemMO) {
        id = Int(mo.id)
        avatar_url = mo.imageLink ?? ""
        login = mo.login ?? ""
        
        company = mo.company
        location = mo.location
        bio = mo.bio
        public_repos = Int(mo.repos)
        followers = Int(mo.followers)
        following = Int(mo.following)
    }
}
extension User {
    static let mock = Self(
        id: Int.random(in: 0...Int.max),
        avatar_url: "",
        login: "Blob"
    )
    
    static let detailedMock = Self(
        id: Int.random(in: 0...Int.max),
        avatar_url: "",
        login: "Blob",
        company: "Company",
        location: "Location",
        bio: "Bio",
        public_repos: 10,
        followers: 100,
        following: 100
    )
}

//MARK: - SearchResult
struct SearchResult: Codable, Sendable, Equatable {
    var total_count: Int
    var items: [User]
    var query: String = ""
    
    private enum CodingKeys: String, CodingKey {
        case total_count, items
    }
}

extension SearchResult {
    static let mock = Self (
        total_count: 1,
        items: [User.mock],
        query: "Blob")
    
    static func mockPage(_ pages: Int) -> Self {
        let start = Defaults.itemsPerPage * (pages - 1)
        let end = Defaults.itemsPerPage * pages
        let users = (start..<end).map{User(id: $0, avatar_url: "", login: "\($0)")}
        return Self(
            total_count: Defaults.itemsPerPage * 2,
            items: users
        )
    }
}

