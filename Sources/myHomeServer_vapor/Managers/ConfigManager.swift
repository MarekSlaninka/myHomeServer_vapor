//
//  ConfigManager.swift
//  myHomeServer_vapor
//
//  Created by Marek Slaninka on 12.11.16.
//
//

import Foundation
import Vapor
import Jay

class ConfigManager: NSObject {
    static let sharedInstance: ConfigManager = ConfigManager()
    let plistPath: String = "file://" + drop.workDir.finished(with: "/") + "Sources/myHomeServer_vapor/"
    let plistName: String = "config.plist"
    var propertyListForamt =  PropertyListSerialization.PropertyListFormat.xml //Format of the Property List.
    
    var config = [String: Any]()
    var lastChange: Date?
    override init() {
        super.init()
        
        self.loadPropertyList()
    }
    
    func loadPropertyList() {
        drop.console.print("debug load 1", newLine: true)
        if let data = try? Data.init(contentsOf: URL(string: self.plistPath + self.plistName)!) {
            if let config = try? Jay().anyJsonFromData([UInt8](data)) {
                if let cf = config as? [String: Any] {
                    self.config = cf
                }
            }
            
            
        }
    }
    
    func saveConfigToPlist() {
        drop.console.print(self.plistPath + self.plistName, newLine: true)
        let data = try? Jay(formatting: .prettified).dataFromJson(any: self.config) // [UInt8]
        try? Data.init(bytes: data!).write(to: URL(string:self.plistPath + self.plistName)!)
    }
    
    func writeToConfig(object: Any, forKey key: String) {
        self.config[key] = object
        self.saveConfigToPlist()
    }
    
    func shareConfigFile() -> Data? {
        
        
        return nil
    }
    
    func getConfig() -> [String: Any] {
        return self.config
    }
    
    
}
