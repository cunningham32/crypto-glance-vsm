//
//  SearchResponseItemView.swift
//  CryptoVSM
//
//  Created by Andrew Cunningham on 9/28/22.
//

import SwiftUI

struct SearchResponseItemView: View {
    let item: SearchResponseItem
    
    var body: some View {
        HStack {
            AsyncImage(url: URL(string: item.thumb ?? "")) { image in
                image.resizable()
                    .aspectRatio(contentMode: .fit)
                    .frame(maxWidth: 30, maxHeight: 30)
            } placeholder: {
                ProgressView()
            }
            
            VStack(alignment: .leading) {
                Text(item.symbol)
                    .font(.headline)
                Text(item.name)
                    .font(.subheadline)
            }
            
            Spacer()
            VStack {
                Text("Rank")
                    .font(.subheadline)
                item.marketCapRank != nil ?
                Text(String(item.marketCapRank!)) :
                Text("--")
            }
        }
    }
}

struct SearchResponseItemView_Previews: PreviewProvider {
    static var previews: some View {
        SearchResponseItemView(item: SearchResponseItem(id: "bitcoin", name: "Bitcoin", symbol: "BTC", marketCapRank: 1, thumb: "https://assets.coingecko.com/coins/images/1/thumb/bitcoin.png", large: "https://assets.coingecko.com/coins/images/1/large/bitcoin.png"))
    }
}
