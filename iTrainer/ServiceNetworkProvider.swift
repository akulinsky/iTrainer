//
//  ServiceNetworkProvider.swift
//  AjaxTestSwiftUI
//
//  Created by Andrey Kulinskiy on 19.07.2024.
//

import Foundation
import Combine

protocol ServiceNetworkProvider {
    func getUsers(count: Int) -> AnyPublisher<PersonsResponseModel, Error>
}

class ServiceNetworkClient: ServiceNetworkProvider {
    
    var networkClient: NetworkProvider = NetworkClient.instance
    
    func getUsers(count: Int) -> AnyPublisher<PersonsResponseModel, Error> {
        networkClient.request(ServiceRouter.users(count: count)).decode()
    }
}
