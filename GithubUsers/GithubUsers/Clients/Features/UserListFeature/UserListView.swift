//
//  UserListView.swift
//  GithubUsers
//
//  Created by Yuri on 01.02.2024.
//

import SwiftUI
import ComposableArchitecture

public struct UserListView: View {
    let store: StoreOf<UserListFeature>
    
    public init(store: StoreOf<UserListFeature>) {
        self.store = store
    }
    
    public var body: some View {
        Text("User List")
    }
}

#Preview {
    NavigationStack {
        UserListView(
            store: Store(
                initialState: UserListFeature.State()
            ) {
                UserListFeature()
            }
        )
    }
}



