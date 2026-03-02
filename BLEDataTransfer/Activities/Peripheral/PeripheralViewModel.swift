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
    
    private let manager: BLEPeripheralManager
    
    init(manager: BLEPeripheralManager) {
        self.manager = manager
    }
    
}
