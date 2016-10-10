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
    let gpioForGate: GPIO?
    let highStateDuration: TimeInterval
    let lowStateDuration: TimeInterval
    
    init() {
        
        let gpios = SwiftyGPIO.GPIOs(for: .RaspberryPi2)
        self.gpioForGate = gpios[.P4]
        guard self.gpioForGate != nil else {
            fatalError("It has not been possible to initialised the LED GPIO pin")
        }
        self.highStateDuration = 3
        self.lowStateDuration = 0.5
    }
    
    func openGate() {
        guard self.gpioForGate != nil else {
            fatalError("It has not been possible to initialised the LED GPIO pin")
        }

        self.gpioForGate?.value = 1
        sleep(UInt32(round(highStateDuration)))
        self.gpioForGate?.value = 0
    }
}
