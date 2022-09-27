//
//  RootView.swift
//  CryptoVSM
//
//  Created by Andrew Cunningham on 9/26/22.
//

import SwiftUI

struct RootView: View {
    typealias Dependencies = WatchlistView.Dependencies
    private let dependencies: Dependencies
    
    init(dependencies: Dependencies) {
        self.dependencies = dependencies
    }
    
    var body: some View {
        WatchlistView(dependencies: dependencies)
    }
}
