//
//  UserListView.swift
//  GithubUsers
//
//  Created by Yuri on 01.02.2024.
//

import SwiftUI
import ComposableArchitecture
import Kingfisher

struct UserListView: View {
    @Bindable var store: StoreOf<UserListFeature>
    
    public var body: some View {
        NavigationView {
            userList
                .task(id: store.searchQuery) {
                    do {
                        try await Task.sleep(for: .milliseconds(300))
                        await store.send(.searchQueryChangeDebounced).finish()
                    } catch {}
                }
        }
        .navigationTitle("Search")
        .navigationViewStyle(.stack)
    }
    
    var userList: some View {
        VStack(spacing: 0) {
            searchView.padding(8)
            List {
                ForEach(store.items) { item in
                    NavigationLink(
                        state: AppFeature.Path.State.details(UserDetailsFeature.State(user: item))
                    ) {
                        ItemView(item: item)
                    }
                }
                if !store.items.isEmpty, store.isMoreDataAvailable {
                    LoadingRow().onAppear {
                        store.send(.loadNext)
                    }
                }
            }.overlay {
                if store.items.isEmpty,
                   store.isInternetConnectionErrorShown {
                    noDataView
                } else if store.isNoData{
                    ContentUnavailableView.search
                }
            }
        }
    }
    
    var noDataView: some View {
        ContentUnavailableView {
            Label("Error", systemImage: "wifi.slash")
        } description: {
            Text("Check your internet connection and try again")
        }
    }
    
    var searchView: some View {
        HStack {
            Image(systemName: "magnifyingglass")
            TextField(
                "Search users ...",
                text: $store.searchQuery.sending(\.searchQueryChanged)
            )
            .disableAutocorrection(true)
            .keyboardType(.asciiCapable)
            .textFieldStyle(.roundedBorder)
            .autocapitalization(.none)
            
        }
        .padding(.horizontal, 16)
    }
}

struct ItemView: View {
    
    let item: User
    
    var body: some View {
        HStack(spacing: 20) {
            KFImage(URL(string: item.avatar_url)!).placeholder({
                Image(systemName: "person.circle")
            })
            .resizable()
            .scaledToFit()
            .frame(width: 30, height: 30)
            .cornerRadius(15)
            Text(item.login)
        }
        .frame(height: 44)
    }
}

struct LoadingRow: View {
    var body: some View {
        HStack(alignment: .center, spacing: 20) {
            ProgressView()
                .progressViewStyle(CircularProgressViewStyle())
            Text("Loading")
        }
    }
}

