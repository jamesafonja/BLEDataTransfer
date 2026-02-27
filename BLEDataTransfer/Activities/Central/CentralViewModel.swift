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
        guard
            profiles.count < 20,
            rssi > -75
        else { return }
        
        if let index = profiles.firstIndex(where: { $0.id == peripheral.identifier }) {
            profiles[index].rssi = rssi
        } else {
            let profile = PeripheralProfile(
                id: peripheral.identifier,
                name: name(for: peripheral),
                rssi: rssi,
                peripheral: peripheral
            )
            
            profiles.append(profile)
        }
        
        configureProfiles()
    }
    
    func configureProfiles() {
        profiles.sort { $0.rssi > $1.rssi }
        profiles = Array(profiles.prefix(10))
    }
    
    func didFailToConnect(peripheral: CBPeripheral, error: (any Error)?) {
        statusText = "Failed to connect to \(peripheral.name ?? "Unknown"): \(error?.localizedDescription ?? "Unknown error")"
    }
    
    func didConnect(peripheral: CBPeripheral) {
        statusText = "Connected to \(peripheral.name ?? "Unknown")"
    }

}

extension CentralViewModel {
    func name(for peripheral: CBPeripheral) -> String {
        if
            let peripheralName = peripheral.name,
            !peripheralName.isEmpty
        {
            return peripheralName
        } else {
            return "Unknown"
        }
    }
    
}
