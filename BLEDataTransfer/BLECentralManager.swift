//
//  BLECentralManager.swift
//  BLEDataTransfer
//
//  Created by SAfonja on 2/23/26.
//

import Combine
import CoreBluetooth

// MARK: - BLECentralManager
/*
 TODO: Decouple business logic and view-related functions using MVVM
 */

@MainActor
final class BLECentralManager: NSObject, ObservableObject {
    @Published var isOn: Bool = false
    @Published var connectedPeripherals: [CBPeripheral] = []
    @Published var selectedPeripheral: CBPeripheral?
    @Published var targetCharacteristic: CBCharacteristic?
    @Published var data = Data()
    @Published var characteristicText: String = ""
    @Published var bluetoothState: String = ""
    @Published var stringFromData: String = ""
    
    static let shared = BLECentralManager()
    
    private override init() {
        super.init()
    }
    
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
        connectedPeripherals = centralManager.retrieveConnectedPeripherals(withServices: [TargetService.serviceUUID])
        
        if let connectedPeripheral = connectedPeripherals.last {
            centralManager.connect(connectedPeripheral)
            self.selectedPeripheral = connectedPeripheral
        } else {
            centralManager.scanForPeripherals(withServices: [TargetService.serviceUUID])
        }
    }
    
    private func cleanUp() {
        guard
            let selectedPeripheral = selectedPeripheral,
            case .connected = selectedPeripheral.state
        else { return }
        
        for service in selectedPeripheral.services ?? [] {
            for characteristic in service.characteristics ?? [] {
                if characteristic.uuid == TargetService.characteristicUUID && characteristic.isNotifying {
                    self.selectedPeripheral?.setNotifyValue(false, for: characteristic)
                }
            }
        }
        
        centralManager.cancelPeripheralConnection(selectedPeripheral)
    }
    
    func stop() {
        centralManager.stopScan()
        bluetoothState = "Scanning stopped"
        data.removeAll(keepingCapacity: false)
    }
    
    private func writeData() {
        guard
            let selectedPeripheral = selectedPeripheral,
            let transferCharacteristic = targetCharacteristic
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

extension BLECentralManager: CBCentralManagerDelegate {
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
        
        peripheral.delegate = self
        peripheral.discoverServices([TargetService.serviceUUID])
    }
}

// MARK: - CBPeripheralDelegate

extension BLECentralManager: CBPeripheralDelegate {
        
    func peripheral(_ peripheral: CBPeripheral, didDiscoverServices error: (any Error)?) {
        if let error = error {
            bluetoothState = String(format: "Error discovering services: $s", error.localizedDescription)
            return
        }
        
        guard let peripheralService = peripheral.services else { return }
        
        for service in peripheralService {
            peripheral.discoverCharacteristics([TargetService.characteristicUUID], for: service)
        }
    }
    
    func peripheral(_ peripheral: CBPeripheral, didModifyServices invalidatedServices: [CBService]) {
        for service in invalidatedServices where service.uuid == TargetService.serviceUUID {
            peripheral.discoverServices([TargetService.serviceUUID])
        }
    }
    
    func peripheral(_ peripheral: CBPeripheral, didDiscoverCharacteristicsFor service: CBService, error: (any Error)?) {
        if let error = error {
            bluetoothState = String(format: "Error discovering cgaracteristics: %s", String(describing: error))
            cleanUp()
            return
        }
        
        guard let serviceCharacteristics = service.characteristics else { return }
        
        for characteristic in serviceCharacteristics where characteristic.uuid == TargetService.characteristicUUID {
            targetCharacteristic = characteristic
            peripheral.setNotifyValue(true, for: characteristic)
        }
        
    }
    
    func peripheral(_ peripheral: CBPeripheral, didUpdateValueFor characteristic: CBCharacteristic, error: (any Error)?) {
        if let error = error {
            bluetoothState = String(format: "Error discovering characteristics %s", error.localizedDescription)
            cleanUp()
            return
        }
        
        guard
            let characteristicData = characteristic.value,
            let stringFromData = String(data: characteristicData, encoding: .utf8)
        else { return }
        
        bluetoothState = String(format: "Received %d bytes: %s", characteristicData.count, stringFromData)
        
        if
            stringFromData == "EOM",
            let text = String(data: self.data, encoding: .utf8)
        {
            self.characteristicText = text
            writeData()
        } else {
            data.append(characteristicData)
        }
    }
    
    func peripheral(_ peripheral: CBPeripheral, didUpdateNotificationStateFor characteristic: CBCharacteristic, error: (any Error)?) {
        if let error = error {
            bluetoothState = String(format: "Error changing notification state: %s", error.localizedDescription)
            return
        }
        
        guard characteristic.uuid == TargetService.characteristicUUID else { return }
        
        if characteristic.isNotifying {
            bluetoothState = String(format: "Notification began on %@", characteristic)
        } else {
            bluetoothState = String(format: "Notification stopped on %@. Disconnecting", characteristic)
            cleanUp()
        }
    }
    
    func peripheralIsReady(toSendWriteWithoutResponse peripheral: CBPeripheral) {
        bluetoothState = "Peripheral is ready, send data"
        writeData()
    }
    
}
