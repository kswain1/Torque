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
    
    @IBOutlet weak var sensorConfigImage: UIImageView!
    var sensorConfiguration: ConfigurationType?
    override func viewDidLoad() {
        super.viewDidLoad()
        //self.SensorConfigurationSetup()
        self.setUpImageView()
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
    func setUpImageView() {
        let sensorConfigDic =  ["Left Ankle & Right Thigh (5)":"left lower leg configuration", "Right Ankle & Left Thigh (5)":"right lower leg configuration", "Chest (1)":"chest"]
        let name = sensorConfiguration?.name
        if let sensorName = sensorConfigDic[name!] {
            sensorConfigImage.image = UIImage(named: sensorName)
        }
    }
    
    //TODO: autonomously place sensor on person based on their chosen configuraiton
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
