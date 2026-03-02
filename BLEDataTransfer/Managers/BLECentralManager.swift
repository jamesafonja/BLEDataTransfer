//
//  BLECentralManager.swift
//  BLEDataTransfer
//
//  Created by SAfonja on 2/23/26.
//

import Combine
import CoreBluetooth

// MARK: - BLECentralManager

protocol BLECentralManagerDelegate: AnyObject {
    func didUpdateState(isOn: Bool)
    func didDiscover(peripheral: CBPeripheral, rssi: Int)
    func didFailToConnect(peripheral: CBPeripheral, error: (any Error)?)
    func didConnect(peripheral: CBPeripheral)
}

// MARK: - CentralManagerProtocol

protocol CentralManagerProtocol {
    func startScanning()
    func stopScanning()
}

// MARK: - BLECentralManager

final class BLECentralManager: NSObject, CentralManagerProtocol {
    weak var delegate: BLECentralManagerDelegate?
    
    private var centralManager: CBCentralManager!
    private var selectedPeripheral: CBPeripheral?
    private var targetCharacteristic: CBCharacteristic?
    private var connectedPeripherals: [CBPeripheral] = []
    private var data = Data()
    
    override init() {
        super.init()
        
        centralManager = CBCentralManager(delegate: self, queue: nil, options: [CBCentralManagerOptionShowPowerAlertKey: true])
    }
        
    var writeIterationsComplete: Int = 0
    var connectionIterationsComplete: Int = 0
    var maxIterations: Int = 5
    
    var connectionAttempts: Int = 0
    let maxConnectionRetries: Int = 5
    
    func getPeripheral() {
        // Retrieve only peripherals that meet a known service criteria
        connectedPeripherals = centralManager.retrieveConnectedPeripherals(withServices: [TargetService.serviceUUID])
        
        if let connectedPeripheral = connectedPeripherals.last {
            centralManager.connect(connectedPeripheral)
            self.selectedPeripheral = connectedPeripheral
        } else {
            // centralManager.scanForPeripherals(withServices: [TargetService.serviceUUID])
            centralManager.scanForPeripherals(withServices: nil, options: [CBCentralManagerScanOptionAllowDuplicatesKey: false])
        }
    }
    
    func startScanning() {
        centralManager.scanForPeripherals(withServices: nil, options: [CBCentralManagerScanOptionAllowDuplicatesKey: false])
        
        DispatchQueue.main.asyncAfter(deadline: .now() + 5) {
            self.centralManager.stopScan()
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
    
    func stopScanning() {
        centralManager.stopScan()
        // bluetoothState = "Scanning stopped"
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
            // stringFromData = String(data: packetData, encoding: .utf8) ?? "Could not convert data"
            
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
        print("Current central state is: \(central.state.description)")
        
        delegate?.didUpdateState(isOn: central.state == .poweredOn)
        
        if central.state == .poweredOn {
            getPeripheral()
        }
    }
    
    func centralManager(
        _ central: CBCentralManager,
        didDiscover peripheral: CBPeripheral,
        advertisementData: [String : Any],
        rssi RSSI: NSNumber
    ) {
        guard RSSI.intValue >= -50 else { return }
        
        delegate?.didDiscover(peripheral: peripheral, rssi: RSSI.intValue)
    }
    
    func centralManager(_ central: CBCentralManager, didFailToConnect peripheral: CBPeripheral, error: (any Error)?) {
        delegate?.didFailToConnect(peripheral: peripheral, error: error)
        cleanUp()
    }
    
    func centralManager(_ central: CBCentralManager, didConnect peripheral: CBPeripheral) {
        print("Peripheral connected")
        centralManager.stopScan()
        // bluetoothState = "Scanning stopped"
        
        connectionIterationsComplete += 1
        writeIterationsComplete = 0
        
        data.removeAll(keepingCapacity: false)
        
        peripheral.delegate = self
        peripheral.discoverServices([TargetService.serviceUUID])
        
        delegate?.didConnect(peripheral: peripheral)
    }
    
    func centralManager(_ central: CBCentralManager, didDisconnectPeripheral peripheral: CBPeripheral, error: (any Error)?) {
        if let error = error {
            print(error.localizedDescription)
        }
        
        let delay = TimeInterval(connectionAttempts * 2) // Spacing out re-connection attempts
        
        if connectionAttempts < maxConnectionRetries {
            DispatchQueue.main.asyncAfter(deadline: .now() + delay) { [weak self] in
                guard central.state == .poweredOn else {
                    print("Unable to retry connection: central not powered on.")
                    return
                }

                self?.centralManager.connect(peripheral)
                self?.connectionAttempts += 1
            }
        }
    }
}

// MARK: - CBPeripheralDelegate

extension BLECentralManager: CBPeripheralDelegate {
        
    func peripheral(_ peripheral: CBPeripheral, didDiscoverServices error: (any Error)?) {
        if let error = error {
            // bluetoothState = "Error discovering services: \(error.localizedDescription)"
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
            // bluetoothState = "Error discovering characteristics: \(error.localizedDescription)"
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
            // bluetoothState = "Error discovering characteristics: \(error.localizedDescription)"
            cleanUp()
            return
        }
        
        guard
            let characteristicData = characteristic.value,
            let stringFromData = String(data: characteristicData, encoding: .utf8)
        else { return }
        
        // bluetoothState = "Received \(characteristicData.count) bytes: \(stringFromData)"
        
        if
            stringFromData == "EOM",
            let text = String(data: self.data, encoding: .utf8)
        {
            // self.characteristicText = text
            writeData()
        } else {
            data.append(characteristicData)
        }
    }
    
    func peripheral(_ peripheral: CBPeripheral, didUpdateNotificationStateFor characteristic: CBCharacteristic, error: (any Error)?) {
        if let error = error {
            // bluetoothState = "Error changing notification state: \(error.localizedDescription)"
            return
        }
        
        guard characteristic.uuid == TargetService.characteristicUUID else { return }
        
        if characteristic.isNotifying {
            // bluetoothState = "Notification began on \(characteristic)"
        } else {
            // bluetoothState = "Notification stopped on \(characteristic). Disconnecting..."
            cleanUp()
        }
    }
    
    func peripheralIsReady(toSendWriteWithoutResponse peripheral: CBPeripheral) {
        // bluetoothState = "Peripheral is ready, send data"
        writeData()
    }
    
}
