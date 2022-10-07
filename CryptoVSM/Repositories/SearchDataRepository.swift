//
//  SearchDataRepository.swift
//  CryptoVSM
//
//  Created by Andrew Cunningham on 9/28/22.
//

import Foundation
import Combine

enum SearchDataState {
    case notActive
    case loading
    case loaded(SearchResponse)
}

protocol SearchDataProvidingDependency {
    var searchDataRepository: SearchDataProviding { get }
}

protocol SearchDataProviding {
    var searchDataPublisher: AnyPublisher<SearchDataState, Never> { get }
    func searchCoin(text: String) -> AnyPublisher<SearchDataState, Never>
}

class SearchDataRepository: SearchDataProviding {
    private let searchDataSubject = CurrentValueSubject<SearchDataState, Never>(.notActive)
    var searchDataPublisher: AnyPublisher<SearchDataState, Never> {
        searchDataSubject.share().eraseToAnyPublisher()
    }
    
    enum Errors: Error {
        case unableToConstructUrl
    }
    
    func searchCoin(text: String) -> AnyPublisher<SearchDataState, Never> {
        searchDataSubject.value = .loading
        Task {
            let response = try await searchCoin(text: text)
            searchDataSubject.value = .loaded(response)
        }
        return searchDataPublisher.eraseToAnyPublisher()
    }
    
    func searchCoin(text: String) async throws -> SearchResponse {
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
        let (data, _) = try await URLSession.shared.data(for: URLRequest(url: url))
        let decoder = JSONDecoder()
        decoder.keyDecodingStrategy = .convertFromSnakeCase
        return try JSONDecoder().decode(SearchResponse.self, from: data)
    }
}
