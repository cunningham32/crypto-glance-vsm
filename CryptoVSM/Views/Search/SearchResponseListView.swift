//
//  SearchResponseListView.swift
//  CryptoVSM
//
//  Created by Andrew Cunningham on 9/28/22.
//

import SwiftUI

struct SearchResponseListView: View {
    let items: [SearchResponseItem]
    
    var body: some View {
        List(items) { item in
            SearchResponseItemView(item: item)
        }
    }
}

struct SearchResponseListView_Previews: PreviewProvider {
    static let items = [
        SearchResponseItem(id: "bitcoin", name: "Bitcoin", symbol: "BTC", marketCapRank: 1, thumb: "https://assets.coingecko.com/coins/images/1/thumb/bitcoin.png", large: "https://assets.coingecko.com/coins/images/1/large/bitcoin.png"),
        SearchResponseItem(id: "bitcoin", name: "Bitcoin", symbol: "BTC", marketCapRank: 1, thumb: "https://assets.coingecko.com/coins/images/1/thumb/bitcoin.png", large: "https://assets.coingecko.com/coins/images/1/large/bitcoin.png"),
        SearchResponseItem(id: "bitcoin", name: "Bitcoin", symbol: "BTC", marketCapRank: 1, thumb: "https://assets.coingecko.com/coins/images/1/thumb/bitcoin.png", large: "https://assets.coingecko.com/coins/images/1/large/bitcoin.png")
    ]
    
    static var previews: some View {
        SearchResponseListView(items: items)
    }
}
