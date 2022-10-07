//
//  CryptoVSMApp.swift
//  CryptoVSM
//
//  Created by Andrew Cunningham on 9/26/22.
//

import SwiftUI
import VSM

struct AppDependencies: RootView.Dependencies {
    var searchDataRepository: SearchDataProviding
    var persistenceManager: PersistenceManaging
    var coinDataRepository: CoinDataProviding
    
    init(coinDataRepository: CoinDataProviding,
         persistenceManager: PersistenceManaging,
         searchDataRepository: SearchDataProviding) {
        self.coinDataRepository = coinDataRepository
        self.persistenceManager = persistenceManager
        self.searchDataRepository = searchDataRepository
    }
    
    static func build() -> RootView.Dependencies {
        do {
            let persistenceManager = PersistenceManager()
            let coinDataRepository = try CoinDataRepository(persistenceManager: persistenceManager)
            let searchDataRepository = SearchDataRepository()
            return AppDependencies(
                coinDataRepository: coinDataRepository,
                persistenceManager: persistenceManager,
                searchDataRepository: searchDataRepository)
        } catch {
            fatalError("Dependency not initialized: \(error)")
        }
    }
}

@main
struct CryptoVSMApp: App {
    var body: some Scene {
        WindowGroup {
            RootView(dependencies: AppDependencies.build())
        }
    }
}
