//
//  DiscoveredPeripheral.swift
//  BLEDataTransfer
//
//  Created by SAfonja on 2/27/26.
//

import CoreBluetooth
import Foundation

struct PeripheralProfile: Identifiable {
    let id: UUID
    let name: String
    var rssi: Int
    let peripheral: CBPeripheral
}
