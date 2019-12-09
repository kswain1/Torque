//
//  SensorBodyAttachmentViewController.swift
//  TestIos
//
//  Created by kehlin swain on 12/9/19.
//  Copyright © 2019 kehlin swain. All rights reserved.
//
import Foundation
import UIKit

class SensorBodyAttachmentViewController: UIViewController {
    
    var sensorConfiguration: ConfigurationType?
    override func viewDidLoad() {
        super.viewDidLoad()
        //self.SensorConfigurationSetup()

        // Do any additional setup after loading the view.
    }
    
    @IBAction func complete(_ sender: UIButton){
        self.dismiss(animated: true, completion: nil)
    }
    /*
    // MARK: - Navigation

    // In a storyboard-based application, you will often want to do a little preparation before navigation
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        // Get the new view controller using segue.destination.
        // Pass the selected object to the new view controller.
    }
    */
    
    func SensorConfigurationSetup() {
       let altURL = Bundle.main.url(forResource: "config_1_chest", withExtension: ".json")
        
        var URL = self.sensorConfiguration?.configurationFile
        let data = try! NSData(contentsOf: URL!, options: .mappedIfSafe)
        
        
        if let url = URL {
            var jsonResult: NSDictionary = try! JSONSerialization.jsonObject(with: data as! Data, options: .mutableLeaves) as! NSDictionary
            print(jsonResult)
            
        }
        
    }
}
