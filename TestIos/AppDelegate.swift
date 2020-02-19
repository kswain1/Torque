//
//  AppDelegate.swift
//  TutorialApp
//
//  Created by Elekes Tamas on 7/28/17.
//  Copyright © 2017 Notch Interfaces. All rights reserved.
///Users/kehlinswain/Desktop/GoogleService-Info (1).plist

import UIKit
import WearnotchSDK
import Firebase
@UIApplicationMain
class AppDelegate: UIResponder, UIApplicationDelegate {
    
    var window: UIWindow?
    
    // initialize the notch mock service
    public static let notchAPI = try! NotchAPI.Builder().build()
    public static let service = notchAPI.service
    
    
    func application(_ application: UIApplication,
       didFinishLaunchingWithOptions launchOptions:
        [UIApplication.LaunchOptionsKey: Any]?) -> Bool {
       FirebaseApp.configure()
       return true
     }
}

