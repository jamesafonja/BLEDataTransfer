//
//  CentralViewModel.swift
//  BLEDataTransfer
//
//  Created by SAfonja on 2/27/26.
//

import Combine
import CoreBluetooth
import SwiftUI

@MainActor
final class CentralViewModel: ObservableObject {
    @Published var isOn: Bool = false
    @Published var profiles: [PeripheralProfile] = []
    @Published var statusText: String = ""
    
    private let manager: BLECentralManager
    
    init(manager: BLECentralManager) {
        self.manager = manager
        self.manager.delegate = self
    }
    
    func connect(to profile: PeripheralProfile) {
        statusText = "Connecting to \(profile.name)"
    }
    
    func stopScanning() {
        manager.stopScanning()
        statusText = "Scanning stopped"
    }
}

extension CentralViewModel: BLECentralManagerDelegate {
    func didUpdateState(isOn: Bool) {
        self.isOn = isOn
    }
    
    func didDiscover(peripheral: CBPeripheral, rssi: Int) {
        let name = peripheral.name ?? "Unknown"
        
        if let index = profiles.firstIndex(where: { $0.id == peripheral.identifier }) {
            profiles[index].rssi = rssi
        } else {
            let profile = PeripheralProfile(
                id: peripheral.identifier,
                name: name,
                rssi: rssi,
                peripheral: peripheral
            )
            
            profiles.append(profile)
        }
    }
    
    func didFailToConnect(peripheral: CBPeripheral, error: (any Error)?) {
        statusText = "Failed to connect to \(peripheral.name ?? "Unknown"): \(error?.localizedDescription ?? "Unknown error")"
    }
    
    func didConnect(peripheral: CBPeripheral) {
        statusText = "Connected to \(peripheral.name ?? "Unknown")"
    }

}

