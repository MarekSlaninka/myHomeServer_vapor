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
import Vapor
import Jobs

struct Thermometer: NodeRepresentable, NodeInitializable {
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
  
    init(node: Node, in context: Context) throws {
        self.probeName = try node.extract("probeName")
        self.name = try node.extract("name")
        self.maxTemp = try node.extract("maxTemp")
        self.minTemp = try node.extract("minTemp")
    }
    
    
}


//struct Temperature: NodeRepresentable {
//    var temperature: Double
//    var name: String
//    
//    func makeNode(context: Context) throws -> Node {
//        return try Node(node: [ "temperature": temperature,
//                                "name": name ])
//    }
//}



final class TempController {
    let wrongTemperature: Double = 1000
    static let sharedInstance = TempController()
    var timer: NewTimer?
    var probes: [Thermometer] = []
    let probeDirectory = "/sys/bus/w1/devices/"
    private var probeConfigUrl: String = "probeConfig"
    
    var job: Job?
    
    
    func setLoopForMeasurments(withIntervalInMinutes interval: Double = 5) {
        try? self.timer?.cancel()
    
        let time = interval * 60
        
        self.readTempsFromAllThermometers()

        
        self.timer = NewTimer.init(interval: time, handler: { (timer) in
            drop.console.print("timer fired", newLine: true)
            self.readTempsFromAllThermometers()
        }, repeats: false)
        try? self.timer?.start()
        
    }
    
    func setJob(withIntervalInSeconds interval: Double = 5) {
        self.job?.stop()
        self.job = Jobs.add(interval: interval.seconds, action: {
            self.readTempsFromAllThermometers()
        })
        self.job?.start()
    }
    
    
    func readTempsFromAllThermometers() {
        self.loadProbesFromFirebase()
        _ = self.setConnectedThermometers()
        drop.console.print("readTempsFromAllThermometers-start", newLine: true)

        var measurment = [MeasuredValue]()
        for probe in self.probes {
            drop.console.print("readTempsFromAllThermometers \(probe)", newLine: true)

            guard probe.name != "" else { continue}
            let temp = self.readProbe(name: probe.probeName)
            guard temp != wrongTemperature else {continue}
            let temperature: MeasuredValue = MeasuredValue(value: temp, valueType: .Temp, time: Date(), probe: probe.name)
            measurment.append(temperature)
            self.checkForNotification(probe: probe, temp: temp)
        }
        drop.console.print("readTempsFromAllThermometers-mid", newLine: true)

        if self.saveTemperaturesIntoFirebase(temps: measurment) {
            for var temp in measurment {
                temp.setSyncedInFB(synced: true)
                _ = temp.writeToDatabase()
            }
        } else {
            for var temp in measurment {
                temp.setSyncedInFB(synced: false)
                _ = temp.writeToDatabase()
            }
        }
    }
    
    func checkForNotification(probe: Thermometer, temp: Double) {
            if temp > probe.maxTemp {
                let _ = PushNotificationsManager.sharedInstance.sendNotification(withTitle: "Vysoka teplota", body: "Pozor na teplomery \(probe.name) je teplota \(temp)°C", completitionBlock: nil, drop: drop)
            }
            if temp < probe.minTemp {
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
        drop.console.print("setConnectedThermometers", newLine: true)

        let found = self.findConnectedThermometers()
        var new:Bool = false
        for probe in found {
            if !self.probes.contains(where: { (thermo) -> Bool in
                return thermo.probeName == probe!
            }) {
                self.probes.append(Thermometer(probeName: probe!, name: ""))
                new = true
            }
        }
        if new {
            drop.console.print("setConnectedThermometers-new", newLine: true)

            self.writeProbesToFirebase()
        }
        drop.console.print("setConnectedThermometers-end", newLine: true)

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
        drop.console.print("loadProbesFromConfig", newLine: true)

        if let prArr = ConfigManager.sharedInstance.config["probes"] as? [[String: AnyObject]]{
            for pr in prArr {
                self.probes.append(Thermometer.init(fromJson: pr))
            }
        }
    }
    
    func saveTemperaturesIntoFirebase(temps: [MeasuredValue]) -> Bool {
        drop.console.print("save temp to firebase \(temps.debugDescription)", newLine: true)

        guard let node = try? temps.makeNode() else {return false}
        let timeStamp: Int = Int(Date().timeIntervalSince1970)
        return firebaseManager.saveToFirebase(node: node, route: Config().tempSaveUrl + "/\(timeStamp).json")

    }
    
    func loadProbesFromFirebase() {
        drop.console.print("loadProbesFromFirebase", newLine: true)

        let json = firebaseManager.loadFromFirebase(route: Config().probeConfigUrl + ".json")
        guard let nodes: [Node] = try! json?.extract()  else {self.loadProbesFromConfig(); return}
        var probes: [Thermometer] = [Thermometer]()
        for node in nodes {
            guard let probe = try? node.converted() as Thermometer else {continue}
            probes.append(probe)
        }
        if probes.count == 0 {
            self.loadProbesFromConfig()
        } else {
            self.probes = probes
        }
    }
    
    func writeProbesToConfig() {
        guard let js = try? JSON(node: self.probes.makeNode()) else {return}
        ConfigManager.sharedInstance.writeToConfig(object: js , forKey: "probes")
//        self.writeProbesToFirebase()
    }
    
    func writeProbesToFirebase() {
        self.writeProbesToConfig()
        guard let probes: Node = try? self.probes.makeNode() else {return}
        _ = firebaseManager.saveToFirebase(node: probes, route: Config().probeConfigUrl + ".json")
    }
}



