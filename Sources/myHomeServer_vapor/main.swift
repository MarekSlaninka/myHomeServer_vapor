import Vapor
import Foundation
import Dispatch

let drop = Droplet()
let gate = GateController.sharedInstance

drop.get("/hello") { _ in
    return "Hello Vapor"
}

drop.get("/tomas") { _ in
    return "Hello Tomas"
}

drop.get("/start") { _ in
    
    gate.setTimer()
    return GateController.sharedInstance.openGate()
    
}

drop.get("/temp") { _ in

    
    DispatchQueue.global().asyncAfter(deadline: DispatchTime.now() + .seconds(5)) {
        drop.console.print("background after", newLine: true)
    }
    return TempController.sharedInstance.getTemp()
}

drop.get("/after") { _ in
    
//    DispatchQueue.global().asyncAfter(deadline: DispatchTime.now() + .seconds(5)) {
//        drop.console.print("background after", newLine: true)
//    }
    drop.console.print("background before", newLine: true)

    DispatchQueue.global().asyncAfter(deadline: .now() + 5, execute: {
        drop.console.print("background after", newLine: true)
        var i = 0
        while i < 3 {
            i+=1
            drop.console.print("background aft ", newLine: true)
            sleep(2)
        }
    })
    
    return "after"
}

drop.get("/background") { _ in
    
    DispatchQueue.global().async {
        var i = 0
        while i < 50 {
            i+=1
            drop.console.print("background ", newLine: true)
            sleep(2)
        }
    }
    return "background"
    
}

drop.run()
