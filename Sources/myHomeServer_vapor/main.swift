import Vapor

let drop = Droplet()

drop.get("/hello") { _ in
    return "Hello Vapor"
}

drop.get("/tomas") { _ in
    return "Hello Tomas"
}

drop.get("/start") { _ in
    
    return GateController.sharedInstance.openGate()
//    return "otvoreke"
    
}

drop.get("/temp") { _ in
    return TempController.sharedInstance.getTemp()
  
//        return "otvoreke"
    
}


drop.run()
