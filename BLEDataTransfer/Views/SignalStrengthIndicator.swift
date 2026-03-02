//
//  SignalStrengthIndicator.swift
//  BLEDataTransfer
//
//  Created by SAfonja on 3/1/26.
//

import SwiftUI

struct SignalStrengthIndicator: View {
    private let totalBars = 3
    let rssi: Int
    
    init(rssi: Int) {
        self.rssi = rssi
    }
    
    var body: some View {
        HStack(alignment: .bottom, spacing: 2) {
            ForEach(1...totalBars, id: \.self) { i in
                ZStack {
                    Rectangle()
                        .frame(width: 5, height: height(for: i))
                        .foregroundStyle(i <= barsToFill ? Color.green.opacity(0.75) : Color.gray.opacity(0.25))
                }
                
            }
        }
    }
    
    private var barsToFill: Int {
        switch rssi {
        case -50...0:
            return 3
        case -65..<(-50):
            return 2
        case -80..<(-65):
            return 1
        default:
            return 0
        }
    }
    
    func shouldFillBar(_ barIndex: Int) -> Bool {
        barIndex <= barsToFill
    }
    
    func height(for barIndex: Int) -> CGFloat {
        CGFloat(barIndex) * 5
    }
    
    
}

#Preview {
    VStack {
        SignalStrengthIndicator(rssi: -5)
        SignalStrengthIndicator(rssi: -25)
        SignalStrengthIndicator(rssi: -60)
        SignalStrengthIndicator(rssi: -75)
        SignalStrengthIndicator(rssi: -90)
    }
}
