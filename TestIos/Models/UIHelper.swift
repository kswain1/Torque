//
//  UIHelper.swift
//  WearnotchSDK
//
//  Created by Elekes Tamas on 9/5/17.
//  Copyright © 2017 Notch Interfaces. All rights reserved.
//

import Foundation
import UIKit
import WearnotchSDK

extension UIViewController {
    
    func showToast(_ message : String = "Success") {
        DispatchQueue.main.async {
            let toastLabel = UILabel(frame: CGRect(x: self.view.frame.size.width/2 - 125, y: self.view.frame.size.height-80, width: 250, height: 35))
            toastLabel.backgroundColor = UIColor.black.withAlphaComponent(0.6)
            toastLabel.textColor = UIColor.white
            toastLabel.textAlignment = .center;
            toastLabel.font = UIFont(name: "Montserrat-Light", size: 12.0)
            toastLabel.text = message
            toastLabel.alpha = 1.0
            toastLabel.layer.cornerRadius = 10;
            toastLabel.clipsToBounds  =  true
            self.view.addSubview(toastLabel)
            UIView.animate(withDuration: 5.0, delay: 0.1, options: .curveEaseOut, animations: {
                toastLabel.alpha = 0.0
            }, completion: {(isCompleted) in
                toastLabel.removeFromSuperview()
            })
        }
    }
    
    func showFailure(notchError: NotchError) {
        switch notchError {
        case .internalError(let message):
            self.showFailedActionAlert(message: message ?? "Internal error")
        case .operationError(let status):
            self.showFailedActionAlert(message: String(describing: status))
        case .corruptedMeasurement:
            self.showFailedActionAlert(message: "Corrupted measurement")
        }
    }
    
    func showFailedBleConnection(message: String = "No EMG Bluetooth Connection"){
        let alert = UIAlertController(
            title: "Action failed",
            message: message,
            preferredStyle: UIAlertController.Style.alert
        )
        alert.addAction(UIAlertAction(
            title: "Ok",
            style: UIAlertAction.Style.default,
            handler: nil
        ))
        DispatchQueue.main.async {
            self.present(alert, animated: false, completion:nil)
        }
    }
    
    func showFailedActionAlert(message: String) {
        let alert = UIAlertController(
            title: "Action failed",
            message: message,
            preferredStyle: UIAlertController.Style.alert)
        alert.addAction(UIAlertAction(
            title: "OK",
            style: UIAlertAction.Style.default,
            handler: nil))
        
        DispatchQueue.main.async {
            self.present(alert, animated: false, completion: nil)
        }
    }
}
