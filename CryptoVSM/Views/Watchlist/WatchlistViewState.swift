//
//  WatchlistViewState.swift
//  CryptoVSM
//
//  Created by Andrew Cunningham on 9/27/22.
//

import Foundation
import Combine

// MARK: - State & Model Definitions

enum WatchlistViewState {
    case initialized(WatchlistLoaderModeling)
    case loading
    case loaded(WatchlistLoadedModeling)
    case offline(WatchlistOfflineModeling)
}

protocol WatchlistLoaderModeling {
    func loadWatchlist() -> AnyPublisher<WatchlistViewState, Never>
}

protocol WatchlistLoadedModeling {
    var coinData: CoinData { get }
    func updateWatchlist() -> AnyPublisher<WatchlistViewState, Never>
    func searchTextEntered(_ text: String)
}

protocol WatchlistOfflineModeling {
    var coinData: CoinData { get }
    func retry() -> AnyPublisher<WatchlistViewState, Never>
}

// MARK: - Model Implementations
struct WatchlistLoaderModel: WatchlistLoaderModeling {
    typealias Dependencies = CoinDataProvidingDependency
    let dependencies: Dependencies
    
    func loadWatchlist() -> AnyPublisher<WatchlistViewState, Never> {
        dependencies.coinDataRepository.updateCoins()
        return dependencies.coinDataRepository.coinDataPublisher.map { coinDataState in
            switch coinDataState {
            case .loading:
                return WatchlistViewState.loading
            case .loaded(let coinData):
                return WatchlistViewState.loaded(
                    WatchlistLoadedModel(dependencies: dependencies, coinData: coinData))
            }
        }.eraseToAnyPublisher()
    }
}

class WatchlistLoadedModel: WatchlistLoadedModeling {
    typealias Dependencies = CoinDataProvidingDependency
    let dependencies: Dependencies
    var coinData: CoinData
    
    private let searchTextPublisher = PassthroughSubject<String, Error>()
    private var cancellables = Set<AnyCancellable>()
    
    init(dependencies: Dependencies, coinData: CoinData) {
        self.dependencies = dependencies
        self.coinData = coinData
        
        setupSearchTextSubscriber()
    }
    
    func updateWatchlist() -> AnyPublisher<WatchlistViewState, Never> {
        dependencies.coinDataRepository.updateCoins()
        return dependencies.coinDataRepository.coinDataPublisher.map { coinDataState in
            switch coinDataState {
            case .loading:
                return WatchlistViewState.loading
            case .loaded(let coinData):
                return WatchlistViewState.loaded(
                    WatchlistLoadedModel(dependencies: self.dependencies, coinData: coinData))
            }
        }.eraseToAnyPublisher()
    }
    
    func searchTextEntered(_ text: String) {
        searchTextPublisher.send(text)
    }
}

private extension WatchlistLoadedModel {
    func setupSearchTextSubscriber() {
        searchTextPublisher
            .debounce(for: 0.8, scheduler: DispatchQueue.main)
            .sink { error in
                print(error)
            } receiveValue: { text in
                self.dependencies.coinDataRepository.searchCoin(text: text)
            }
            .store(in: &cancellables)
    }
}
