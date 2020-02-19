//
//  email.swift
//  TestIos
//
//  Created by kehlin swain on 11/20/19.
//  Copyright © 2019 kehlin swain. All rights reserved.
//

import Foundation
import UIKit
import MessageUI

class EmailComposer: NSObject, MFMailComposeViewControllerDelegate {
    
    func canSendMail() -> Bool {
        return MFMailComposeViewController.canSendMail()
    }
    
    
    // MARK: MFMailComposeViewControllerDelegate Method
    
    func mailComposeController(_ controller: MFMailComposeViewController, didFinishWith result: MFMailComposeResult, error: Error?) {
        controller.dismiss(animated: true, completion: nil)
    }
}




