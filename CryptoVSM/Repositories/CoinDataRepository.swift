//
//  CoinDataRepository.swift
//  CryptoVSM
//
//  Created by Andrew Cunningham on 9/26/22.
//

import Foundation
import Combine

struct CoinData {
    let coins: [Coin]
}

enum CoinDataState {
    case loading
    case loaded(CoinData)
}

protocol CoinDataProviding {
    var coinDataPublisher: AnyPublisher<CoinDataState, Never> { get }
    var offlineCoinDataSubject: CurrentValueSubject<CoinData, Never> { get }
    
    func updateCoins() -> AnyPublisher<CoinDataState, Never>
    func load() -> AnyPublisher<CoinData, Error>
}

protocol CoinDataProvidingDependency {
    var coinDataRepository: CoinDataProviding { get }
}

class CoinDataRepository: CoinDataProviding {
    
    private let persistenceManager: PersistenceManaging
    private let offlineUrl: URL
    
    private var coinDataSubject = CurrentValueSubject<CoinDataState, Never>(.loading)
    var coinDataPublisher: AnyPublisher<CoinDataState, Never> {
        coinDataSubject.share().eraseToAnyPublisher()
    }
    
    var offlineCoinDataSubject = CurrentValueSubject<CoinData, Never>(CoinData(coins: []))
    
    private var cancellables = [AnyCancellable]()
    
    enum Errors: Error {
        case unableToConstructUrl
    }
    
    init(persistenceManager: PersistenceManaging) throws {
        guard let url = Bundle.main.url(forResource: "offline", withExtension: "json") else {
            preconditionFailure("offline.json not found")
        }
        
        self.persistenceManager = persistenceManager
        
        offlineUrl = url
        offlineCoinDataSubject.value = persistenceManager.load()
//        try loadOfflineCoins()
        
        coinDataPublisher.sink(receiveValue: { coinDataState in
            guard case CoinDataState.loaded(let coinData) = coinDataState else {
                return
            }
            
            self.offlineCoinDataSubject.value = coinData
            do {
                try self.saveOffline()
            } catch {
                print(error)
            }
        })
        .store(in: &cancellables)
    }
    
    func load() -> AnyPublisher<CoinData, Error> {
        do {
            let url = try buildURL(coins: offlineCoinDataSubject.value.coins)
            
            return URLSession.shared.dataTaskPublisher(for: url)
                    .tryMap(\.data)
                    .decode(type: [String: [String: Decimal]].self, decoder: JSONDecoder())
                    .compactMap { item in
                        let coins: [Coin] = self.offlineCoinDataSubject.value.coins.compactMap { coin in
                            guard let coinPrice = item[coin.id],
                                  let usdPrice = coinPrice["usd"],
                                  let priceChangePercentage24H = coinPrice["usd_24h_change"] else {
                                return nil
                            }
                            
                            return Coin(update: coin,
                                        with: usdPrice,
                                        priceChangePercentage24H: priceChangePercentage24H)
                            
                        }
                        
                        return CoinData(coins: coins)
                    }
                    .eraseToAnyPublisher()
        } catch {
            return Fail(error: error).eraseToAnyPublisher()
        }
    }
    
    func updateCoins() -> AnyPublisher<CoinDataState, Never> {
        coinDataSubject.value = .loading
        Task {
            let coinData = try await update(coins: offlineCoinDataSubject.value.coins)
            coinDataSubject.value = .loaded(coinData)
        }
        return coinDataSubject.eraseToAnyPublisher()
    }
}

private extension CoinDataRepository {
    func loadOfflineCoins() throws {
        let data = try Data(contentsOf: offlineUrl)
        let coins = try JSONDecoder().decode([Coin].self, from: data)
        offlineCoinDataSubject.value = CoinData(coins: coins)
    }
    
    func saveOffline() throws {
        do {
            let data = try JSONEncoder().encode(offlineCoinDataSubject.value.coins)
            try data.write(to: offlineUrl)
        } catch {
            print(error)
        }
        
        
    }
    
    func update(coins: [Coin]) async throws -> CoinData {
        let url = try buildURL(coins: coins)
        let (data, _) = try await URLSession.shared.data(for: URLRequest(url: url))
        let response = try JSONDecoder().decode([String: [String: Decimal]].self, from: data)
        let updated: [Coin] = coins.compactMap { coin in
            guard let coinPrice = response[coin.id],
                  let usdPrice = coinPrice["usd"],
                  let priceChangePercentage24H = coinPrice["usd_24h_change"] else {
                return nil
            }
            
            return Coin(update: coin,
                        with: usdPrice,
                        priceChangePercentage24H: priceChangePercentage24H)
        }
        
        return CoinData(coins: updated)
    }
    
    // TODO: make this more modular
    func buildURL(coins: [Coin]) throws -> URL {
        let queryIds = String(coins.reduce("") { partialResult, coin in
            partialResult + "," + coin.id
        }.dropFirst())
        
        var urlComponents = URLComponents(string: "https://api.coingecko.com/api/v3/simple/price")
        let queries = [
            URLQueryItem(name: "ids", value: queryIds),
            URLQueryItem(name: "vs_currencies", value: "usd"),
            URLQueryItem(name: "include_24hr_change", value: "true")
        ]
        
        urlComponents?.queryItems = queries
        guard let url = urlComponents?.url else {
            throw Errors.unableToConstructUrl
        }
        
        return url
    }
}
