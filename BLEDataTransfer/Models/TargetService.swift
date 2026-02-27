//
//  TargetService.swift
//  BLEDataTransfer
//
//  Created by SAfonja on 2/23/26.
//

import CoreBluetooth
import Foundation

struct TargetService {
    static let serviceUUID = CBUUID(string: "DB5B50F4-43DC-756B-0E84-07D9D2DBDB5C")
    static let characteristicUUID = CBUUID(string: "87654321-E5F6-7890-1234-56789ABCDEF0")
}
