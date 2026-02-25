//
//  TargetService.swift
//  BLEDataTransfer
//
//  Created by SAfonja on 2/23/26.
//

import CoreBluetooth
import Foundation

struct TargetService {
    static let serviceUUID = CBUUID(string: "TargetServiceCBUUID")
    static let characteristicUUID = CBUUID(string: "TargetCharacteristicCBUUID")
}
