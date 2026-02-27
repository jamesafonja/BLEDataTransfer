//
//  CentralScreen.swift
//  BLEDataTransfer
//
//  Created by SAfonja on 2/23/26.
//

import CoreBluetooth
import SwiftUI

struct CentralScreen: View {
    @StateObject var manager: BLECentralManager
    
    init() {
        let manager = BLECentralManager.shared
        _manager = StateObject(wrappedValue: manager)
    }

    var body: some View {
        VStack(alignment: .leading) {
            List {
                Section("BLE Status") {
                    HStack {
                        Text("Status")
                        Spacer()
                        Text(manager.isOn ? "On" : "Off")
                            .foregroundColor(manager.isOn ? .green : .red)
                    }
                }
                
                Section("Devices") {
                    ForEach(manager.connectedPeripherals, id: \.self) { peripheral in
                        Text(peripheral.name ?? "Unknown")
                            .padding()
                    }
                }
            }
            Spacer()
        }
        .navigationTitle("Central")
        .onReceive(manager.$isOn) { value in
            debugPrint("manager.isOn changed:", value)
        }

    }
}

#Preview {
    CentralScreen()
}
