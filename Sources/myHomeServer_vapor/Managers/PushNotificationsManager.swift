//
//  PushNotificationsManager.swift
//  myHomeServer_vapor
//
//  Created by Marek Slaninka on 15.10.16.
//
//

import Foundation


class PushNotificationsManager: NSObject {
    static let sharedInstance: PushNotificationsManager = PushNotificationsManager()
    
    
    func sendNotification(withTitle title: String, body: String, completitionBlock: ((String?)->())?){
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
        
        var request = URLRequest(url: URL(string: Config().pushFirebaseUrl)!)
        request.httpMethod = "POST"
        request.httpBody = try? JSONSerialization.data(withJSONObject: param, options: .prettyPrinted)
        request.addValue("application/json", forHTTPHeaderField: "Content-Type")
        request.addValue("Authorization", forHTTPHeaderField: "key="+Config().pushAuthKey)
        
        URLSession.shared.dataTask(with: request,
            completionHandler: { (data, response, error) in
                guard error == nil else {return}
                guard data != nil else {return}
                var dict: [String: AnyObject]?
                dict = try? JSONSerialization.jsonObject(with: data!,
                                                         options: .allowFragments) as! [String: AnyObject]
                if let dict = dict {
                    if let success = dict["success"] as? Int {
                        if let failure = dict["failure"] as? Int {
                            if success == 1 && failure == 0 {
                                //Push notifikacia presla
                                
                            }
                            completitionBlock?("\(success)")
                        }
                    }
                }
                //Spustenie vykonávania dátového tasku
        }).resume()
    }
    
    
    
}
