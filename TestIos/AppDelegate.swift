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
import GoogleSignIn

@UIApplicationMain
class AppDelegate:UIResponder, UIApplicationDelegate , GIDSignInDelegate{
    func sign(_ signIn: GIDSignIn!, didSignInFor user: GIDGoogleUser!, withError error: Error!) {
        
    }
    
    
    var window: UIWindow?
    
    // initialize the notch mock service
    public static let notchAPI = try! NotchAPI.Builder().build()
    public static let service = notchAPI.service
    
    
    func application(_ application: UIApplication,
       didFinishLaunchingWithOptions launchOptions:
        [UIApplication.LaunchOptionsKey: Any]?) -> Bool {
        FirebaseApp.configure()
        GIDSignIn.sharedInstance().clientID = FirebaseApp.app()?.options.clientID
        GIDSignIn.sharedInstance().delegate = self
       return true
     }
    func application(_ app: UIApplication, open url: URL, options: [UIApplication.OpenURLOptionsKey : Any] = [:]) -> Bool {
        return GIDSignIn.sharedInstance().handle(url)
    }
}

