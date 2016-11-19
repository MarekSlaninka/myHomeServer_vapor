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

struct Thermometer {
    var probeName: String
    var name: String?
    var maxTemp: Double?
    var minTemp: Double?
    
    init(probeName: String, name: String?) {
        self.probeName = probeName
        self.name = name
    }
    
    func toJson() -> [String: String]{
        let sl = ["probeName": probeName, "name": name ?? ""]
        
        return sl// try! JSONSerialization.data(withJSONObject: sl, options: .prettyPrinted)
        
    }
    
    init(fromJson: [String: String]){
        self.probeName = fromJson["probeName"]!
        self.name = fromJson["name"]
//        self.probeName = try! (JSONSerialization.jsonObject(with: fromJson, options: []) as! [String: String])["probeName"]!
//        self.name = try!  (JSONSerialization.jsonObject(with: fromJson, options: []) as! [String: String])["name"]!
    }
}




final class TempController {
    static let sharedInstance = TempController()
    var timer: NewTimer?
    var probes: [Thermometer] = []
    let probeDirectory = "/sys/bus/w1/devices/"
    
    init() {
        self.probes.append(Thermometer(probeName: "probeName1", name: "meno1"))
        self.probes.append(Thermometer(probeName: "probeName2", name: "meno2"))
    }
    
    
    func setLoopForMeasurments(withIntervalInMinutes interval: Double = 5) {
        try? self.timer?.cancel()

        let time = interval * 60
        
        self.timer = NewTimer.init(interval: time, handler: { (timer) in
            
            
        }, repeats: false)
        try? self.timer?.start()
    }

    func readTempsFromAllThermometers() {
        var measurment = [String: Double]()
        for probe in self.probes {
            guard probe.name != nil else {continue}
            let temp = self.readProbe(name: probe.probeName)
            guard temp != 1000 else {continue}
            measurment[probe.name!] = temp
            guard probe.maxTemp != nil else {continue}
            if temp > probe.maxTemp! {
                PushNotificationsManager.sharedInstance.sendNotification(withTitle: "Vysoka teplota", body: "Pozor na teplomery \(probe.name) je teplota \(temp)°C", completitionBlock: nil, drop: drop)
            }
            guard probe.minTemp != nil else {continue}
            if temp > probe.minTemp! {
                PushNotificationsManager.sharedInstance.sendNotification(withTitle: "Nizka teplota", body: "Pozor na teplomery \(probe.name) je teplota \(temp)°C", completitionBlock: nil, drop: drop)
            }
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
            temp = 1000
        }
        
        return Double(temp)
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
        if let configRoute: URL = URL(string: "file://" + drop.workDir.finished(with: "/") + "Config/thermoProbes.json") {
            if let config = try? Data.init(contentsOf: configRoute) {
                if let probeArray = try? JSONSerialization.jsonObject(with: config, options: []) as? [[String: String]] {
                    for ar in probeArray! {
                        self.probes.append(Thermometer.init(fromJson: ar))
                    }
                    debugPrint(self.probes)
                }
            }
        }
    }
    
    func writeProbesToConfig() {
        if let configRoute: URL = URL(string: drop.workDir.finished(with: "/") + "Config/thermoProbes.json") {
            let js = self.probes.map { (th) -> [String: String] in
                th.toJson()
            }
            let data = try? JSONSerialization.data(withJSONObject: js, options: .prettyPrinted)
            try? data?.write(to: configRoute)
        }
    }
    
}
