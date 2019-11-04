//
//  SensoryTypeViewController.swift
//  TestIos
//
//  Created by kehlin swain on 10/16/19.
//  Copyright © 2019 kehlin swain. All rights reserved.
//

import UIKit

protocol SensorPickerViewDelegate: class {
    func didSelect(sensor: Int, of type: String)
}

class SensoryTypeViewController: UIViewController {
    //MARK: - Outlets
    @IBOutlet weak var typePicker: UIPickerView!
    
    //MARK: Variables
    weak var pickerDelegate: SensorPickerViewDelegate?
    
    fileprivate var selectedTypes = [Int]()
    var typePickerAvailableTypes = [String: Int]()
    
    var peripheralNumber: Int!
    
    lazy var typePickerAvailableTypesKeys : [String] = {
        let keys = [String](self.typePickerAvailableTypes.keys)
        return keys
    }()
    
    //MARK: LIFE CYCLE
    override func viewDidLoad() {
        super.viewDidLoad()
        typePicker.delegate = self
        typePicker.dataSource = self

        // Do any additional setup after loading the view.
    }
    
    //allow the picker type to disappear after someone has selected a peripheral
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        if selectedTypes.isEmpty, let key = typePickerAvailableTypes.keys.first {
                pickerDelegate?.didSelect(sensor: peripheralNumber, of: key)
        }
    }

}

//MARK: UIPickerView Delegate and Datasource
extension SensoryTypeViewController: UIPickerViewDelegate, UIPickerViewDataSource {
    func numberOfComponents(in pickerView: UIPickerView) -> Int {
        return 1
    }
    
    func pickerView(_ pickerView: UIPickerView, numberOfRowsInComponent component: Int) -> Int {
        return typePickerAvailableTypes.count
    }
    
    func pickerView(_ pickerView: UIPickerView, titleForRow row: Int, forComponent component: Int) -> String? {
        return typePickerAvailableTypesKeys[row]
    }
    
    func pickerView(_ pickerView: UIPickerView, didSelectRow row: Int, inComponent component: Int) {
        selectedTypes.append(row + 1)
        dismiss(animated: true, completion: {
            self.pickerDelegate?.didSelect(sensor: self.peripheralNumber, of: self.typePickerAvailableTypesKeys[row])
        })
    }
}
