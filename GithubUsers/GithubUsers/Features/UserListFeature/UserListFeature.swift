//
//  UserListFeature.swift
//  GithubUsers
//
//  Created by Yuri on 01.02.2024.
//

import ComposableArchitecture

@Reducer
struct UserListFeature {
    @ObservableState
    struct State: Equatable {
        var isLoading = false
        var isMoreDataAvailable = true
        var isInternetConnectionErrorShown = false
        var isNoData = false
        
        var items: IdentifiedArrayOf<User> = []
        
        var searchQuery = ""
        var page = 0
        var source: Source = .remote
    }
    
    enum Source: Equatable {
        case cache
        case remote
    }
    
    private enum CancelID { case query }
    
    enum Action {
        case searchQueryChanged(String)
        case searchQueryChangeDebounced
        case loadNext
        case loadFromCache
        case loadFromServer
        case searchResponse(Result<SearchResult, Error>)
    }
    
    @Dependency(\.githubClient) var apiClient
    @Dependency(\.coreDataClient) var coreDataClient
    
    public init() {}
    
    public var body: some Reducer<State, Action> {
        Reduce { state, action in
            switch action {
            case .searchQueryChanged(let query):
                state.items = []
                state.page = 0
                state.isMoreDataAvailable = true
                state.searchQuery = query
                return .cancel(id: CancelID.query)
                
            case .searchQueryChangeDebounced:
                if state.searchQuery.count < 3 {
                    return .cancel(id: CancelID.query)
                }
                return .run { send in
                    await send(.loadNext)
                }
                .cancellable(id: CancelID.query)
                
            case .loadNext:
                guard state.isMoreDataAvailable else {
                    return .none
                }
                state.isLoading = true
                state.page += 1
                
                return .run { send in
                    await send(.loadFromCache)
                }
                .cancellable(id: CancelID.query)
                
            case .loadFromCache:
                state.source = .cache
                return .run { [query = state.searchQuery, page = state.page] send in
                    let result = try await coreDataClient.searchByName(query, page)
                    await send(.searchResponse(.success(result)))
                }
                catch: { _, send in
                    await send(.loadFromServer)
                }
                .cancellable(id: CancelID.query)
                
            case .loadFromServer:
                state.source = .remote
                return .run {  [query = state.searchQuery, page = state.page] send in
                    await send(
                        .searchResponse(
                            Result { try await apiClient.searchByName(query, page) }
                        )
                    )
                }
                .cancellable(id: CancelID.query)
                
            case .searchResponse( .success(let result)):
                state.items.append(contentsOf: result.items)
                state.isNoData = state.items.isEmpty
                state.isLoading = false
                state.isMoreDataAvailable = result.total_count > state.items.count
                if state.source == .cache {
                    return .none
                }
                state.isInternetConnectionErrorShown = false
                return .run { _ in
                    await coreDataClient.saveSearchResult(result)
                }
                
            case .searchResponse(.failure(let error)):
                state.isLoading = false
                if error is InternetConnectionError {
                    state.isInternetConnectionErrorShown = true
                } else {
                    if state.items.isEmpty {
                        state.isNoData = true
                    }
                }
                return .none
            }
        }
            
    }
}
