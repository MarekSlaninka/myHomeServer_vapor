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
    DispatchQueue.main.asyncAfter(deadline: .now() + 10) {
        drop.console.print("background after", newLine: true)
    }

    return TempController.sharedInstance.getTemp()
}



drop.run()
