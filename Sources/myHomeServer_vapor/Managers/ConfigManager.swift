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
    
    func getConfigFile() -> [[String: String]]? {
        
        if let configRoute: URL = URL(string: "file://" + drop.workDir.finished(with: "/") + "Config/thermoProbes.json") {
            if let config = try? Data.init(contentsOf: configRoute) {
                if let probeArray = try? JSONSerialization.jsonObject(with: config, options: []) as? [[String: String]] {
                 
                    return probeArray
                }
            }
        }

        
        return nil
    }
    
    func readPropertyList() -> [String: AnyObject]? {
        var propertyListForamt =  PropertyListSerialization.PropertyListFormat.xml //Format of the Property List.
        var plistData: [String: AnyObject] = [:] //Our data
        let plistPath: String? = Bundle.main.path(forResource: "data", ofType: "plist")! //the path of the data
        let plistXML = FileManager.default.contents(atPath: plistPath!)!
        do {//convert the data to a dictionary and handle errors.
            plistData = try PropertyListSerialization.propertyList(from: plistXML, options: [], format: &propertyListForamt) as! [String:AnyObject]
            return plistData
        } catch {
            print("Error reading plist: \(error), format: \(propertyListForamt)")
        }
        return nil
    }
    
    
    func setConfigFile() {
        
    }
    
}
