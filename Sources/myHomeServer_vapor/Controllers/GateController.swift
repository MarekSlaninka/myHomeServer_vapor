//
//  GateController.swift
//  myHomeServer_vapor
//
//  Created by Marek Slaninka on 09.10.16.
//
//

import Foundation

import SwiftyGPIO
import HTTP
import Dispatch
import Vapor


final class GateController {
//    static let sharedInstance = GateController()
    
    var drop: Droplet
    
    let gpioForRemote: GPIO?
    let gpioForGateSensor: GPIO?
    let highStateDuration: TimeInterval = 1
    let remotePinName: GPIOName = .P17
    let sensorPinName: GPIOName = .P27
    var gateOpen: Bool = false
    var gateTimer: Timer?
    let timeInMinutes: Double = 15
    
    
    init(_drop: Droplet) {
        self.drop = _drop
        self.drop.console.print("initing", newLine: true)
        
        let gpios = SwiftyGPIO.GPIOs(for: .RaspberryPi2)
        
        //set GPIO for remote controll
        self.gpioForRemote = gpios[self.remotePinName]
        guard self.gpioForRemote != nil else {
            fatalError("It has not been possible to initialised the LED GPIO pin")
        }
        self.gpioForRemote?.direction = .OUT

        
        //set GPIO for gate sensor
        self.gpioForGateSensor = gpios[self.sensorPinName]
        guard self.gpioForGateSensor != nil else {
            fatalError("It has not been possible to initialised the LED GPIO pin")
        }
        self.gpioForGateSensor!.direction = .IN
//        self.setTimerOnInit()
        self.setINMethods()
        self.drop.console.print("initing finished", newLine: true)
        self.setTimer()
        
        try? background {
            self.drop.console.print("background", newLine: true)
            if self.gateOpen {
                self.gateOpen = false
                self.gateClosed()
                self.drop.console.print("closed", newLine: true)
            } else {
                self.gateOpen = true
                self.gateOpened()
                self.drop.console.print("opened", newLine: true)
            }
        }
    }
    
    
    
    func setINMethods() {
        
        self.gpioForGateSensor?.onChange({ (gp: GPIO) in
            if self.gateOpen {
                self.gateOpen = false
                self.gateClosed()
                self.drop.console.print("closed", newLine: true)
            } else {
                self.gateOpen = true
                self.gateOpened()
                self.drop.console.print("opened", newLine: true)
            }
        })
    }
    
    func changeLight() {
        if self.gateOpen {
            self.gateOpen = false
            self.gateClosed()
            self.drop.console.print("closed", newLine: true)
        } else {
            self.gateOpen = true
            self.gateOpened()
            self.drop.console.print("opened", newLine: true)
        }
    }
    
    func setTimerOnInit() {
        switch self.gpioForGateSensor!.value {
        case 0:
            self.gateOpen = true
//            self.setTimer()
            break
        case 1:
            self.gateOpen = false
            break
        default:
            break
        }

    }
    
    func openGate() -> String {
        guard self.gpioForRemote != nil else {
            return "It has not been possible to initialised the LED GPIO pin"
        }
        self.gpioForRemote?.value = 1
        sleep(UInt32(round(highStateDuration)))
        self.gpioForRemote?.value = 0
        return "ok"
    }
    
    func gateOpened() {
        self.gpioForRemote?.value = 1

    }
    
    func gateClosed() {
        self.gpioForRemote?.value = 0

    }
    
    func gateOpenedForLongTime() {
        
    }
    
    func setTimer() {
        #if os(Linux)
            self.drop.console.print("set timer", newLine: true)
            
            self.gateTimer = Timer.scheduledTimer(withTimeInterval: 1, repeats: true) { (tr: Timer) in
                self.drop.console.print("timer fired /(Date())", newLine: true)
                self.changeLight()
            }
        #else
            
        #endif
    }
    
    


}


