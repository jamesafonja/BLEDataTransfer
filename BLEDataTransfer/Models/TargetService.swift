//
//  TargetService.swift
//  BLEDataTransfer
//
//  Created by SAfonja on 2/23/26.
//

import CoreBluetooth
import Foundation

struct TargetService {
    static let serviceUUID = CBUUID(string: "12345678-E5F6-7890-1234-56789ABCDEF0")
    static let characteristicUUID = CBUUID(string: "87654321-E5F6-7890-1234-56789ABCDEF0")
}
