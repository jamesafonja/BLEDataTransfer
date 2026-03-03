//
//  CentralScreen.swift
//  BLEDataTransfer
//
//  Created by SAfonja on 2/23/26.
//

import CoreBluetooth
import SwiftUI

struct CentralScreen: View {
    @StateObject var centralViewModel: CentralViewModel
    
    init(manager: BLECentralManager) {
        let viewModel = CentralViewModel(manager: manager)
        _centralViewModel = StateObject(wrappedValue: viewModel)
    }

    var body: some View {
        ZStack {
            List {
                Section("BLE") {
                    HStack {
                        Text("Connection")
                        Spacer()
                        Text(centralViewModel.isOn ? "On" : "Off")
                            .foregroundColor(centralViewModel.isOn ? .green : .red)
                    }
                }
                
                Section("Devices") {
                    ForEach(centralViewModel.profiles) { profile in
                        HStack {
                            Text(profile.name)
                            Spacer()
                            SignalStrengthIndicator(rssi: profile.rssi)
                        }
                    }
                }
            }
            .toolbar {
                ToolbarItem(placement: .automatic) {
                    Button(centralViewModel.state == .idle ? "Scan" : "Stop") {
                        
                        if centralViewModel.state == .idle {
                            centralViewModel.startScanning()
                        } else {
                            centralViewModel.stopScanning()
                        }
                    }
                }
            }
            
            if centralViewModel.state == .scanning {
                VStack {
                    LoadingView()
                    Text(centralViewModel.statusText)
                        .foregroundStyle(Color.gray.opacity(0.5))
                }
            }
            
            if centralViewModel.state == .idle && centralViewModel.profiles.isEmpty {
                Text("Press the \"scan\" button to discover peripherals")
                    .font(.title3)
                    .foregroundStyle(Color.gray.opacity(0.75))
                    .padding(.horizontal, 20)
            }
        }
        .navigationTitle("Central")
        .onReceive(centralViewModel.$isOn) { value in
            debugPrint("centralViewModel.isOn changed:", value)
        }
    }
}

#Preview {
    NavigationStack {
        CentralScreen(manager: BLECentralManager())
    }
}
