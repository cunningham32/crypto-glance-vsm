//
//  WatchlistView.swift
//  CryptoVSM
//
//  Created by Andrew Cunningham on 9/26/22.
//

import SwiftUI
import VSM
import Combine

struct WatchlistView: View, ViewStateRendering {
    typealias Dependencies = CoinDataProvidingDependency
    private let dependencies: Dependencies
    @ObservedObject private(set) var container: StateContainer<WatchlistViewState>
    
    init(dependencies: Dependencies) {
        self.dependencies = dependencies
        let loaderModel = WatchlistLoaderModel(dependencies: dependencies)
        container = .init(state: .initialized(loaderModel))
        container.observe(loaderModel.loadWatchlist())
    }
    
    var body: some View {
        switch state {
        case .loading, .initialized(_):
            ProgressView()
        case .loaded(let loadedModel):
            WatchlistDataView(dependencies: dependencies, coins: loadedModel.coinData.coins)
        case .offline(_):
            Text("offline")
        }
    }
}

struct WatchlistDataView: View {
    let dependencies: WatchlistView.Dependencies
    let coins: [Coin]
    
    var body: some View {
        NavigationView {
            WatchlistListView(dependencies: dependencies, coins: coins)
        }
    }
}

struct WatchlistListView: View {
    let dependencies: WatchlistView.Dependencies
    let coins: [Coin]
    @State var searchText = ""
    
    var body: some View {
        VStack {
            List(coins) { coin in
                WatchlistRowView(coin: coin)
            }
            .navigationBarTitle(Text("Watchlist"))
            .refreshable {
                dependencies.coinDataRepository.updateCoins()
                print("update")
            }
            .onChange(of: searchText) { newValue in
                // update loaded model
                print(newValue)
            }
            .searchable(text: $searchText, placement: .navigationBarDrawer(displayMode: .always))
        }
    }
}

struct WatchlistRowView: View {
    let coin: Coin
    
    var body: some View {
        HStack {
            CoinImageView(imageUrl: coin.imageUrl)
                .padding(.trailing, 5)
            VStack(alignment: .leading) {
                HStack {
                    Text(coin.symbol.uppercased())
                    Spacer()
                    Text(coin.price.doubleValue.asCurrencyWith6Decimals())
                        
                }
                .font(.headline)
                
                HStack {
                    Text(coin.name)
                    Spacer()
                    Text(coin.priceChangePercentage24H.doubleValue.asPercentString())
                        .foregroundColor(
                            (coin.priceChangePercentage24H >= 0) ?
                            ColorTheme2.green :
                            ColorTheme2.red
                        )
                }
                .font(.subheadline)
            }
        }
        .padding(.vertical, 5)
    }
}

struct CoinImageView: View {
    let imageUrl: String?
    
    var body: some View {
        AsyncImage(
            url: URL(string: imageUrl ?? ""),
            content: { image in
                image.resizable()
                     .aspectRatio(contentMode: .fit)
                     .frame(maxWidth: 30, maxHeight: 30)
            },
            placeholder: {
                ProgressView()
            })
    }
}
