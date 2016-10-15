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

final class TempController {
    static let sharedInstance = TempController()
    let probeNames = ["28-021564ce28ff", "28-021564f10eff"]
    let probeDirectory = "/sys/bus/w1/devices/"
    
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
            temp = 0.0
        }
        
        return Double(temp)
    }
    
    func doReading() -> Double{
        //Turn LED on to indicate we've begun reading the temperature
        let temp = readProbe(name: probeNames.first!)
        
        //sleep a little bit so we don't miss it. Not required
        usleep(1000)
        
        return temp
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
    
}