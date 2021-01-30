//
//  ReceiptValidatorTests.swift
//  SwiftyReceiptValidatorTests
//
//  Created by Dominik Ringler on 27/02/2019.
//  Copyright © 2019 Dominik. All rights reserved.
//

import XCTest
import Combine
@testable import SwiftyReceiptValidator

class ReceiptValidatorTests: XCTestCase {
    
    // MARK: - Properties
    
    private(set) var receiptURLFetcher: MockReceiptURLFetcher!
    private(set) var receiptClient: MockReceiptClient!
    private(set) var responseValidator: MockResponseValidator!
    
    // MARK: - Life Cycle
    
    override func setUp() {
        super.setUp()
        receiptURLFetcher = MockReceiptURLFetcher()
        receiptClient = MockReceiptClient()
        responseValidator = MockResponseValidator()
    }

    override func tearDown() {
        receiptURLFetcher = nil
        receiptClient = nil
        responseValidator = nil
        super.tearDown()
    }
    
    // MARK: - Tests

    // MARK: Validate Purchase
    
    func test_validatePurchase_success_returnsCorrectData() {
        let expectation = self.expectation(description: "Finished")
        let expectedResponse: SRVReceiptResponse = .mock()
        receiptClient.stub.validateResult = { (_, _, _) in .success(expectedResponse) }
        responseValidator.stub.validatePurchaseResult = { (_, _) in .success(expectedResponse) }
        let request = SRVPurchaseValidationRequest(
            productId: "123",
            sharedSecret: "secret"
        )
        
        let sut = makeSUT()
        sut.validate(request) { result in
            if case .success(let response) = result {
                XCTAssertEqual(response, expectedResponse)
                expectation.fulfill()
            }
        }
        
        waitForExpectations(timeout: 0.1)
    }
    
    func test_validatePurchase_failure_receiptFetcher_returnsCorrectError() {
        let expectation = self.expectation(description: "Finished")
        let expectedError = URLError(.notConnectedToInternet)
        receiptURLFetcher.stub.fetchResult = { _ in .failure(.other(expectedError)) }
        let request = SRVPurchaseValidationRequest(
            productId: "123",
            sharedSecret: "secret"
        )
        
        let sut = makeSUT()
        sut.validate(request) { result in
            if case .failure(let error) = result {
                XCTAssertEqual(error.localizedDescription, expectedError.localizedDescription)
                expectation.fulfill()
            }
        }
        
        waitForExpectations(timeout: 0.1)
    }
    
    func test_validatePurchase_failure_receiptClient_returnsCorrectError() {
        let expectation = self.expectation(description: "Finished")
        let expectedError = URLError(.notConnectedToInternet)
        receiptClient.stub.validateResult = { (_, _, _) in .failure(.other(expectedError)) }
        let request = SRVPurchaseValidationRequest(
            productId: "123",
            sharedSecret: "secret"
        )
        
        let sut = makeSUT()
        sut.validate(request) { result in
            if case .failure(let error) = result {
                XCTAssertEqual(error.localizedDescription, expectedError.localizedDescription)
                expectation.fulfill()
            }
        }
        
        waitForExpectations(timeout: 0.1)
    }
    
    func test_validatePurchase_failure_responseValidator_returnsCorrectError() {
        let expectation = self.expectation(description: "Finished")
        let expectedError: SRVError = .productIdNotMatching(.unknown)
        responseValidator.stub.validatePurchaseResult = { (_, _) in .failure(expectedError) }
        let request = SRVPurchaseValidationRequest(
            productId: "123",
            sharedSecret: "secret"
        )
        
        let sut = makeSUT()
        sut.validate(request) { result in
            if case .failure(let error) = result {
                XCTAssertEqual(error.localizedDescription, expectedError.localizedDescription)
                expectation.fulfill()
            }
        }
        
        waitForExpectations(timeout: 0.1)
    }
    
    // MARK: Validate Subscription
    
    func test_validateSubscription_success_returnsCorrectData() {
        let expectation = self.expectation(description: "Finished")
        let expectedReceiptResponse: SRVReceiptResponse = .mock()
        let expectedValidationResponse: SRVSubscriptionValidationResponse = .mock(
            validReceipts: expectedReceiptResponse.validSubscriptionReceipts(now: .test),
            receiptResponse: expectedReceiptResponse
        )
        receiptClient.stub.validateResult = { (_, _, _) in .success(expectedReceiptResponse) }
        responseValidator.stub.validateSubscriptionResult = { (_, _) in .success(expectedValidationResponse) }
        let request = SRVSubscriptionValidationRequest(
            sharedSecret: "secret",
            refreshLocalReceiptIfNeeded: false,
            excludeOldTransactions: false,
            now: .test
        )
        
        let sut = makeSUT()
        sut.validate(request) { result in
            if case .success(let response) = result {
                XCTAssertEqual(response, expectedValidationResponse)
                expectation.fulfill()
            }
        }
        
        waitForExpectations(timeout: 0.1)
    }
    
    func test_validateSubscription_failure_receiptFetcher_returnsCorrectError() {
        let expectation = self.expectation(description: "Finished")
        let expectedError = URLError(.notConnectedToInternet)
        receiptURLFetcher.stub.fetchResult = { _ in .failure(.other(expectedError)) }
        let request = SRVSubscriptionValidationRequest(
            sharedSecret: "secret",
            refreshLocalReceiptIfNeeded: false,
            excludeOldTransactions: false,
            now: .test
        )
        
        let sut = makeSUT()
        sut.validate(request) { result in
            if case .failure(let error) = result {
                XCTAssertEqual(error.localizedDescription, expectedError.localizedDescription)
                expectation.fulfill()
            }
        }
        
        waitForExpectations(timeout: 0.1)
    }
    
    func test_validateSubscription_failure_receiptClient_returnsCorrectError() {
        let expectation = self.expectation(description: "Finished")
        let expectedError = URLError(.notConnectedToInternet)
        receiptClient.stub.validateResult = { (_, _, _) in .failure(.other(expectedError)) }
        let request = SRVSubscriptionValidationRequest(
            sharedSecret: "secret",
            refreshLocalReceiptIfNeeded: false,
            excludeOldTransactions: false,
            now: .test
        )
        
        let sut = makeSUT()
        sut.validate(request) { result in
            if case .failure(let error) = result {
                XCTAssertEqual(error.localizedDescription, expectedError.localizedDescription)
                expectation.fulfill()
            }
        }
        
        waitForExpectations(timeout: 0.1)
    }
    
    func test_validateSubscription_failure_responseValidator_returnsCorrectError() {
        let expectation = self.expectation(description: "Finished")
        let expectedError = URLError(.notConnectedToInternet)
        responseValidator.stub.validateSubscriptionResult = { (_, _) in .failure(.other(expectedError)) }
        let request = SRVSubscriptionValidationRequest(
            sharedSecret: "secret",
            refreshLocalReceiptIfNeeded: false,
            excludeOldTransactions: false,
            now: .test
        )
        
        let sut = makeSUT()
        sut.validate(request) { result in
            if case .failure(let error) = result {
                XCTAssertEqual(error.localizedDescription, expectedError.localizedDescription)
                expectation.fulfill()
            }
        }
        
        waitForExpectations(timeout: 0.1)
    }
}

// MARK: - Internal Methods

extension ReceiptValidatorTests {
    
    func makeSUT(configuration: SRVConfiguration = .standard) -> SwiftyReceiptValidator {
        SwiftyReceiptValidator(
            configuration: configuration,
            receiptURLFetcher: receiptURLFetcher,
            receiptClient: receiptClient,
            responseValidator: responseValidator
        )
    }
}
