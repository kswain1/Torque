//
//  AppDelegate.swift
//  TutorialApp
//
//  Created by Elekes Tamas on 7/28/17.
//  Copyright © 2017 Notch Interfaces. All rights reserved.
//

import UIKit
import WearnotchSDK

@UIApplicationMain
class AppDelegate: UIResponder, UIApplicationDelegate {
    
    var window: UIWindow?
    
    // initialize the notch mock service
    public static let notchAPI = try! NotchAPI.Builder().build()
    public static let service = notchAPI.service
    
}

