//
//  PeripheralViewModel.swift
//  BLEDataTransfer
//
//  Created by SAfonja on 3/1/26.
//

import Combine
import CoreBluetooth
import SwiftUI

@MainActor
final class PeripheralViewModel: ObservableObject {
    @Published var receivedText: String = ""
    @Published var text: String = ""
    @Published var displayText: String = ""
    @Published private(set) var state: BLEPeripheralManager.PeripheralState = .off
    
    private let manager: BLEPeripheralManager
    
    weak var delegate: BLEPeripheralManagerDelegate?
    
    init(manager: BLEPeripheralManager) {
        self.manager = manager
        manager.delegate = self
    }
    
    func sendData() {
        guard let data = text.data(using: .utf8) else { return }
        manager.send(data)
    }
    
    func stopAdvertising() {
        manager.stopAdvertising()
    }
    
}

extension PeripheralViewModel: BLEPeripheralManagerDelegate {
    
    func didSubscribe(to peripheral: CBPeripheralManager, central: CBCentral, characteristic: CBCharacteristic) {
        sendData()
    }
    
    func didUnsubscribe(from peripheral: CBPeripheralManager, central: CBCentral, characteristic: CBCharacteristic) {
        
        print("Unsubscribed from characteristic")
    }
    
    func managerIsReadyToUpdate(subscribers: CBPeripheralManager) {
        sendData()
    }
    
    func didReceiveWrite(peripheralManager: CBPeripheralManager, requests: [CBATTRequest]) {
        for request in requests {
            guard
                let value = request.value,
                let stringFromData = String(data: value, encoding: .utf8)
            else {
                print("Failed to retrieve write data")
                return
            }
            
            displayText = stringFromData
        }
    }
    
    func peripheralDidChange(state: BLEPeripheralManager.PeripheralState) {
        self.state = state
    }
}
