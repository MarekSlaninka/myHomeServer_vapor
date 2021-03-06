//
//  PinController.swift
//  myHomeServer_vapor
//
//  Created by Marek Slaninka on 12.11.16.
//
//

import Foundation
import SwiftyGPIO
import Vapor
import HTTP
import Jobs

extension Bool {
    init<T: Integer>(_ num: T) {
        self.init(num != 0)
    }
}


enum PinType: Int {
    case switcher = 0
    case impulser
}

struct Pin: NodeRepresentable, NodeInitializable {
    var pinNumber: Int
    var type: PinType
    var state: Bool?
    var secured: Bool
    var name: String?
    var direction: GPIODirection? {
        didSet {
            if direction != nil {
                gpio?.direction = direction!
            } else {
                direction = gpio?.direction
            }
        }
    }
    
    var gpio: GPIO?
    
    init(name: String?, pinNumber: Int, type: PinType, secured: Bool) {
        self.gpio = GPIOS.shared.getGpio(number: pinNumber)
        self.pinNumber = pinNumber
        self.type = type
        self.secured = secured
    }
    
    init(node: Node, in context: Context) throws {
        pinNumber = try node.extract("pinNumber")
        gpio = GPIOS.shared.getGpio(number: pinNumber)
        type = try PinType(rawValue: node.extract("type"))!
        state = try node.extract("state")
        secured = try node.extract("secured")
        name = try node.extract("name")
//        direction = try GPIODirection(rawValue: node.extract("direction"))
        direction = GPIODirection.OUT
    }
    
    func makeNode(context: Context) throws -> Node {
        return try Node(node: ["pinNumber" : pinNumber,
                               "type" : type.rawValue,
                               "state": state,
                               "secured": secured,
                               "name": name,
                               "direction": direction?.rawValue])
    }
    
    //    func setValue(gpio: ) {
    //
    //    }
    
}


final class PinController {
    var pins: [Pin] = [Pin]()
    
    func addRoutes(drop: Droplet) {
        let pinGroup = drop.grouped("pins")
        
        //Znovu nacitanie pinov z FirebaseDB
        pinGroup.get("reload") { request in
            if self.loadPinsConfigFromFirebase() {
                return Response(status: .ok, body: "Okay")
            } else {
                return Response(status: .badRequest, body: "Bad")
            }
        }
        
        //Set Pin to state
        pinGroup.post("set") { request in
            let data = request.data

            drop.console.print(request.description, newLine: true)
            guard let pinNumber = data["pinNumber"]?.int else {return Response(status: .badRequest, body: "Wrong parameter pinNumber")}
            guard let state = data["state"]?.int else {return Response(status: .badRequest, body: "Wrong parameter state") }
            
            guard let pin = self.pins.first(where: { (pin) -> Bool in
                pin.pinNumber == pinNumber
            }) else {return  Response(status: .badRequest, body:  "Unknown pin number") }
            if pin.secured {
                guard let _ = data["password"]?.string else {return Response(status: .badRequest, body:  "Wrong parameter password") }
            }
            self.set(pin: pin, toState: Bool(state), completitionBlock: {
//                return Response(status: .ok, body: "Okay")
            })
            return Response(status: .ok, body: "Okay")
        }
        
        
        pinGroup.post("impulse") { request in
            drop.console.print(request.description, newLine: true)
            let data = request.data
            guard let pinNumber = data["pinNumber"]?.int else {return Response(status: .badRequest, body: "Wrong parameter pinNumber")}
            guard let time = data["time"]?.int else {return Response(status: .badRequest, body: "Wrong parameter time") }
//            guard let state = request.json?["state"]?.int else {return Abort.custom(status: .badRequest, message: "Wrong parameter state") as! ResponseRepresentable}
            
            guard let pin = self.pins.first(where: { (pin) -> Bool in
                pin.pinNumber == pinNumber
            }) else {return  Response(status: .badRequest, body: "Unknown pin number") }
            if pin.secured {
                guard let _ = data["password"]?.string else {return Response(status: .badRequest, body:  "Wrong parameter password") }
            }
            pin.gpio?.value = 1//pin.gpio?.value == 1 ? 0 : 1
            
            Jobs.oneoff(delay: time.seconds) {
                pin.gpio?.value = 0//pin.gpio?.value == 1 ? 0 : 1
            }
            
            return try! Response(status: .ok, body: JSON(node: ["value": pin.gpio!.value]))
        }
        
        
    }
    
    
    func sendImpulseTo(pin: Pin, completitionBlock: ((String)->())?) {
//        guard pin.type == .impulser else {return}
        completitionBlock?("Otvara sa")
    }
    
    func set(pin: Pin,toState state: Bool, completitionBlock: @escaping (()->())) {
//        guard pin.type == .switcher else {return}
        pin.gpio?.direction = .OUT
        pin.gpio?.value = state.int!
        
        completitionBlock()
    }
    
    
    
    func savePinsConfigToFirebase() {
        _ = try? firebaseManager.saveToFirebase(node: self.pins.makeNode(), route: Config().pinsConfigUrl + ".json")
    }
    
    func loadPinsConfigFromFirebase() -> Bool{
        let json = firebaseManager.loadFromFirebase(route: Config().pinsConfigUrl + ".json")
        guard let nodes: [Node] = try! json?.extract()  else {return false}
        var pins: [Pin] = [Pin]()
        for node in nodes {
            guard let probe = try? node.converted() as Pin else {continue}
            pins.append(probe)
        }
        self.pins = pins
        return true
    }
    

    
}

class GPIOS {
    static let shared = GPIOS()
    public let gpios = SwiftyGPIO.GPIOs(for: .RaspberryPi2)
    
    func getGpio(number: Int) -> GPIO? {
        guard let gpioName = self.numberToGPIOName(number: number) else {return nil}
        return gpios[gpioName]
    }
    
    func numberToGPIOName(number: Int) -> GPIOName?{
        switch number {
        case 3:
            return .P2
        case 5:
            return .P3
        case 7:
            return .P4
        case 8:
            return .P14
        case 10:
            return .P15
        case 11:
            return .P17
        case 12:
            return .P18
        case 13:
            return .P27
        case 15:
            return .P22
        case 16:
            return .P23
        case 18:
            return .P24
        case 19:
            return .P10
        case 21:
            return .P9
        case 22:
            return .P25
        case 23:
            return .P11
        case 24:
            return .P8
        case 26:
            return .P7
        case 29:
            return .P5
        case 31:
            return .P6
        case 32:
            return .P12
        case 33:
            return .P13
        case 35:
            return .P19
        case 36:
            return .P16
        case 37:
            return .P26
        case 38:
            return .P20
        case 40:
            return .P21
        default:
            return nil
        }
    }
}


