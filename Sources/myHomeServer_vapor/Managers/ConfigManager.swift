//
//  ConfigManager.swift
//  myHomeServer_vapor
//
//  Created by Marek Slaninka on 12.11.16.
//
//

import Foundation
import Vapor

class ConfigManager: NSObject {
    static let sharedInstance: ConfigManager = ConfigManager()
    let plistPath: String = "file://" + drop.workDir.finished(with: "/") + "Sources/myHomeServer_vapor/"
    let plistName: String = "config.plist"
    var propertyListForamt =  PropertyListSerialization.PropertyListFormat.xml //Format of the Property List.
    
    var config = [String: AnyObject]()
    var lastChange: Date?
    override init() {
        super.init()
        
        self.loadPropertyList()
    }
    
    func loadPropertyList() {
        var plistData: [String: AnyObject] = [:] //Our data
        //        if let configRoute: URL = URL(string: "file://" + drop.workDir.finished(with: "/") + "Config/thermoProbes.json") {
        //            if let config = try? Data.init(contentsOf: configRoute) {
        
        //        let plistXML = FileManager.default.contents(atPath: plistPath!)!
        if let plistXML = try? Data.init(contentsOf: URL(string: self.plistPath + self.plistName)!) {
            do {//convert the data to a dictionary and handle errors.
                plistData = try PropertyListSerialization.propertyList(from: plistXML, options: [], format: &self.propertyListForamt) as! [String:AnyObject]
                self.config = plistData
                self.lastChange = plistData["lastChange"] as? Date
            } catch {
                print("Error reading plist: \(error), format: \(propertyListForamt)")
            }
        }
    }
    
    func saveConfigToPlist() {
        let data = try? PropertyListSerialization.data(fromPropertyList: self.config as! AnyObject, format: self.propertyListForamt, options: 0)
        try? data?.write(to: URL(string:self.plistPath + self.plistName)!)
    }
    
    func writeToConfig(object: Any, forKey key: String) {
        self.config[key] = object as AnyObject?
        self.saveConfigToPlist()
    }
    
    func shareConfigFile() -> Data? {
        
        
        return nil
    }
    
    
}
