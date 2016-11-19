//
//  PinController.swift
//  myHomeServer_vapor
//
//  Created by Marek Slaninka on 12.11.16.
//
//

import Foundation
import SwiftyGPIO

enum PinType {
    case switcher
    case impulser
}

struct Pin {
    var pinNumber: Int
    var type: PinType
    var state: Bool?
    var secured: Bool
    var name: String?
    
    init(name: String?, pinNumber: Int, type: PinType, secured: Bool) {
        self.pinNumber = pinNumber
        self.type = type
        self.secured = secured
    }
}


final class PinController {
    let gpios = SwiftyGPIO.GPIOs(for: .RaspberryPi2)
    
    
    func sendImpulseTo(pin: Pin, completitionBlock: ((String)->())?) {
        guard pin.type == .impulser else {return}
        completitionBlock?("Otvara sa")
    }
    
    func set(pin: Pin,toState state: Bool, to completitionBlock: (()->())?) {
        guard pin.type == .switcher else {return}
    }
    
    
}
