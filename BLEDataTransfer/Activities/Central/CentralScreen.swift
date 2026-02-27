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
    
    init() {
        let manager = BLECentralManager()
        let viewModel = CentralViewModel(manager: manager)
        _centralViewModel = StateObject(wrappedValue: viewModel)
    }

    var body: some View {
        VStack(alignment: .leading) {
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
                        Text(profile.name)
                    }
                }
            }
            Spacer()
        }
        .navigationTitle("Central")
        .onReceive(centralViewModel.$isOn) { value in
            debugPrint("centralViewModel.isOn changed:", value)
        }

    }
}

#Preview {
    CentralScreen()
}
