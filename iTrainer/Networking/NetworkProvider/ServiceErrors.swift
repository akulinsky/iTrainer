//
//  ServiceErrors.swift
//  AjaxTestSwiftUI
//
//  Created by Andrey Kulinskiy on 20.07.2024.
//

import Foundation

struct ServiceError: Error {
    
    var code: Int
    
    var message: String {
        switch code {
        case 400:
            return "400 Bad Request."
        case 401:
            return "401 Unauthorized."
        case 403:
            return "HTTP Error 403 Forbidden."
        case 404:
            return "404 Not Found."
        case 500:
            return "HTTP Error 500 Internal Server Error."
        case 501:
            return "501 Not Implemented."
        case 502:
            return "502 Bad Gateway."
        case 503:
            return "HTTP Error 503 Service Unavailable."
        default:
            return "Unknown error: \(code.description)"
        }
    }
}

extension Error {
    /// Returns the instance cast as an `ServiceError`.
    var asServiceError: ServiceError? {
        self as? ServiceError
    }
}
