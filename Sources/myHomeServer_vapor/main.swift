import Vapor
import Foundation
import Dispatch
import Jay
import HTTP
import VaporSQLite


let drop = Droplet()
#if os(Linux)
    //let gate = GateController(_drop: drop)
#endif

//////////////////////////////////////////////////////////////////////////////////////////
//MARK: final metody

//
//let config = ConfigManager()
let firebaseManager = FirebaseController(url: Config().firebaseBaseUrl, key: "")
let tempController = TempController()
let pinController = PinController()
pinController.loadPinsConfigFromFirebase()
let notificationManager = PushNotificationsManager.sharedInstance
notificationManager.addRoutes(drop: drop)
pinController.addRoutes(drop: drop)
//tempController.setJob(withIntervalInSeconds: 300)
tempController.setLoopForMeasurments(withIntervalInMinutes: 1)
//
//
//tempController.readTempsFromAllThermometers()
//tempController.setLoopForMeasurments(withIntervalInMinutes: Config().measureInterval)
//
try drop.addProvider(VaporSQLite.Provider.self)

drop.get("stopmeasuring") { request in
    return try JSON(node: ["ok": tempController.stopLoop()])
}

drop.get("startmeasuring") { request in
    tempController.setLoopForMeasurments()
    return try JSON(node: ["ok": true])
}

drop.get("measuredValues","afterDate", Int.self) { request, date in
    let result = try drop.database?.driver.raw("SELECT value, value_type, time, probe FROM MeasuredData WHERE time > \(date);")
    guard let nodeArray = result?.nodeArray else {return try JSON(node: [])}
    var mva = [MeasuredValue]()
    for node in nodeArray {
        guard let value = node["value"]?.double,
        let value_type = node["value_type"]?.int,
        let time = node["time"]?.int,
        let probe = node["probe"]?.string
            else {return try JSON(node: [])}
        var mv = MeasuredValue(value: value, valueType: ValueType(rawValue: value_type)!, time: Date(timeIntervalSince1970: TimeInterval(time)), probe: probe)
        mva.append(mv)
    }
    return try JSON(node: mva)
}

drop.get("measuredValues","all") { request in
    let result = try drop.database?.driver.raw("SELECT value, value_type, time, probe FROM MeasuredData;")
    guard let nodeArray = result?.nodeArray else {return try JSON(node: [])}
    var mva = [MeasuredValue]()
    for node in nodeArray {
        guard let value = node["value"]?.double,
            let value_type = node["value_type"]?.int,
            let time = node["time"]?.int,
            let probe = node["probe"]?.string
            else {return try JSON(node: [])}
        var mv = MeasuredValue(value: value, valueType: ValueType(rawValue: value_type)!, time: Date(timeIntervalSince1970: TimeInterval(time)), probe: probe)
        mva.append(mv)
    }
    return try JSON(node: mva)
}

//////////////////////////////////////////////////////////////////////////////////////////
//MARK: testovacie metody

drop.get("/getConfig") { _ in
    let data = try? Jay(formatting: .prettified).dataFromJson(any: ConfigManager.sharedInstance.getConfig()) // [UInt8]
    if let string = try? data?.string() {
        return string!
    }
    return Response(status: .badRequest, body: "Okay")
}

drop.get("version") { request in
    let result = try drop.database?.driver.raw("SELECT sqlite_version()")
    return try JSON(node: result)
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


//
//drop.post("/setTempConfig") { request in
//    //    debugPrint(request.data["probes"]?.array?.first)
//
//    var probes = [[String: Any]]()
//
//    if let arr = request.data["probes"]?.array {
//        for pr in arr {
//            var probe: [String: Any] = [
//                "name": pr.object!["name"]!.string!,
//                "probeName": pr.object!["probeName"]!.string!
//            ]
//
//            if let min = pr.object!["minTemp"]?.double {
//                probe["minTemp"] = min
//            } else {
//                probe["minTemp"] = -1000
//            }
//            if let max = pr.object!["maxTemp"]?.double {
//                probe["maxTemp"] = max
//            } else {
//                probe["maxTemp"] = 1000
//            }
//            probes.append(probe)
//        }
//    }
//    drop.console.print("debug save 1", newLine: true)
//
//    ConfigManager.sharedInstance.writeToConfig(object: probes, forKey: "probes")
//    drop.console.print("debug save 2", newLine: true)
//
//
//    let response = Response(status: .ok, body: "Okay")
//
//    return response
//}
//
