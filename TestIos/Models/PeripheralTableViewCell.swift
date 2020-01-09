//
//  PeripheralTableViewCell.swift
//  TestIos
//
//  Created by kehlin swain on 10/16/19.
//  Copyright © 2019 kehlin swain. All rights reserved.
//

import Foundation
import UIKit

class PeripheralTableViewCell: UITableViewCell {
    @IBOutlet weak var sensorName: UILabel!
    @IBOutlet weak var SensorMuscleType: UILabel!
    
    var peripheral: Peripheral? {didSet{ updateUI() }}
    
    func updateUI() {
        if let peripheral = peripheral {
            sensorName.text = peripheral.name
            
            var detailText = ""
            guard let type = peripheral.type else { return}
            switch type{
                case 1: detailText = "Selected as Peroneals"
                case 2: detailText = "Selected as Tibilar Anterior"
                case 3: detailText = "Selected as Lateral Gastro"
                case 4: detailText = "Selected as Medial Gastro"
                default: detailText  = "No selected type"
            }
            
            SensorMuscleType.text = detailText
            self.accessoryType = peripheral.isSelected ? .checkmark : .none
        }
    }
    
    override func awakeFromNib() {
        super.awakeFromNib()
        SensorMuscleType.text = "no selected text"
    }
}
