//
//  BLECentralManager.swift
//  BLEDataTransfer
//
//  Created by SAfonja on 2/23/26.
//

import Combine
import CoreBluetooth
import Foundation
import os

@MainActor
final class BLECentral: NSObject, ObservableObject {
    @Published var isOn: Bool = false
    @Published var connectedPeripherals: [CBPeripheral] = []
    @Published var selectedPeripheral: CBPeripheral?
    @Published var transferCharacteristic: CBCharacteristic?
    @Published var data = Data()
    @Published var bluetoothState: String = ""
    @Published var stringFromData: String = ""
    
    private lazy var centralManager: CBCentralManager = { [unowned self] () -> CBCentralManager in
        CBCentralManager(
            delegate: self,
            queue: nil,
            options: [CBCentralManagerOptionShowPowerAlertKey: true]
        )
    }()
    
    var writeIterationsComplete: Int = 0
    var connectionIterationsComplete: Int = 0
    var maxIterations: Int = 5
    
    func getPeripheral() {
        // Retrieve only peripherals that meet a known service criteria
        connectedPeripherals = centralManager.retrieveConnectedPeripherals(withServices: [TargetDevice.serviceUUID])
        
        if let connectedPeripheral = connectedPeripherals.last {
            centralManager.connect(connectedPeripheral)
            self.selectedPeripheral = connectedPeripheral
        } else {
            centralManager.scanForPeripherals(withServices: [TargetDevice.serviceUUID])
        }
    }
    
    private func cleanUp() {
        guard
            let selectedPeripheral = selectedPeripheral,
            case .connected = selectedPeripheral.state
        else { return }
        
        for service in selectedPeripheral.services ?? [] {
            for characteristic in service.characteristics ?? [] {
                if characteristic.uuid == TargetDevice.characteristicUUID && characteristic.isNotifying {
                    self.selectedPeripheral?.setNotifyValue(false, for: characteristic)
                }
            }
        }
        
        centralManager.cancelPeripheralConnection(selectedPeripheral)
    }
    
    private func writeData() {
        guard
            let selectedPeripheral = selectedPeripheral,
            let transferCharacteristic = transferCharacteristic
        else { return }
        
        while (writeIterationsComplete < maxIterations) && (selectedPeripheral.canSendWriteWithoutResponse) {
            let mtu = selectedPeripheral.maximumWriteValueLength(for: .withoutResponse) // Not requiring a response translates to faster writes
            var rawPacket = [UInt8](repeating: 0, count: mtu) // Since capacity is known, allocate the size for optimization
            let bytesToCopy: size_t = min(mtu, data.count)
            
            data.copyBytes(to: &rawPacket, count: bytesToCopy)
            
            let packetData = Data(bytes: &rawPacket, count: bytesToCopy)
            stringFromData = String(data: packetData, encoding: .utf8) ?? "Could not convert data"
            
            selectedPeripheral.writeValue(packetData, for: transferCharacteristic, type: .withoutResponse)
            
            writeIterationsComplete += 1
        }
        
        // Cancel subscription if max iterations have been completed
        if writeIterationsComplete == maxIterations {
            selectedPeripheral.setNotifyValue(false, for: transferCharacteristic)
        }
    }
}

// MARK: - CBCentralManagerDelegate

extension BLECentral: CBCentralManagerDelegate {
    func centralManagerDidUpdateState(_ central: CBCentralManager) {
        self.isOn = central.state == .poweredOn
        bluetoothState = central.state.description
    }
    
    func centralManager(
        _ central: CBCentralManager,
        didDiscover peripheral: CBPeripheral,
        advertisementData: [String : Any], rssi RSSI: NSNumber
    ) {
        guard RSSI.intValue >= -50 else {
            bluetoothState = String(format: "Discovered peripheral not in expected range, at %d", RSSI.intValue)
            return
        }
        
        bluetoothState = String(format: "Discovered %s at %d", String(describing: peripheral.name), RSSI.intValue)
        
        if selectedPeripheral != peripheral {
            selectedPeripheral = peripheral
            bluetoothState = "Connecting to peripheral \(peripheral.name ?? "Unknown")"
            centralManager.connect(peripheral, options: nil)
        }
    }
    
    func centralManager(_ central: CBCentralManager, didFailToConnect peripheral: CBPeripheral, error: (any Error)?) {
        bluetoothState = String(format: "Failed to connect to %@. %s", peripheral, String(describing: error))
        cleanUp()
    }
    
    func centralManager(_ central: CBCentralManager, didConnect peripheral: CBPeripheral) {
        bluetoothState = "Peripheral connected"
        centralManager.stopScan()
        bluetoothState = "Scanning stopped"
        
        connectionIterationsComplete += 1
        writeIterationsComplete = 0
        
        data.removeAll(keepingCapacity: false)
        
        // Peripheral delegate functions need to be implemented
//        peripheral.delegate = self
//        peripheral.discoverServices([TargetDevice.serviceUUID])
    }
}

// MARK: - CBPeripheralDelegate

