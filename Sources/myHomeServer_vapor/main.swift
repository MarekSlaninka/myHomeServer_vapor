import Vapor
import Foundation
import Dispatch

let drop = Droplet()
#if os(Linux)
let gate = GateController(_drop: drop)
#endif




TempController.sharedInstance.writeProbesToConfig()
TempController.sharedInstance.loadProbesFromConfig()

ConfigManager().getConfigFile()

drop.get("hello") { request in
    let name = request.data["name"]?.string ?? "stranger"
    return name
}

drop.get("/tomas") { _ in
    return "Hello Tomas"
}
#if os(Linux)
drop.get("/openGate") { _ in
    
    gate.setTimer()
    return gate.openGate()
    
}
#endif

drop.get("/temp") { _ in
    do {
        let spotifyResponse = try drop.client.get("https://api.weixin.qq.com/cgi-bin/token")
        print(spotifyResponse)
    } catch let error  {
        print(error)
    }
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

drop.get("/notif") { _ in
    if let resp = PushNotificationsManager.sharedInstance.sendNotification(withTitle: "RPi push", body: "Notifikacia z raspberry pi", completitionBlock:nil, drop: drop){
        return resp
    } else {
        return "nevydalo"
    }
//    return "poslana notifikacia, dufam :D"
}


drop.run()
