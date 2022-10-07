//
//  PersistenceRepository.swift
//  CryptoVSM
//
//  Created by Andrew Cunningham on 9/28/22.
//

import Foundation

protocol PersistenceManaging {
    func load() -> CoinData
    func save(_ coinData: CoinData)
}

struct PersistenceManager: PersistenceManaging {
    let defaults = UserDefaults.standard
    let coinDataKey = "CoinData"
    
    func load() -> CoinData {
        defaults.object(forKey: coinDataKey) as? CoinData ?? CoinData(coins: [])
    }
    
    func save(_ coinData: CoinData) {
        defaults.set(coinData, forKey: coinDataKey)
    }
}
