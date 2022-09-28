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
    func updateCoins()
    func searchCoin(text: String)
}

protocol CoinDataProvidingDependency {
    var coinDataRepository: CoinDataProviding { get }
}

class CoinDataRepository: CoinDataProviding {
    
    private let offlineUrl: URL
    private var offlineCoinData = CoinData(coins: [])
    private var coinDataSubject = CurrentValueSubject<CoinDataState, Never>(.loading)
    var coinDataPublisher: AnyPublisher<CoinDataState, Never> {
        coinDataSubject.share().eraseToAnyPublisher()
    }
    
    private var cancellables = [AnyCancellable]()
    
    enum Errors: Error {
        case unableToConstructUrl
    }
    
    init() throws {
        guard let url = Bundle.main.url(forResource: "offline", withExtension: "json") else {
            preconditionFailure("offline.json not found")
        }
        
        self.offlineUrl = url
        try loadOfflineCoins()
        coinDataPublisher.sink(receiveValue: { coinDataState in
            guard case CoinDataState.loaded(let coinData) = coinDataState else {
                return
            }
            
            self.offlineCoinData = coinData
            do {
                try self.saveOffline()
            } catch {
                print(error)
            }
        })
        .store(in: &cancellables)
    }
    
    func updateCoins() {
        Task {
            try await fetch(coins: offlineCoinData.coins)
        }
    }
    
    func searchCoin(text: String) {
        Task {
            try await searchCoin(text: text)
        }
    }
    
    func fetch(coins: [Coin]) async throws {
        coinDataSubject.value = .loading
        let coinData = try await update(coins: coins)
        coinDataSubject.value = .loaded(coinData)
    }
    
    func searchCoin(text: String) async throws {
        // https://api.coingecko.com/api/v3/search?query=btc
        var urlComponents = URLComponents(string: "https://api.coingecko.com/api/v3/search")
        let queries = [
            URLQueryItem(name: "query", value: text)
        ]
        
        urlComponents?.queryItems = queries
        guard let url = urlComponents?.url else {
            throw Errors.unableToConstructUrl
        }
        
        print(url)
        let (data, request) = try await URLSession.shared.data(for: URLRequest(url: url))
        print(request)
        do {
            let decoder = JSONDecoder()
            decoder.keyDecodingStrategy = .convertFromSnakeCase
            let response = try JSONDecoder().decode(SearchResponse.self, from: data)
            print(response)
        } catch {
            print(error)
        }
        
    }
}

private extension CoinDataRepository {
    func loadOfflineCoins() throws {
        let data = try Data(contentsOf: offlineUrl)
        let coins = try JSONDecoder().decode([Coin].self, from: data)
        offlineCoinData = CoinData(coins: coins)
    }
    
    func saveOffline() throws {
        do {
            let data = try JSONEncoder().encode(offlineCoinData.coins)
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
