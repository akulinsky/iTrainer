//
//  ServiceRouter.swift
//  AjaxTestSwiftUI
//
//  Created by Andrey Kulinskiy on 19.07.2024.
//

import Foundation


enum ServiceRouter: RequestInfoConvertible {
    case users(count: Int)
    
    //https://randomuser.me/api/?results=20
    
    var endpoint: String {
        "https://randomuser.me"
    }
    
    var urlString: String {
        "\(endpoint)/api/\(path)"
    }
    
    var path: String {
        switch self {
        case .users(let count):
            return "?results=\(count)"
        }
    }
    
    func asRequestInfo() -> RequestInfo {
        let requestInfo: RequestInfo = RequestInfo(url: urlString)
                
        // Set other property, like headers, parameters for requestInfo here
        
        return requestInfo
    }
}
