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
    typealias Dependencies = CoinDataProvidingDependency & SearchDataProvidingDependency
    private let dependencies: Dependencies
    
    @ObservedObject private(set) var container: StateContainer<WatchlistViewState>
    @State var searchText = ""
    
    init(dependencies: Dependencies) {
        self.dependencies = dependencies
        let loaderModel = WatchlistLoaderModel(dependencies: dependencies)
        container = .init(state: .initialized(loaderModel))
        container.observe(loaderModel.load())
    }
    
    var body: some View {
        NavigationView {
            watchlistListView()
        }
    }
    
    func watchlistListView() -> some View {
        VStack {
            List(state.coinData.coins) { coin in
                watchlistRowView(coin: coin)
                    .swipeActions(edge: .trailing) {
                        Button(role: .destructive) {
                                print("minus")
                            } label: {
                                Label("Remove", systemImage: "trash.fill")
                            }
                        }
            }
            .navigationBarTitle(Text("Watchlist"))
            .refreshable {
                switch state {
                case .initialized(let model):
                    observe(model.load())
                case .loading(_):
                    return
                case .loaded(let model):
                    observe(model.update())
                case .loadingError(let model):
                    observe(model.retry())
                }
            }
            .onChange(of: searchText) { newValue in
                guard case .loaded(let model) = state else {
                    return
                }
                
                model.enterSearch(text: newValue)
            }
            .searchable(text: $searchText, placement: .navigationBarDrawer(displayMode: .always))
            .disabled(state.isLoading)
        }
    }
    
    func watchlistRowView(coin: Coin) -> some View {
        HStack {
            coinImageView(coin.imageUrl)
                .padding(.trailing, 5)
            VStack(alignment: .leading) {
                HStack {
                    Text(coin.symbol.uppercased())
                    Spacer()
                    if state.isLoading {
                        ShimmerView()
                            .frame(width: 75, height: 15)
                    } else {
                        Text(coin.price.doubleValue.asCurrencyWith6Decimals())
                    }
                }
                .font(.headline)
                
                HStack {
                    Text(coin.name)
                    Spacer()
                    if state.isLoading {
                        ShimmerView()
                            .frame(width: 40, height: 15)
                    } else {
                        Text(coin.priceChangePercentage24H.doubleValue.asPercentString())
                            .foregroundColor(
                                (coin.priceChangePercentage24H >= 0) ?
                                ColorTheme2.green :
                                ColorTheme2.red
                            )
                    }
                }
                .font(.subheadline)
            }
        }
        .padding(.vertical, 5)
    }
    
    func coinImageView(_ imageUrl: String?) -> some View {
        AsyncImage(
            url: URL(string: imageUrl ?? ""),
            content: { image in
                image.resizable()
                     .aspectRatio(contentMode: .fit)
                     .frame(maxWidth: 30, maxHeight: 30)
            },
            placeholder: {
                ShimmerView()
                    .frame(width: 30, height: 30)
            })
    }
}
