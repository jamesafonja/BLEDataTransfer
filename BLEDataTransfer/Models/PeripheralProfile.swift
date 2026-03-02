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
    let peripheral: CBPeripheral?
}

extension PeripheralProfile {
    static var sample: PeripheralProfile {
        PeripheralProfile(
            id: UUID(uuidString: "DB5B50F4-43DC-756B-0E84-07D9D2DBDB5C")!,
            name: "Temperature Sensor",
            rssi: -25,
            peripheral: nil
        )
    }
}
