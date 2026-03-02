//
//  BLEPeripheralManager.swift
//  BLEDataTransfer
//
//  Created by SAfonja on 3/1/26.
//

import CoreBluetooth

protocol BLEPeripheralDelegate: AnyObject {
    func didUpdateState(isOn: Bool)
    func didSubscribe(to peripheral: CBPeripheralManager, central: CBCentral, characteristic: CBCharacteristic)
    func didUnsubscribe(from peripheral: CBPeripheralManager, central: CBCentral, characteristic: CBCharacteristic)
    func managerIsReadyToUpdate(subscribers: CBPeripheralManager)
    
}

final class BLEPeripheralManager: NSObject {
    weak var delegate: BLEPeripheralDelegate?
    
    private var peripheralManager: CBPeripheralManager!
    var transferCharacteristic: CBMutableCharacteristic?
    var dataToSend: Data = Data()
    var sendDataIndex: Int = 0
    var connectedCentral: CBCentral?
    
    var isSendingEOM: Bool = false
    
    override init() {
        super.init()
        
        peripheralManager = CBPeripheralManager(
            delegate: self,
            queue: nil,
            options: [CBPeripheralManagerOptionShowPowerAlertKey: true]
        )
    }
    
    func startAdvertising() {
        if peripheralManager.state == .poweredOn {
            peripheralManager.startAdvertising([CBAdvertisementDataServiceUUIDsKey: [TargetService.serviceUUID]])
        } else {
            peripheralManager.stopAdvertising()
        }
    }
    
    private func sendData() {
        guard let transferCharacteristic = transferCharacteristic else { return }
        
        if
            self.isSendingEOM,
            let value = "EOM".data(using: .utf8)
        {
            let didSend = peripheralManager.updateValue(value, for: transferCharacteristic, onSubscribedCentrals: nil)
            
            if didSend {
                isSendingEOM = false
            }
            return
        }
        
        if sendDataIndex >= dataToSend.count { return }
        var didSend = true
        
        while didSend {
            var amountToSend = dataToSend.count - sendDataIndex
            
            if let mtu = connectedCentral?.maximumUpdateValueLength {
                amountToSend = min(amountToSend, mtu)
            }
            
            let chunk = dataToSend.subdata(in: sendDataIndex..<(sendDataIndex + amountToSend))
            
            didSend = peripheralManager.updateValue(chunk, for: transferCharacteristic, onSubscribedCentrals: nil)
            
            if !didSend { return }
            
            let stringFromData = String(data: chunk, encoding: .utf8)
            print("Send \(chunk.count) bytes: \(String(describing: stringFromData))")
            
            sendDataIndex += amountToSend
            
            if sendDataIndex >= dataToSend.count {
                isSendingEOM = true
                
                guard let value = "EOM".data(using: .utf8) else { return }
                
                let eomSent = peripheralManager.updateValue(value, for: transferCharacteristic, onSubscribedCentrals: nil)
                        
                if eomSent {
                    isSendingEOM = false
                }
                
                return
            }
        }
    }
    
    private func setupPeripheral() {
        let transferCharacteristic = CBMutableCharacteristic(
            type: TargetService.serviceUUID,
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

extension BLEPeripheralManager: CBPeripheralManagerDelegate {
    
    func peripheralManagerDidUpdateState(_ peripheral: CBPeripheralManager) {
        delegate?.didUpdateState(isOn: peripheral.state == .poweredOn)
    }
    
    func peripheralManager(_ peripheral: CBPeripheralManager, central: CBCentral, didSubscribeTo characteristic: CBCharacteristic) {
        delegate?.didSubscribe(to: peripheral, central: central, characteristic: characteristic)
    }
    
    func peripheralManager(_ peripheral: CBPeripheralManager, central: CBCentral, didUnsubscribeFrom characteristic: CBCharacteristic) {
        delegate?.didUnsubscribe(from: peripheral, central: central, characteristic: characteristic)
    }
    
    func peripheralManagerIsReady(toUpdateSubscribers peripheral: CBPeripheralManager) {
        delegate?.managerIsReadyToUpdate(subscribers: peripheral)
    }
    
}
