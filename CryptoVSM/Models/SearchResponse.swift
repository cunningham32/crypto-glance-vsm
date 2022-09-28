//
//  SearchResponse.swift
//  CryptoVSM
//
//  Created by Andrew Cunningham on 9/28/22.
//

import Foundation

struct SearchResponse: Codable {
    let coins: [SearchResponseItem]
}

struct SearchResponseItem: Codable, Identifiable {
    let id: String
    let name: String
    let symbol: String
    let marketCapRank: Int?
    let thumb: String?
    let large: String?
}
