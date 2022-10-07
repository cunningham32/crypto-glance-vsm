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
    case loading(WatchlistLoadingModeling)
    case loaded(WatchlistLoadedModeling)
    case loadingError(ErrorModeling)
}

extension WatchlistViewState {
    var coinData: CoinData {
        switch self {
        case .initialized(let model):
            return model.offlineCoinData
        case .loading(let model):
            return model.offlineCoinData
        case .loadingError(let model):
            return model.offlineCoinData
        case .loaded(let model):
            return model.coinData
        }
    }
    
    var isLoading: Bool {
        switch self {
        case .initialized(_), .loading(_):
            return true
        case .loaded(_), .loadingError(_):
            return false
        }
    }
}

protocol WatchlistLoaderModeling {
    var offlineCoinData: CoinData { get }
    func load() -> AnyPublisher<WatchlistViewState, Never>
}

protocol WatchlistLoadingModeling {
    var offlineCoinData: CoinData { get }
}

protocol WatchlistLoadedModeling {
    var coinData: CoinData { get }
    func update() -> AnyPublisher<WatchlistViewState, Never>
    func enterSearch(text: String) -> AnyPublisher<WatchlistViewState, Never>
}

protocol ErrorModeling {
    var offlineCoinData: CoinData { get }
    var message: String { get }
    func retry() -> AnyPublisher<WatchlistViewState, Never>
}

// MARK: - Model Implementations
struct WatchlistLoaderModel: WatchlistLoaderModeling {
    typealias Dependencies = CoinDataProvidingDependency & SearchDataProvidingDependency
    let dependencies: Dependencies
    let offlineCoinData: CoinData
    
    init(dependencies: Dependencies) {
        self.dependencies = dependencies
        self.offlineCoinData = dependencies.coinDataRepository.offlineCoinDataSubject.value
    }
    
    func load() -> AnyPublisher<WatchlistViewState, Never> {
        loadWatchlistData()
            .merge(with: getWatchlistDataStream())
            .eraseToAnyPublisher()
    }
}

private extension WatchlistLoaderModel {
    private func loadWatchlistData() -> AnyPublisher<WatchlistViewState, Never> {
        dependencies.coinDataRepository.load()
            .map { coinData in
            WatchlistViewState.loaded(
                WatchlistLoadedModel(dependencies: dependencies, coinData: coinData))
            }
            .catch{ error -> Just<WatchlistViewState> in
                let errorModel = ErrorModel(offlineCoinData: offlineCoinData, message: error.localizedDescription)
                return Just(WatchlistViewState.loadingError(errorModel))
            }
            .eraseToAnyPublisher()
    }
    
    private func getWatchlistDataStream() -> AnyPublisher<WatchlistViewState, Never> {
        dependencies.coinDataRepository.coinDataPublisher
            .map { dataState -> WatchlistViewState in
                switch dataState {
                case .loading:
                    return .loading(WatchlistLoadingModel(offlineCoinData: offlineCoinData))
                case .loaded(let coinData):
                    return .loaded(WatchlistLoadedModel(dependencies: dependencies, coinData: coinData))
                }
            }
            .eraseToAnyPublisher()
    }
}

struct WatchlistLoadingModel: WatchlistLoadingModeling {
    let offlineCoinData: CoinData
}

class WatchlistLoadedModel: WatchlistLoadedModeling {
    typealias Dependencies = CoinDataProvidingDependency & SearchDataProvidingDependency
    let dependencies: Dependencies
    var coinData: CoinData
    var searchResponse: SearchResponse
    private let searchViewState = CurrentValueSubject<SearchDataState, Never>(.notActive)
    
    private let searchTextPublisher = PassthroughSubject<String, Error>()
    private var cancellables = Set<AnyCancellable>()
    
    init(dependencies: Dependencies, coinData: CoinData, searchResponse: SearchResponse? = nil) {
        self.dependencies = dependencies
        self.coinData = coinData
        self.searchResponse = searchResponse ?? SearchResponse(coins: [])
        
        setupSearchTextSubscriber()
    }
    
    func update() -> AnyPublisher<WatchlistViewState, Never> {
        dependencies.coinDataRepository.updateCoins().map { coinDataState in
            switch coinDataState {
            case .loading:
                return WatchlistViewState.loading(WatchlistLoadingModel(offlineCoinData: self.coinData))
            case .loaded(let coinData):
                return WatchlistViewState.loaded(
                    WatchlistLoadedModel(dependencies: self.dependencies, coinData: coinData))
            }
        }.eraseToAnyPublisher()
    }
    
    func enterSearch(text: String) -> AnyPublisher<WatchlistViewState, Never> {
        let coinData = CoinData(coins:
            coinData.coins.filter { $0.symbol.contains(text) || $0.name.contains(text) })
        searchTextPublisher.send(text)
        return Just(WatchlistViewState.loaded(
            WatchlistLoadedModel(dependencies: dependencies, coinData: coinData)))
                .eraseToAnyPublisher()
    }
}

private extension WatchlistLoadedModel {
    private func loadSearchData(text: String) {
        dependencies.searchDataRepository.searchCoin(text: text).sink {
            self.searchViewState.value = $0
        }
        
        
    }
    
    func setupSearchTextSubscriber() {
        searchTextPublisher
            .debounce(for: 0.8, scheduler: DispatchQueue.main)
            .sink { error in
                print(error)
            } receiveValue: { text in
                let query = text.trimmingCharacters(in: .whitespacesAndNewlines)
                guard !query.isEmpty else { return }
                self.loadSearchData(text: query)
            }
            .store(in: &cancellables)
    }
}

struct ErrorModel: ErrorModeling {
    let offlineCoinData: CoinData
    let message: String
    
    func retry() -> AnyPublisher<WatchlistViewState, Never> {
        Just(WatchlistViewState.loadingError(self)).eraseToAnyPublisher()
    }
}
