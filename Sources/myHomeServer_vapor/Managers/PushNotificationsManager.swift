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


class PushNotificationsManager: NSObject {
    static let sharedInstance: PushNotificationsManager = PushNotificationsManager()
    
    
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
            
            debugPrint(response)
            
            return response
        } catch  {
            debugPrint(error)
        }
        return nil
    }
}
