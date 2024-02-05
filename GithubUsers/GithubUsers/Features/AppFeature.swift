//
//  AppFeature.swift
//  GithubUsers
//
//  Created by Yuri on 04.02.2024.
//

import ComposableArchitecture
import SwiftUI

@Reducer
struct AppFeature {
    @ObservableState
    struct State: Equatable {
        var path = StackState<Path.State>()
        var userList = UserListFeature.State()
        var requireSetup = true
    }
    
    enum Action {
        case path(StackAction<Path.State, Path.Action>)
        case userList(UserListFeature.Action)
    }
    @Dependency(\.coreDataClient) var coreDataClient
    
    var body: some ReducerOf<Self> {
        Scope(state: \.userList, action: \.userList) {
            UserListFeature()
        }
        Reduce { state, action in
            if state.requireSetup {
                state.requireSetup = false
                return .run { send in
                    try await coreDataClient.initialise()
                }
            }
            switch action {
            case .path:
                return .none
                
            case .userList:
                return .none
            }
        }
        .forEach(\.path, action: \.path) {
            Path()
        }
    }
    
    @Reducer
    struct Path {
        @ObservableState
        enum State: Equatable {
            case details(UserDetailsFeature.State)
        }
        
        enum Action {
            case details(UserDetailsFeature.Action)
        }
        
        var body: some Reducer<State, Action> {
            Scope(state: \.details, action: \.details) {
                UserDetailsFeature()
            }
        }
    }
}

struct AppView: View {
    @Bindable var store: StoreOf<AppFeature>
    
    var body: some View {
        NavigationStack(path: $store.scope(state: \.path, action: \.path)) {
            UserListView(
                store: store.scope(state: \.userList, action: \.userList)
            )
        } destination: { store in
            switch store.state {
            case .details:
                if let store = store.scope(state: \.details, action: \.details) {
                    UserDetailsView(store: store)
                }
            }
        }
    }
}
