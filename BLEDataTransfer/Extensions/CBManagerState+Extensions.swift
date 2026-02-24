//
//  CBManagerState+Extensions.swift
//  BLEDataTransfer
//
//  Created by SAfonja on 2/23/26.
//

import CoreBluetooth
import Foundation

extension CBManagerState {
    var description: String {
        switch self {
        case .unknown:
            return "CBManager state is unknown"
        case .resetting:
            return "CBManager is resetting"
        case .unsupported:
            return "Bluetooth is not supported on this device"
        case .unauthorized:
            return "You are not authorized to use Bluetooth"
        case .poweredOff:
            return "CBManager is not powered on"
        case .poweredOn:
            return "CBManager is powered on"
        @unknown default:
            return "Unknown CBManager state"
        }
    }
}
