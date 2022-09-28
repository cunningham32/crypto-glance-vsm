//
//  ShimmerView.swift
//  CryptoVSM
//
//  Created by Andrew Cunningham on 9/28/22.
//

import SwiftUI

public struct ShimmerView: View {
    
    private struct Constants {
        static let duration: Double = 0.9
        static let minOpacity: Double = 0.25
        static let maxOpacity: Double = 1.0
        static let cornerRadius: CGFloat = 2.0
    }
    
    @State private var opacity: Double = Constants.minOpacity
    
    public var body: some View {
        RoundedRectangle(cornerRadius: Constants.cornerRadius)
            .fill(Color.gray)
            .opacity(opacity)
            .transition(.opacity)
            .onAppear {
                let baseAnimation = Animation.easeInOut(duration: Constants.duration)
                let repeated = baseAnimation.repeatForever(autoreverses: true)
                withAnimation(repeated) {
                    self.opacity = Constants.maxOpacity
                }
        }
    }
}
