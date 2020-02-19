//
//  Extensions.swift
//  TestIos
//
//  Created by kehlin swain on 10/17/19.
//  Copyright © 2019 kehlin swain. All rights reserved.
//

import Foundation
import CoreBluetooth

// Dictionary extensions
extension Dictionary where Value: Equatable {
    /// Filters for all key based  on value
    func allKeys(forValue val: Value) -> [Key] {
        return self.filter { $1 == val }.map { $0.0 }
    }
    func keyFor(value: Value) -> Key? {
        guard let index = index(where: { $0.1 == value }) else { return nil }
        return self[index].0
    }
}

extension Double {
    /// Rounds the double to decimal places value
    func rounded(toPlaces places:Int) -> Double {
        let divisor = pow(10.0, Double(places))
        return (self * divisor).rounded() / divisor
    }
}
    //TODO: Grab 8 bites of the array that is sent to create more accuracy from sensor
    //function allows the byte array to be converted into integers

func emgDataConvert(from characteristics: CBCharacteristic ) -> [Double] {
    guard let charData = characteristics.value else {return [0.0]}

    //how to convert UInt8 to UInt16 bytes
    //how to convert UInt8 to UInt16 bytes
    var byteArray = [UInt8](repeating:0, count: charData.count)
    charData.copyBytes(to: &byteArray, count: charData.count)


    //this is the correct value for the first index in the array ( I don't know how to get the correct value for the other 19 elements in the array)
    let newArray = Array(charData)
//        print("New Array", newArray)
    var finalArray: [UInt16] = []

    for a in stride(from: 0, to: 14, by: 2) {
        let littleArray = [newArray[a], newArray[a+1]]
//            print("Little ARray", littleArray)
        let littleData = Data(littleArray)
        let gottenDouble: UInt16 = littleData.withUnsafeBytes({ $0.pointee })
        finalArray.append(gottenDouble)
    }

    var emgConvertedArray : [Double] = []
    for i in finalArray {
        emgConvertedArray.append(Double(i))
    }
    return emgConvertedArray
}

func externalWorkMagnitude(x: Float, y: Float, z: Float) -> Float{
    var results = x*x + y*y + z*z
    results = results.squareRoot()
    return results
}

func angularAcceleration(angleVelocityPrevious: Float, angleVelocityCurrent: Float, samplesPerSecond: Int) -> Float {
    let velocityDelta = angleVelocityCurrent - angleVelocityPrevious
    let ElapsedTime = Float(1.0/Float(samplesPerSecond))
    let angAcceleration = velocityDelta/Float(ElapsedTime)
    return angAcceleration
}

func jointTorque(angularAcceleration: Float, angle: Float, nueroMuscle: Float = 1.0, mass: Float = 1.0) -> Float{
    var torque = mass * angularAcceleration * angle * nueroMuscle
    //measure distance from imu follow up
    return torque
}

func forceAnkle(linearAccel: Float, angularAccel: Float, angularVelo: Float, mass: Float = 79, length: Float = 1.0) -> Float{
    var force = linearAccel + angularAccel + angularVelo
    return force
}

// 

func computeScore (emgArray: Double) -> [Double] {
    return [0.0, 0.0]
}

protocol MVCDelegate: class {
    func addMVC(MVC: (String,Double))
}

protocol PosteriorMVCDelegate: class {
    func addPostMVC(MVC: (String,Double,String,Double))
}

protocol BluetoothControllerDelegate {
    func didAddPeripherals(array: [Peripheral]?, btmanager: CBCentralManager?)
}


