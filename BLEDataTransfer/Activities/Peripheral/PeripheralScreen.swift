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
    @State private var notes: String = ""
    let profile: PeripheralProfile

    init(manager: BLEPeripheralManager, profile: PeripheralProfile) {
        let viewModel = PeripheralViewModel(manager: manager)
        _peripheralViewModel = StateObject(wrappedValue: viewModel)
        self.profile = profile
    }

    var body: some View {
        List {
            Section("Name") {
                HStack {
                    Text(profile.name)
                        .foregroundStyle(Color.secondary)
                    Spacer()
                    SignalStrengthIndicator(rssi: profile.rssi)
                }
            }
            
            Section("BLE Status") {
                Text(peripheralViewModel.state.message)
            }

            Section("RSSI") {
                Text(String(profile.rssi))
                    .foregroundStyle(Color.secondary)
            }
            
            Section("Notes") {
                TextEditor(text: $notes)
                    .frame(height: 200)
            }
        }
        .navigationTitle("Peripheral")
        .onDisappear {
            peripheralViewModel.stopAdvertising()
        }
    }

}

#Preview {
    NavigationStack {
        PeripheralScreen(manager: BLEPeripheralManager(), profile: PeripheralProfile.sample)
    }
}
