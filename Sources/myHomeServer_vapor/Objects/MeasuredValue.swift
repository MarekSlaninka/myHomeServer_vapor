//
//  MeasuredValue.swift
//  myHomeServer_vapor
//
//  Created by Marek Slaninka on 18.2.17.
//
//

import Foundation
import HTTP
import Console
import Jay
import JSON
import Vapor
import VaporSQLite

enum ValueType: Int, NodeRepresentable {
    case Temp = 1
    
    func makeNode(context: Context) throws -> Node {
        return try Node(node: ["type": self.rawValue])
    }
}

struct MeasuredValue: NodeRepresentable {
    var value: Double
    var valueType: ValueType
    var time: Date
    var probe: String
    var syncedInFB: Int?
    
    
    mutating func setSyncedInFB(synced: Bool) {
        self.syncedInFB = synced ? 1 : 0
    }
    
    
    init(value: Double, valueType: ValueType, time: Date, probe: String) {
        self.value = value
        self.valueType = valueType
        self.time = time
        self.probe = probe
    }
    
    func makeNode(context: Context) throws -> Node {
        
        return try Node(node: ["value": value,
                               "valueType": valueType,
                               "time": time.timeIntervalSince1970,
                               "probe": probe])
    }
    
    
    func writeToDatabase() -> Node? {
        let result = try? drop.database?.driver.raw("INSERT INTO MeasuredData(value, value_type, time, probe, syncedInFB)", [Node(value), Node(valueType.rawValue), time.timeIntervalSince1970, probe, syncedInFB!])
        guard result != nil else {return nil}
        return result!
    }
    
}


