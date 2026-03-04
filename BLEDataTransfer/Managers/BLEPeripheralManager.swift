//
//  BLEPeripheralManager.swift
//  BLEDataTransfer
//
//  Created by SAfonja on 3/1/26.
//

import CoreBluetooth

// MARK: - BLEPeripheralManagerDelegate

protocol BLEPeripheralManagerDelegate: AnyObject {
    func didSubscribe(to peripheral: CBPeripheralManager, central: CBCentral, characteristic: CBCharacteristic)
    func didUnsubscribe(from peripheral: CBPeripheralManager, central: CBCentral, characteristic: CBCharacteristic)
    func managerIsReadyToUpdate(subscribers: CBPeripheralManager)
    func didReceiveWrite(peripheralManager: CBPeripheralManager, requests: [CBATTRequest])
    func peripheralDidChange(state: BLEPeripheralManager.PeripheralState)

}

// MARK: - BLEPeripheralManager

final class BLEPeripheralManager: NSObject {
    weak var delegate: BLEPeripheralManagerDelegate?
    
    private var peripheralManager: CBPeripheralManager!
    var transferCharacteristic: CBMutableCharacteristic?
    var sendDataIndex: Int = 0
    var connectedCentral: CBCentral?
    var isSendingEOM: Bool = false

    private(set) var state: PeripheralState = .idle {
        didSet {
            delegate?.peripheralDidChange(state: state)
        }
    }
    
    override init() {
        super.init()
        
        peripheralManager = CBPeripheralManager(
            delegate: self,
            queue: nil,
            options: [CBPeripheralManagerOptionShowPowerAlertKey: true]
        )
    }
    
    func startAdvertising() {
        guard peripheralManager.state == .poweredOn else {
            state = .off
            return
        }
        
        peripheralManager.startAdvertising([CBAdvertisementDataServiceUUIDsKey: [TargetService.serviceUUID]])
        state = .advertising
    }
    
    func stopAdvertising() {
        peripheralManager.stopAdvertising()
        state = .idle
    }
    
    func send(_ data: Data) {
        guard let transferCharacteristic = transferCharacteristic else { return }
        
        if
            self.isSendingEOM,
            let value = "EOM".data(using: .utf8)
        {
            let didSend = peripheralManager.updateValue(value, for: transferCharacteristic, onSubscribedCentrals: nil)
            
            if didSend {
                isSendingEOM = false
                sendDataIndex = 0
            }
            
            return
        }
        
        if sendDataIndex >= data.count { return }
        
        var didSend = true
        
        while didSend {
            var amountToSend = data.count - sendDataIndex
            
            if let mtu = connectedCentral?.maximumUpdateValueLength {
                amountToSend = min(amountToSend, mtu)
            }
            
            let chunk = data.subdata(in: sendDataIndex..<(sendDataIndex + amountToSend))
            
            didSend = peripheralManager.updateValue(chunk, for: transferCharacteristic, onSubscribedCentrals: nil)
            
            if !didSend { return }
            
            let stringFromData = String(data: chunk, encoding: .utf8)
            print("Send \(chunk.count) bytes: \(String(describing: stringFromData))")
            
            sendDataIndex += amountToSend
            
            if sendDataIndex >= data.count {
                isSendingEOM = true
                
                guard let value = "EOM".data(using: .utf8) else { return }
                
                let eomSent = peripheralManager.updateValue(value, for: transferCharacteristic, onSubscribedCentrals: nil)
                        
                if eomSent {
                    isSendingEOM = false
                    sendDataIndex = 0
                }
                
                return
            }
        }
    }
    
    private func setupPeripheral() {
        let transferCharacteristic = CBMutableCharacteristic(
            type: TargetService.characteristicUUID,
            properties: [.notify, .writeWithoutResponse],
            value: nil,
            permissions: [.readable, .writeable]
        )
        
        let transferService = CBMutableService(type: TargetService.serviceUUID, primary: true)
        transferService.characteristics = [transferCharacteristic]
        peripheralManager.add(transferService)
        
        self.transferCharacteristic = transferCharacteristic
    }
}

// MARK: - BLEPeripheralManager extension

extension BLEPeripheralManager {
    enum PeripheralState {
        case advertising
        case idle
        case off
        case subscribed
        
        var message: String {
            switch self {
            case .advertising:
                return "📡 Advertising"
            case .idle:
                return "🌙 Idle"
            case .off:
                return "❌ Off"
            case .subscribed:
                return "🤝 Subscribed"
            }
        }
    }
}

// MARK: - BLEPeripheralManager - CBPeripheralManagerDelegate

extension BLEPeripheralManager: CBPeripheralManagerDelegate {
    
    func peripheralManagerDidUpdateState(_ peripheral: CBPeripheralManager) {
        switch peripheral.state {
        case .poweredOn:
            setupPeripheral()
            state = .idle
        default:
            state = .off
        }
    }
    
    func peripheralManager(_ peripheral: CBPeripheralManager, central: CBCentral, didSubscribeTo characteristic: CBCharacteristic) {
        state = .subscribed

        sendDataIndex = 0
        connectedCentral = central
        delegate?.didSubscribe(to: peripheral, central: central, characteristic: characteristic)
    }
    
    func peripheralManager(_ peripheral: CBPeripheralManager, central: CBCentral, didUnsubscribeFrom characteristic: CBCharacteristic) {
        connectedCentral = nil
        
        if !peripheral.isAdvertising {
            peripheral.startAdvertising([CBAdvertisementDataServiceUUIDsKey: [TargetService.serviceUUID]])
        }
        
        state = .advertising
        delegate?.didUnsubscribe(from: peripheral, central: central, characteristic: characteristic)
    }
    
    func peripheralManagerIsReady(toUpdateSubscribers peripheral: CBPeripheralManager) {
        delegate?.managerIsReadyToUpdate(subscribers: peripheral)
    }
    
    func peripheralManager(_ peripheral: CBPeripheralManager, didReceiveWrite requests: [CBATTRequest]) {
        delegate?.didReceiveWrite(peripheralManager: peripheral, requests: requests)
    }
    
}
