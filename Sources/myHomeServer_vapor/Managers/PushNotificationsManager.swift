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
        
        
        do {
            let spotifyResponse = try drop.client.get("https://api.weixin.qq.com/cgi-bin/token")
            print(spotifyResponse)
        } catch let error  {
            print(error)
        }
        
        
        let param = [
            "to": "fVaWMgWu35M:APA91bFBOVsrJ8R-D3MZ8vvWRibupTEHA-InkaJqOhaMhxaTkKIPHfpzswxnguVQb4Zlci1SptFX8qKZYTurh45w-Mo_yk1A6gv8UwwllwhmucQjPibNwElQW9DCm_TCChMmvgk8j4lI",
            "priority": 10,
            "notification":[
                "title": title,
                "body": body,
                "badge": 0,
                "sound":"default"
            ],
//            "data": [
//                "attachment-url": "https://api.buienradar.nl/Image/1.0/RadarMapNL"
//            ]
        ] as [String : Any]
        
//        var request = URLRequest(url: URL(string: Config().pushFirebaseUrl)!)
//        request.httpMethod = "POST"
//        request.httpBody = try? JSONSerialization.data(withJSONObject: param, options: .prettyPrinted)
//        request.addValue("application/json", forHTTPHeaderField: "Content-Type")
//        request.addValue("Authorization", forHTTPHeaderField: "key="+Config().pushAuthKey)
        let jsonBody = try? JSONSerialization.data(withJSONObject: param, options: .prettyPrinted)
        let heders = ["application/json":"Content-Type","Authorization":"key="+Config().pushAuthKey]

        
         do {
           let response = try drop.client.post(Config().pushFirebaseUrl, headers: ["application/json":"Content-Type","Authorization":"key="+Config().pushAuthKey], query: param as! [String : CustomStringConvertible], body: Body.data([]))
            return response
        } catch  {
            debugPrint(error)
        }
        let response = try? drop.client.post(Config().pushFirebaseUrl, headers: ["application/json":"Content-Type","Authorization":"key="+Config().pushAuthKey], query: param as! [String : CustomStringConvertible], body: Body.data((jsonBody?.makeBytes())!))
        
        return response
        
//        URLSession.shared.dataTask(with: request,
//            completionHandler: { (data, response, error) in
//                guard error == nil else {return}
//                guard data != nil else {return}
//                var dict: [String: AnyObject]?
//                dict = try? JSONSerialization.jsonObject(with: data!,
//                                                         options: .allowFragments) as! [String: AnyObject]
//                if let dict = dict {
//                    if let success = dict["success"] as? Int {
//                        if let failure = dict["failure"] as? Int {
//                            if success == 1 && failure == 0 {
//                                //Push notifikacia presla
//                                
//                            }
//                            completitionBlock?("\(success)")
//                        }
//                    }
//                }
//                //Spustenie vykonávania dátového tasku
//        }).resume()
    }
    
    
    
}
