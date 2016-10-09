//
//  GateController.swift
//  myHomeServer_vapor
//
//  Created by Marek Slaninka on 09.10.16.
//
//

import Foundation
import SwiftyGPIO

final class GateController {
    static let sharedInstance = GateController()
    
    init() {
        
        let gpios = SwiftyGPIO.GPIOs(for: .RaspberryPi2)

        guard let ledGPIO = gpios[.P4] else {
            fatalError("It has not been possible to initialised the LED GPIO pin")
        }
    }
    
    func openGate() {
        
    }
}
