// Copyright © 2018. Notch Interfaces. All rights reserved.

import Foundation

enum ConfigurationType: String {
    case chest1 = "config_1_chest.js"
//    case rightArm2 = "config_2_right_arm.js"
//    case rightArm3 = "config_3_right_arm.js"
//    case upperBody5 = "config_5_upper_body.js"
//    case lowerBody6 = "config_6_lower_body.js"
//    case lowerBody5 = "config_5_lower_body.js"
//    case upperBody6 = "config_6_upper_body.js"
//    case rightLowerBody5 = "config_5_lower_right_leg.js"
//    case fullBody11 = "config_11_full_body.js"
    case rightAnkleLeftThigh5 = "config_5_leg_rightAnkle_leftThigh.js"
    case leftAnkleLeftThigh5 = "config_5_leg_leftAnkle_leftThigh.js"
    
    var name: String {
        switch self {
        case .chest1: return "Chest (1)"
//        case .rightArm2: return "Right arm (2)"
//        case .rightArm3: return "Right arm (3)"
//        case .upperBody5: return "Upper body (5)"
//        case .lowerBody5: return "Lower Body (5) :)"
//        case .rightLowerBody5: return "Right Leg Lower (5)"
//        case .upperBody6: return "Upper body (6)"
//        case .lowerBody6: return "Loser body (6)"
//        case .fullBody11: return "Full body (11)"
        case .rightAnkleLeftThigh5: return "Right Ankle & Left Thigh (5)"
        case .leftAnkleLeftThigh5: return "Left Ankle & Right Thigh (5)"
        }
    }
    
    var notchCount: Int {
        switch self {
        case .chest1: return 1
//        case .rightArm2: return 2
//        case .rightArm3: return 3
//        case .upperBody5: return 5
//        case .lowerBody5: return 5
//        case .rightLowerBody5: return 5
//        case .upperBody6: return 6
//        case .lowerBody6: return 6
//        case .fullBody11: return 11
        case .rightAnkleLeftThigh5: return 5
        case .leftAnkleLeftThigh5: return 5
        
        }
    }
    
    var configurationFile: URL? {
        guard let path = Bundle.main.path(forResource: rawValue, ofType: nil) else {
            return nil
        }
        
        return URL(fileURLWithPath: path)
    }
    
    static var allItems: [ConfigurationType] {
        return [.chest1, .rightAnkleLeftThigh5, .leftAnkleLeftThigh5]
//        return [.rightLowerBody5, .rightAnkleLeftThigh5, .chest1, .rightArm2, .rightArm3, .upperBody5, .upperBody6, .lowerBody6, .fullBody11, .lowerBody5, .leftAnkleLeftThigh5]
    }
}
