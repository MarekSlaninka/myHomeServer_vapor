import Vapor
import Foundation
import Dispatch

let drop = Droplet()
let gate = GateController(_drop: drop)



drop.get("/hello") { _ in
    return "Hello Vapor"
}

drop.get("/tomas") { _ in
    return "Hello Tomas"
}

drop.get("/start") { _ in
    
    gate.setTimer()
    return gate.openGate()
    
}

drop.get("/temp") { _ in

    
    DispatchQueue.global().asyncAfter(deadline: DispatchTime.now() + .seconds(5)) {
        drop.console.print("background after", newLine: true)
    }
    return TempController.sharedInstance.getTemp()
}

drop.get("/after",":time") { request in
    var time: Double = 2
    if let time = request.parameters["time"]?.double {
        
    }
    drop.console.print("background before in time: \(time)", newLine: true)

    DispatchQueue.global().asyncAfter(deadline: DispatchTime.init(secondsFromNow: time), execute: {
        drop.console.print("background after", newLine: true)
    })
    
    return "after time: \(time)"
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

drop.get("timer",":time") { request in
    var time: Double = 2
    if let time = request.parameters["time"]?.double {
        
    }
    let timer = Timer.init(interval: time, handler: { (timer) in
        drop.console.print("timer after \(time)", newLine: true)

    }, repeats: false)
    try? timer.start()
    
    return "timer"
}




drop.run()
