//
//  CryptoVSMApp.swift
//  CryptoVSM
//
//  Created by Andrew Cunningham on 9/26/22.
//

import SwiftUI
import VSM

struct AppDependencies: RootView.Dependencies {
    var coinDataRepository: CoinDataProviding
    
    init(coinDataRepository: CoinDataProviding) {
        self.coinDataRepository = coinDataRepository
    }
    
    static func build() -> RootView.Dependencies {
        do {
            let coinDataRepository = try CoinDataRepository()
            return AppDependencies(coinDataRepository: coinDataRepository)
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
