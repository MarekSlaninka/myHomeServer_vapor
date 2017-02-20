//
//  FirebaseController.swift
//  myHomeServer_vapor
//
//  Created by Marek Slaninka on 13.10.16.
//
//

import Foundation
import Vapor
import HTTP

final class FirebaseController {
    
//     private let sharedInstance = FirebaseController()
     private var firebaseUrl: String = ""
    private var firebaseKey: String = ""
    
    init(url: String, key: String) {
        self.firebaseKey = key
        self.firebaseUrl = url
    }
    

    
    func saveToFirebase(node: Node, route: String) -> Bool {
        let fullRoute = self.firebaseUrl + route

        guard let request: Request = try? Request(method: .put, uri: fullRoute) else {return false}
        guard let json: JSON = try? JSON(node: node) else {return false}
        guard let body: Body = try? Body.init(json) else {return false}
        request.body = body
//        request.parameters = node
        
        let response = try? drop.client.respond(to: request)
        drop.console.print(response.debugDescription, newLine: true)
        if response?.status != Status.accepted {
            return false
        }
        return true
    }
    
    func loadFromFirebase(route: String) -> JSON? {
        let fullRoute = self.firebaseUrl + route
        guard let request: Request = try? Request(method: .get, uri: fullRoute) else {return nil}
        guard let response = try? drop.client.respond(to: request) else {return nil}
        
        return response.json
    }

}
