//
//  MockBundle.swift
//  SwiftyReceiptValidatorTests
//
//  Created by Dominik Ringler on 18/01/2020.
//  Copyright © 2020 Dominik. All rights reserved.
//

import Foundation

final class MockBundle: Bundle {
    struct Stub {
        var bundleIdentifier: String = "test.com"
    }
    
    var stub = Stub()
    
    override var bundleIdentifier: String? {
        stub.bundleIdentifier
    }
}
