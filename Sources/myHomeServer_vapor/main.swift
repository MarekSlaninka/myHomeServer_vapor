import Vapor

let drop = Droplet()

drop.get("/hello") { _ in
    return "Hello Vapor"
}

drop.get("/roland") { _ in
    return "Hello Roland"
}



drop.run()
