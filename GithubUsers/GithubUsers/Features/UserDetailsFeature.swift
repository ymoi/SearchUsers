//
//  UserDetailsFeature.swift
//  GithubUsers
//
//  Created by Yuri on 04.02.2024.
//

import SwiftUI
import ComposableArchitecture
import Kingfisher

@Reducer
struct UserDetailsFeature {
    @ObservableState
    struct State: Equatable {
        var user: User
        var source: Source = .remote
    }
    
    enum Action {
        case load
        case loadFromServer
        case loaded(User)
    }
    
    enum Source: Equatable {
        case cache
        case remote
    }
    
    @Dependency(\.githubClient) var apiClient
    @Dependency(\.coreDataClient) var coreDataClient
    
    public var body: some Reducer<State, Action> {
        Reduce { state, action in
            switch action {
            case .load:
                state.source = .cache
                return .run { [name = state.user.login] send in
                    let result = try await coreDataClient.fetchDetails(name)
                    await send(.loaded(result))
                }
                catch: { _, send in
                    await send(.loadFromServer)
                }
                
            case .loadFromServer:
                state.source = .remote
                return .run { [name = state.user.login] send in
                    do {
                        let result = try await apiClient.fetchDetails(name)
                        await send(.loaded(result))
                    } catch { }
                }
                
            case .loaded(let user):
                state.user = user
                if state.source == .cache {
                    return .none
                }
                return .run { _ in
                    await coreDataClient.saveUserDetails(user)
                }
            }
        }
    }
}

struct UserDetailsView: View {
    var store: StoreOf<UserDetailsFeature>
    
    var body: some View {
        VStack(alignment: .leading) {
            HStack(spacing: 20) {
                KFImage(URL(string: store.user.avatar_url)!).placeholder({
                    Image(systemName: "person.circle")
                })
                .resizable()
                .scaledToFit()
                .frame(width: 100, height: 100)
                .cornerRadius(8)
                .padding(20)
                Text(store.user.login).font(.system(size: 20))
            }
            Form {
                LabeledContent("Company: ", value: store.user.company ?? "")
                LabeledContent("Location: ", value: store.user.location ?? "")
                LabeledContent("Bio: ", value: store.user.bio ?? "")
                LabeledContent("Repositories: ", value: "\(store.user.public_repos ?? 0)")
                LabeledContent("Followers: ", value: "\(store.user.followers ?? 0)")
                LabeledContent("Following: ", value: "\(store.user.following ?? 0)")
            }
        }
        .task {
            store.send(.load)
        }
        .navigationTitle("User")
    }
}
