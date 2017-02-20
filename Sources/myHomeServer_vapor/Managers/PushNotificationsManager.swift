//
//  PushNotificationsManager.swift
//  myHomeServer_vapor
//
//  Created by Marek Slaninka on 15.10.16.
//
//

import Foundation
import Vapor
import HTTP

struct Device {
    var deviceName: String
    var deviceKey: String
}

class PushNotificationsManager: NSObject {
    static let sharedInstance: PushNotificationsManager = PushNotificationsManager()
    
//    let result = try? drop.database?.driver.raw("INSERT INTO MeasuredData(value, value_type, time, probe, syncedInFB)", [Node(value), Node(valueType.rawValue), time.timeIntervalSince1970, probe, syncedInFB!])

    var devices: [Device]?
    
    override init() {
        super.init()
        self.devices = self.getPhoneKeys()

    }
    
    func addRoutes(drop: Droplet) {
        let notifGroup = drop.grouped("notifications")
        notifGroup.post("add") { request in
            guard let name = request.json?["deviceName"]?.string else {return Abort.custom(status: Status.failedDependency, message: "deviceName missing") as! ResponseRepresentable}
            guard let key = request.json?["deviceKey"]?.string else {return Abort.custom(status: Status.failedDependency, message: "deviceKey missing") as! ResponseRepresentable}
            self.setPhoneNotification(deviceName: name, deviceKey: key)
            return Response(status: .ok, body: "Okay")
        }
        
        notifGroup.post("remove") { request in
            guard let name = request.json?["deviceName"]?.string else {return Abort.custom(status: Status.failedDependency, message: "deviceName missing") as! ResponseRepresentable}
            self.removeDevice(withName: name)
            return Response(status: .ok, body: "Okay")
        }
    }
    
    
    func setPhoneNotification(deviceName: String, deviceKey: String) {
        if (self.devices?.contains(where: { (device) -> Bool in
            return device.deviceName == deviceName
        }))! {
            self.removeDevice(withName: deviceName)
        }
        _ = try? drop.database?.driver.raw("INSERT INTO NotificationDevices(device_name, device_key)", [deviceName, deviceKey])
    }
    
    func getPhoneKeys() -> [Device]{
        return [Device]()
    }
    
    func removeDevice(withName name: String) {
        _ = try? drop.database?.driver.raw("DELETE FROM NotificationDevices WHERE device_name = \(name)")
    }
    
    func sendNotification(withTitle title: String, body: String, completitionBlock: ((String?)->())?, drop: Droplet) -> Response? {
        let param = [
            "to": "fVaWMgWu35M:APA91bFBOVsrJ8R-D3MZ8vvWRibupTEHA-InkaJqOhaMhxaTkKIPHfpzswxnguVQb4Zlci1SptFX8qKZYTurh45w-Mo_yk1A6gv8UwwllwhmucQjPibNwElQW9DCm_TCChMmvgk8j4lI",
            "priority": 10,
            "notification":[
                "title": title,
                "body": body,
                "badge": 0,
                "sound":"default"
            ]
//            "data": [
//                "attachment-url": "https://api.buienradar.nl/Image/1.0/RadarMapNL"
//            ]
        ] as [String : Any]

        let jsonBody = try? JSONSerialization.data(withJSONObject: param, options: .prettyPrinted)
        let jsonString = String.init(data: jsonBody!, encoding: String.Encoding.ascii)
         do {
           let response = try drop.client.post(Config().pushFirebaseUrl, headers: ["Content-Type":"application/json","Authorization":"key="+Config().pushAuthKey], query: [:], body: jsonString!)
            return response
        } catch  {
            debugPrint(error)
        }
        return nil
    }
}
