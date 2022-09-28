//
//  Coin.swift
//  CryptoVSM
//
//  Created by Andrew Cunningham on 9/27/22.
//

import Foundation

struct Coin: Codable, Identifiable {
    let id: String
    let name: String
    let symbol: String
    let imageUrl: String?
    let price: Decimal
    let priceChangePercentage24H: Decimal
    
    init(id: String,
         name: String,
         symbol: String,
         imageUrl: String?,
         price: Decimal,
         priceChangePercentage24H: Decimal) {
        self.id = id
        self.name = name
        self.symbol = symbol
        self.imageUrl = imageUrl
        self.price = price
        self.priceChangePercentage24H = priceChangePercentage24H
    }
    
    init(update: Coin, with price: Decimal, priceChangePercentage24H: Decimal) {
        self.id = update.id
        self.name = update.name
        self.symbol = update.symbol
        self.imageUrl = update.imageUrl
        self.price = price
        self.priceChangePercentage24H = priceChangePercentage24H
    }
}
