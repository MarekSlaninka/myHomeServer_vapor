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

drop.get("/openGate") { _ in
    
    gate.setTimer()
    return gate.openGate()
    
}

drop.get("/temp") { _ in
    return TempController.sharedInstance.getTemp()
}



//Timer test WORK
drop.get("timer",":time") { request in
    var time: Double = 2
    if let tm = request.parameters["time"]?.double {
        time = tm
    }
    let timer = NewTimer.init(interval: time, handler: { (timer) in
        drop.console.print("timer after \(time)", newLine: true)

    }, repeats: false)
    try? timer.start()
    
    
    return "timer \(timer), time: \(time)"
}




drop.run()
