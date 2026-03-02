//
//  BLECentralManagerTests.swift
//  BLEDataTransferTests
//
//  Created by SAfonja on 3/1/26.
//

import XCTest
@testable import BLEDataTransfer

final class BLECentralManagerTests: XCTestCase {
    var manager: BLECentralManager?
    
    override func setUp() {
        manager = BLECentralManager()
    }
    
    override func tearDown() {
        manager = nil
    }
    
    func testManagerNotNil() {
        XCTAssertNotNil(manager)
    }
    
    
}
