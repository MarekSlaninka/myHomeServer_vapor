//
//  Config.swift
//  myHomeServer_vapor
//
//  Created by Marek Slaninka on 09.11.16.
//
//

import Foundation

class Config: NSObject {
    public let pushAuthKey = "AIzaSyDaFluLsUsb2g5mT2USjZnqjPIUH-SDT90"
    public let pushFirebaseUrl = "https://fcm.googleapis.com/fcm/send"
    public let firebaseBaseUrl = "https://myhome-63718.firebaseio.com/"
    public let probeConfigUrl = "tempConfig"
    public let pinsConfigUrl = "pinsConfig"
    public let tempSaveUrl = "temperatures"
    public let measureInterval: Double = 5
}
