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

final class GateController {
    static let sharedInstance = GateController()
    let gpioForRemote: GPIO?
    let gpioForGateSensor: GPIO?
    let highStateDuration: TimeInterval = 1
    let remotePinName: GPIOName = .P17
    let sensorPinName: GPIOName = .P27
    var gateOpen: Bool = false
    var gateTimer: Timer?
    let timeInMinutes: Double = 15
    
    init() {
        drop.console.print("initing", newLine: true)

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
        drop.console.print("initing", newLine: true)

        print("inited")
    }
    
    func setINMethods() {
        self.gpioForGateSensor?.onRaising({ (gp: GPIO) in
            print("raising")
            drop.console.print("raising", newLine: true)

            self.gateClosed()
            if self.gateOpen {
                self.gateOpen = false
                self.gateTimer?.invalidate()
                self.gateTimer = nil
            }
        })
        
        self.gpioForGateSensor?.onFalling({ (gp: GPIO) in
            drop.console.print("falling", newLine: true)

            print("falling")
            self.gateClosed()
            if self.gateOpen {
                if self.gateTimer == nil {
//                    self.setTimer()
                } else if !self.gateTimer!.isValid {
//                    self.setTimer()
                }
            } else {
                self.gateOpen = true
//                self.setTimer()
            }
        })
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
        self.gpioForRemote?.value = 0

    }
    
    func gateClosed() {
        self.gpioForRemote?.value = 1

    }
    
    func gateOpenedForLongTime() {
        
    }
    
    func setTimer() {
        if #available(OSX 10.12, *) {
            self.gateTimer = Timer.scheduledTimer(withTimeInterval: self.timeInMinutes * 60, repeats: false, block: { (tmr: Timer) in
                self.gateOpenedForLongTime()
            })
        } else {
            // Fallback on earlier versions
        }
        #if os(Linux)
            self.gateTimer = Timer.scheduledTimer(withTimeInterval: self.timeInMinutes * 60, repeats: false, block: { (tmr: Timer) in
                self.gateOpenedForLongTime()
            })
        #else
            
        #endif
    }
    
    


}


