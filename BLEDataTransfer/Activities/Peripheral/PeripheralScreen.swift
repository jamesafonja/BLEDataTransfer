//
//  PeripheralScreen.swift
//  BLEDataTransfer
//
//  Created by SAfonja on 2/26/26.
//

import CoreBluetooth
import SwiftUI

struct PeripheralScreen: View {
    @StateObject private var peripheralViewModel: PeripheralViewModel
    
    init(manager: BLEPeripheralManager) {
        let viewModel = PeripheralViewModel(manager: manager)
        _peripheralViewModel = StateObject(wrappedValue: viewModel)
    }

    var body: some View {
        Text("Hello, World!")
    }
}

#Preview {
    PeripheralScreen(manager: BLEPeripheralManager())
}
