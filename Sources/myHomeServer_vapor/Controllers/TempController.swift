//
//  TempController.swift
//  myHomeServer_vapor
//
//  Created by Marek Slaninka on 13.10.16.
//
//

import Foundation
import SwiftyGPIO
import HTTP
import Console
import Jay
import JSON

struct Thermometer: NodeRepresentable {
    var probeName: String
    var name: String = ""
    var maxTemp: Double = 1000
    var minTemp: Double = -1000
    
    init(probeName: String, name: String) {
        self.probeName = probeName
        self.name = name
    }
    
  //  func toJson() -> [String: Any]{
  //      drop.console.print("debug 1", newLine: true)
  //      let sl  =  ["probeName": probeName,
  //                  "name": name ,
  //                 "maxTemp": maxTemp ,
  //                  "minTemp": minTemp ] as [String : Any]
  //      drop.console.print("debug 2", newLine: true)
  //
  //      return sl
  //  }
    
    init(fromJson: [String: AnyObject]){
        self.probeName = fromJson["probeName"] as! String
        self.name = fromJson["name"] as! String
        self.maxTemp = (fromJson["maxTemp"] as? Double)!
        self.maxTemp = (fromJson["minTemp"] as? Double)!
    }
    
    func makeNode(context: Context) throws -> Node {
        return try Node(node: ["probeName": probeName,
                         "name": name,
                         "maxTemp": maxTemp ,
                         "minTemp": minTemp ])
    }
    
    
    
}





final class TempController {
    let wrongTemperature: Double = 1000
    static let sharedInstance = TempController()
    var timer: NewTimer?
    var probes: [Thermometer] = []
    let probeDirectory = "/sys/bus/w1/devices/"
    
    
    func setLoopForMeasurments(withIntervalInMinutes interval: Double = 5) {
        try? self.timer?.cancel()
        
        let time = interval * 60
        
        self.timer = NewTimer.init(interval: time, handler: { (timer) in
            self.readTempsFromAllThermometers()
        }, repeats: false)
        try? self.timer?.start()
    }
    
    func readTempsFromAllThermometers() {
        self.loadProbesFromConfig()
        var measurment = [String: Double]()
        for probe in self.probes {
            guard probe.name != nil else {continue}
            let temp = self.readProbe(name: probe.probeName)
            guard temp != wrongTemperature else {continue}
            
            measurment[probe.name] = temp
            self.checkForNotification(probe: probe, temp: temp)
            
        }
    }
    
    func checkForNotification(probe: Thermometer, temp: Double) {
            if temp > probe.maxTemp {
                let _ = PushNotificationsManager.sharedInstance.sendNotification(withTitle: "Vysoka teplota", body: "Pozor na teplomery \(probe.name) je teplota \(temp)°C", completitionBlock: nil, drop: drop)
            }
        
            if temp > probe.minTemp {
                let _ = PushNotificationsManager.sharedInstance.sendNotification(withTitle: "Nizka teplota", body: "Pozor na teplomery \(probe.name) je teplota \(temp)°C", completitionBlock: nil, drop: drop)
            }
        
    }
    
    func getTemp() -> String {
        var stringTemp = "temps: "
        let probes = self.findConnectedThermometers()
        for probe in probes {
            stringTemp.append(String(readProbe(name: probe!))+"°C   " )
        }
        return stringTemp
    }
    
    
    
    func readProbe(name : String) -> Double {
        let path = "\(probeDirectory)\(name)/w1_slave"
        var outval = ""
        let BUFSIZE = 1024
        
        let fp = fopen(path, "r")
        
        // try reading from /sys/bus/w1/devices/{prob name}/w1_slave
        if fp != nil {
            var buf = [CChar](repeating:CChar(0), count:BUFSIZE)
            while fgets(&buf, Int32(BUFSIZE), fp) != nil {
                //outval += String.fromCString(buf)!
                outval += String(validatingUTF8:buf)!
            }
        }
        
        let temp : Double
        if let tempS = outval.split(byString:"t=").last, let t = Double(tempS.trim()) {
            temp = Double(t)/1000.0
        } else {
            temp = wrongTemperature
        }
        
        return Double(temp)
    }
    
    func setConnectedThermometers() -> Int{
        let found = self.findConnectedThermometers()
        for probe in found {
            if !self.probes.contains(where: { (thermo) -> Bool in
                return thermo.probeName == probe!
            }) {
                self.probes.append(Thermometer(probeName: probe!, name: ""))
            }
        }
        self.writeProbesToConfig()
        return found.count
    }
    
    func findConnectedThermometers() -> [String?]{
        let fileManager = FileManager.default
        guard let enumerator = fileManager.enumerator(atPath: self.probeDirectory) else {return []}
        
        var thermometers: [String] = []
        while let element = enumerator.nextObject() as? String {
            if element.hasPrefix("28-") {
                thermometers.append(element)
            }
        }
        return thermometers
    }
    
    func loadProbesFromConfig() {
        if let prArr = ConfigManager.sharedInstance.config["probes"] as? [[String: AnyObject]]{
            for pr in prArr {
                self.probes.append(Thermometer.init(fromJson: pr))
            }
        }
    }
    
    func writeProbesToConfig() {
        guard let js = try? JSON(node: self.probes.makeNode()) else {return}

        
        ConfigManager.sharedInstance.writeToConfig(object: js , forKey: "probes")
    }
    
    func writeProbesToFirebase() {
       // let js = self.probes.map({ (th) -> [String: Any] in
       //     JSON(node: th)
       // })
        
        guard let js = try? JSON(node: self.probes.makeNode()) else {return}
 
        
        if let data = try? Jay(formatting: .prettified).dataFromJson(any: js) {// [UInt8]
            drop.console.print("debug saveConfigToPlist 2", newLine: true)
            
            try? Data.init(bytes: data).write(to: URL(string:ConfigManager.sharedInstance.plistPath + ConfigManager.sharedInstance.plistName)!)
            
            _ = try? drop.client.request(.post, "", query: ["probes": data.debugDescription])
            
            drop.console.print("debug saveConfigToPlist 3", newLine: true)
        }
        
    }
    
}
