//
//  SwiftyReceiptValidatorTests.swift
//  SwiftyReceiptValidatorTests
//
//  Created by Dominik Ringler on 27/02/2019.
//  Copyright © 2019 Dominik. All rights reserved.
//

import XCTest
import Combine
@testable import SwiftyReceiptValidator

class SwiftyReceiptValidatorTests: XCTestCase {
    
    // MARK: - Properties
    
    private(set) var receiptFetcher: MockReceiptFetcher!
    private(set) var sessionManager: MockSessionManager!
    private(set) var responseValidator: MockResponseValidator!
    
    // MARK: - Computed Properties
    
    var expectation: XCTestExpectation {
        XCTestExpectation(description: "Expectation Succeeded")
    }
    
    // MARK: - Life Cycle
    
    override func setUp() {
        super.setUp()
        receiptFetcher = MockReceiptFetcher()
        sessionManager = MockSessionManager()
        responseValidator = MockResponseValidator()
    }

    override func tearDown() {
        receiptFetcher = nil
        sessionManager = nil
        responseValidator = nil
        super.tearDown()
    }
    
    // MARK: - Tests

    // MARK: Config
    
    func test_config() {
        let expectedConfiguration: SRVConfiguration = .standard
        let sut = makeSUT(configuration: expectedConfiguration)
        XCTAssertEqual(sut.configuration, expectedConfiguration)
    }
    
    // MARK: Validate Purchase
    
    func test_validPurchase_success_returnsCorrectData() {
        let expectation = self.expectation
        let sut = makeSUT()
        let expectedResponse: SRVReceiptResponse = .mock()
        sessionManager.stub.start = .success(expectedResponse)
        responseValidator.stub.validatePurchaseResult = .success(expectedResponse)
        sut.validatePurchase(forId: "123", sharedSecret: nil) { result in
            if case .success(let response) = result {
                XCTAssertEqual(response, expectedResponse)
                expectation.fulfill()
            }
        }
        wait(for: [expectation], timeout: 0.1)
    }
    
    func test_validPurchase_failure_receiptFetcher_returnsCorrectError() {
        let expectation = self.expectation
        let sut = makeSUT()
        let expectedError = URLError(.notConnectedToInternet)
        receiptFetcher.stub.fetchResult = .failure(expectedError)
        sut.validatePurchase(forId: "123", sharedSecret: nil) { result in
            if case .failure(let error) = result {
                XCTAssertEqual(error.localizedDescription, expectedError.localizedDescription)
                expectation.fulfill()
            }
        }
        
        wait(for: [expectation], timeout: 0.1)
    }
    
    func test_validPurchase_failure_sessionManager_returnsCorrectError() {
        let expectation = self.expectation
        let sut = makeSUT()
        let expectedError = URLError(.notConnectedToInternet)
        sessionManager.stub.start = .failure(expectedError)
        sut.validatePurchase(forId: "123", sharedSecret: nil) { result in
            if case .failure(let error) = result {
                XCTAssertEqual(error.localizedDescription, expectedError.localizedDescription)
                expectation.fulfill()
            }
        }
        
        wait(for: [expectation], timeout: 0.1)
    }
    
    func test_validPurchase_failure_responseValidator_returnsCorrectError() {
        let expectation = self.expectation
        let sut = makeSUT()
        let expectedError: SRVError = .productIdNotMatching(.unknown)
        responseValidator.stub.validatePurchaseResult = .failure(expectedError)
        sut.validatePurchase(forId: "123", sharedSecret: nil) { result in
            if case .failure(let error) = result {
                XCTAssertEqual(error.localizedDescription, expectedError.localizedDescription)
                expectation.fulfill()
            }
        }
        
        wait(for: [expectation], timeout: 0.1)
    }
    
    // MARK: Validate Subscription
    
    func test_validSubscription_success_returnsCorrectData() {
        let expectation = self.expectation
        let sut = makeSUT()
        let expectedReceiptResponse: SRVReceiptResponse = .mock()
        let expectedValidationResponse: SRVSubscriptionValidationResponse = .mock(
            validReceipts: expectedReceiptResponse.validSubscriptionReceipts,
            pendingRenewalInfo: expectedReceiptResponse.pendingRenewalInfo ?? []
        )
        sessionManager.stub.start = .success(expectedReceiptResponse)
        responseValidator.stub.validateSubscriptionResult = .success(expectedReceiptResponse)
        sut.validateSubscription(sharedSecret: "abc",
                                 refreshLocalReceiptIfNeeded: false,
                                 excludeOldTransactions: false) { result in
            if case .success(let response) = result {
                XCTAssertEqual(response, expectedValidationResponse)
                expectation.fulfill()
            }
        }
        
        wait(for: [expectation], timeout: 0.1)
    }
    
    func test_validSubscription_failure_receiptFetcher_returnsCorrectError() {
        let expectation = self.expectation
        let sut = makeSUT()
        let expectedError = URLError(.notConnectedToInternet)
        receiptFetcher.stub.fetchResult = .failure(expectedError)
        sut.validateSubscription(sharedSecret: "abc",
                                 refreshLocalReceiptIfNeeded: false,
                                 excludeOldTransactions: false) { result in
            if case .failure(let error) = result {
                XCTAssertEqual(error.localizedDescription, expectedError.localizedDescription)
                expectation.fulfill()
            }
        }
        
        wait(for: [expectation], timeout: 0.1)
    }
    
    func test_validSubscription_failure_sessionManager_returnsCorrectError() {
        let expectation = self.expectation
        let sut = makeSUT()
        let expectedError = URLError(.notConnectedToInternet)
        sessionManager.stub.start = .failure(expectedError)
        sut.validateSubscription(sharedSecret: "abc",
                                 refreshLocalReceiptIfNeeded: false,
                                 excludeOldTransactions: false) { result in
            if case .failure(let error) = result {
                XCTAssertEqual(error.localizedDescription, expectedError.localizedDescription)
                expectation.fulfill()
            }
        }
        
        wait(for: [expectation], timeout: 0.1)
    }
    
    func test_validSubscription_failure_responseValidator_returnsCorrectError() {
        let expectation = self.expectation
        let sut = makeSUT()
        let expectedError = URLError(.notConnectedToInternet)
        responseValidator.stub.validateSubscriptionResult = .failure(.other(expectedError))
        sut.validateSubscription(sharedSecret: "abc",
                                 refreshLocalReceiptIfNeeded: false,
                                 excludeOldTransactions: false) { result in
            if case .failure(let error) = result {
                XCTAssertEqual(error.localizedDescription, expectedError.localizedDescription)
                expectation.fulfill()
            }
        }
        
        wait(for: [expectation], timeout: 0.1)
    }
    
    // MARK: Fetch
    
    func test_fetch_success_returnsCorrectData() {
        let expectation = self.expectation
        let sut = makeSUT()
        let expectedResponse: SRVReceiptResponse = .mock()
        sessionManager.stub.start = .success(expectedResponse)
        sut.fetch(sharedSecret: nil, refreshLocalReceiptIfNeeded: false, excludeOldTransactions: false) { result in
            if case .success(let response) = result {
                XCTAssertEqual(response, expectedResponse)
                expectation.fulfill()
            }
        }
        
        wait(for: [expectation], timeout: 0.1)
    }
    
    func test_fetch_failure_receiptFetcher_returnsCorrectError() {
        let expectation = self.expectation
        let sut = makeSUT()
        let expectedError = URLError(.notConnectedToInternet)
        receiptFetcher.stub.fetchResult = .failure(expectedError)
        sut.fetch(sharedSecret: nil, refreshLocalReceiptIfNeeded: false, excludeOldTransactions: false) { result in
            if case .failure(let error) = result {
                XCTAssertEqual(error.localizedDescription, expectedError.localizedDescription)
                expectation.fulfill()
            }
        }
        
        wait(for: [expectation], timeout: 0.1)
    }
    
    func test_fetch_failure_sessionManager_returnsCorrectError() {
        let expectation = self.expectation
        let sut = makeSUT()
        let expectedError = URLError(.notConnectedToInternet)
        sessionManager.stub.start = .failure(expectedError)
        sut.fetch(sharedSecret: nil, refreshLocalReceiptIfNeeded: false, excludeOldTransactions: false) { result in
            if case .failure(let error) = result {
                XCTAssertEqual(error.localizedDescription, expectedError.localizedDescription)
                expectation.fulfill()
            }
        }
        
        wait(for: [expectation], timeout: 0.1)
    }
}

// MARK: - Internal Methods

extension SwiftyReceiptValidatorTests {
    
    func makeSUT(configuration: SRVConfiguration = .standard) -> SwiftyReceiptValidator {
        SwiftyReceiptValidator(
            configuration: configuration,
            receiptFetcher: receiptFetcher,
            sessionManager: sessionManager,
            responseValidator: responseValidator
        )
    }
}
