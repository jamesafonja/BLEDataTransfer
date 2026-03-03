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
    @Published var text: String = ""
    @Published var isOn: Bool = false
    
    private let manager: BLEPeripheralManager
    
    weak var delegate: BLEPeripheralManagerDelegate?
    
    init(manager: BLEPeripheralManager) {
        self.manager = manager
    }
    
}

extension PeripheralViewModel: BLEPeripheralManagerDelegate {
    func didUpdateState(isOn: Bool) {
        self.isOn = isOn
    }
    
    func didSubscribe(to peripheral: CBPeripheralManager, central: CBCentral, characteristic: CBCharacteristic) {
        //
    }
    
    func didUnsubscribe(from peripheral: CBPeripheralManager, central: CBCentral, characteristic: CBCharacteristic) {
        //
    }
    
    func managerIsReadyToUpdate(subscribers: CBPeripheralManager) {
        //
    }
    
    func didReceiveWrite(peripheralManager: CBPeripheralManager, requests: [CBATTRequest]) {
        //
    }
    
    
}
