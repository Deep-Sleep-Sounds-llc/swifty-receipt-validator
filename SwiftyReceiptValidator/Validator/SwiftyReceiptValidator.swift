//
//  SwiftyReceiptValidator.swift
//  SwiftyReceiptValidator
//
//  Created by Dominik Ringler on 09/08/2017.
//  Copyright © 2017 Dominik. All rights reserved.
//

//    The MIT License (MIT)
//
//    Copyright (c) 2016-2018 Dominik Ringler
//
//    Permission is hereby granted, free of charge, to any person obtaining a copy
//    of this software and associated documentation files (the "Software"), to deal
//    in the Software without restriction, including without limitation the rights
//    to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
//    copies of the Software, and to permit persons to whom the Software is
//    furnished to do so, subject to the following conditions:
//
//    The above copyright notice and this permission notice shall be included in all
//    copies or substantial portions of the Software.
//
//    THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
//    IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
//    FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
//    AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
//    LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
//    OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
//    SOFTWARE.

import StoreKit

/*
 SwiftyReceiptValidator
 
 A class to manage in app purchase receipt validation.
 */
public final class SwiftyReceiptValidator: NSObject {
    public typealias ResultHandler = (Result<SwiftyReceiptResponse>) -> Void
    private typealias ReceiptHandler = (Result<URL>) -> Void
    
    // MARK: - Types
    
    /// Configuration
    public struct Configuration {
        let productionURL: String
        let sandboxURL: String
        let sessionConfiguration: URLSessionConfiguration
        
        public init(productionURL: String, sandboxURL: String, sessionConfiguration: URLSessionConfiguration) {
            self.productionURL = productionURL
            self.sandboxURL = sandboxURL
            self.sessionConfiguration = sessionConfiguration
        }
        
        // Defaults to apple validation only which is not recommended
        public static var standard: Configuration {
            return Configuration(productionURL: "https://buy.itunes.apple.com/verifyReceipt",
                                 sandboxURL: "https://sandbox.itunes.apple.com/verifyReceipt",
                                 sessionConfiguration: .default)
        }
    }
    
    // MARK: - Properties

    let sessionManager: SessionManager
    let configuration: Configuration
    
    private let receiptURL = Bundle.main.appStoreReceiptURL
    private var receiptHandler: ReceiptHandler?
    private var receiptRefreshRequest: SKReceiptRefreshRequest?
    
    private var hasReceipt: Bool {
        guard let path = receiptURL?.path, FileManager.default.fileExists(atPath: path) else { return false }
        return true
    }
    
    private(set) lazy var jsonDecoder: JSONDecoder = {
        let dateFormatter = DateFormatter()
        dateFormatter.calendar = Calendar(identifier: .iso8601)
        dateFormatter.locale = .current
        dateFormatter.dateFormat = "yyyy-MM-dd HH:mm:ss VV"
        
        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .formatted(dateFormatter)
        decoder.keyDecodingStrategy = .convertFromSnakeCase
        return decoder
    }()
  
    // MARK: - Init
    
    /// Init
    ///
    /// - parameter configuration: The configuration struct to customise SwiftyReceiptValidator.
    public init(configuration: Configuration) {
        print("Init SwiftyReceiptValidator")
        self.configuration = configuration
        sessionManager = SessionManager(sessionConfiguration: configuration.sessionConfiguration)
    }
    
    // MARK: - Deinit
    
    deinit {
        print("Deinit SwiftyReceiptValidator")
    }
    
    // MARK: - Validate Receipt
    
    /// Validate app store receipt
    ///
    /// - parameter validationMode: The validation method of receipt request.
    /// - parameter sharedSecret: The shared secret when using auto-subscriptions, setup in iTunes.
    /// - parameter excludeOldTransactions: If value is true, response includes only the latest renewal transaction for any subscriptions.
    /// - parameter handler: Completion handler called when the validation has completed.
    public func validate(_ validationMode: ValidationMode,
                         sharedSecret: String?,
                         excludeOldTransactions: Bool,
                         handler: @escaping ResultHandler) {
        fetchReceipt { [weak self] result in
            guard let self = self else { return }
            self.receiptHandler = nil
            self.receiptRefreshRequest = nil
            
            switch result {
            case .success(let receiptURL):
                do {
                    let receiptData = try Data(contentsOf: receiptURL)
                    self.startURLSession(with: receiptData,
                                         sharedSecret: sharedSecret,
                                         validationMode: validationMode,
                                         excludeOldTransactions: excludeOldTransactions,
                                         handler: handler)
                } catch {
                    self.printError(error)
                    handler(.failure(.other(error.localizedDescription), code: nil))
                }
            case .failure(let error, let code):
                self.printError(error)
                handler(.failure(error, code: code))
            }
        }
    }
    
    private func fetchReceipt(handler: @escaping (SwiftyReceiptValidator.Result<URL>) -> Void) {
        receiptHandler = handler
        
        guard hasReceipt, let receiptURL = receiptURL else {
            receiptRefreshRequest = SKReceiptRefreshRequest(receiptProperties: nil)
            receiptRefreshRequest?.delegate = self
            receiptRefreshRequest?.start()
            return
        }
        
        handler(.success(receiptURL))
    }
}

// MARK: - SKRequestDelegate

extension SwiftyReceiptValidator: SKRequestDelegate {
    
    public func requestDidFinish(_ request: SKRequest) {
        guard hasReceipt, let receiptURL = receiptURL else {
            receiptHandler?(.failure(.noReceiptFound, code: nil))
            return
        }
        
        receiptHandler?(.success(receiptURL))
    }
    
    public func request(_ request: SKRequest, didFailWithError error: Error) {
        printError(error)
        receiptHandler?(.failure(.other(error.localizedDescription), code: nil))
    }
}

// MARK: - Debug

extension SwiftyReceiptValidator {
    
    func printError(_ error: Error) {
        #if DEBUG
        print("SwiftyReceiptValidator error: \(error)")
        #endif
    }
}
