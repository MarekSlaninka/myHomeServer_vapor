import Vapor

let drop = Droplet()
_ = GateController.sharedInstance

drop.get("/hello") { _ in
    return "Hello Vapor"
}

drop.get("/tomas") { _ in
    return "Hello Tomas"
}

drop.get("/start") { _ in
    
    return GateController.sharedInstance.openGate()
    
}

drop.get("/temp") { _ in
    return TempController.sharedInstance.getTemp()
    
}


drop.run()
