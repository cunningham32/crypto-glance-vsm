//
//  SearchViewState.swift
//  CryptoVSM
//
//  Created by Andrew Cunningham on 9/28/22.
//

import Foundation
import Combine

enum SearchViewState {
    case loading
    case loaded(SearchLoadedModeling)
}

protocol SearchLoadedModeling {
    var searchResponse: SearchResponse { get }
    func add(coin: Coin) -> AnyPublisher<SearchViewState, Never>
}

struct SearchLoadedModel: SearchLoadedModeling {
    let searchResponse: SearchResponse
    
    func add(coin: Coin) -> AnyPublisher<SearchViewState, Never> {
        Just(SearchViewState.loaded(self)).eraseToAnyPublisher()
    }
}
