//
//  TestCase.swift
//  
//
//  Created by Vasyl Ahosta on 04.10.2020.
//

import XCTest

class TestCase: XCTestCase {
    
    override func setUp() {
        super.setUp()
        continueAfterFailure = false
    }
    
    override func setUpWithError() throws {
        try super.setUpWithError()
        continueAfterFailure = false
    }
}

