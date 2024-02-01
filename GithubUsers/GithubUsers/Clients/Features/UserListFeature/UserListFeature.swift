//
//  UserListFeature.swift
//  GithubUsers
//
//  Created by Yuri on 01.02.2024.
//

import ComposableArchitecture

@Reducer
public struct UserListFeature {
  @ObservableState
  public enum State: Equatable {
    case loading
    public init() { self = .loading }
  }

  public enum Action {
    case load

  }

  public init() {}

  public var body: some Reducer<State, Action> {
    Reduce { state, action in
      switch action {
      case .load:
          return .none
      }
    }
  }
}
