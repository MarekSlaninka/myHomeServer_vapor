import Vapor

let drop = Droplet()

drop.get("/hello") { _ in
    return "Hello Vapor"
}

drop.get("/tomas") { _ in
    return "Hello Tomas"
}




drop.run()
