//
//  VisualizerDataModel.swift
//  TestIos
//
//  Created by kehlin swain on 12/10/19.
//  Copyright © 2019 kehlin swain. All rights reserved.
//

import Foundation
import WearnotchSDK

struct VisualizerImuDictionary {
    var angleVeloX: Float = 0.0
    var angleVeloY: Float = 0.0
    var angleVeloZ: Float = 0.0
    var posX: Float = 0.0
    var posY: Float = 0.0
    var posZ: Float = 0.0
    var angleX:Float = 0.0
    var angleY:Float = 0.0
    var angleZ:Float = 0.0
    var accelerationX: Float = 0.0
    var accelerationY:Float = 0.0
    var accelerationZ: Float = 0.0
    var previousVeloX:Float = 0.00
    var previousVeloY:Float = 0.00
    var previousVeloZ:Float = 0.00
    var Foot: NotchBone? = nil
    var LowerLeg: NotchBone? = nil
    var torqueX: Float = 0.0
    var torqueY: Float = 0.0
    var torqueZ: Float = 0.0
    var imuData: [[String: Float]] = []
    
    mutating func setLeg(leg: String, skeleton: NotchSkeleton){
        //check which leg
        if leg == "Right"{
            self.Foot = skeleton.bone("RightFootTop")!
            self.LowerLeg = skeleton.bone("RightLowerLeg")!
        }else {
            self.Foot = skeleton.bone("LeftFootTop")!
            self.LowerLeg = skeleton.bone("LeftLowerLeg")!
        }
    }
    
    mutating func computeImuDict(leg: String, visualizerData: NotchVisualiserData, measurementUrl: URL) -> [[String:Float]] {
        
        for i in 1..<visualizerData.frameCount{
            if i > 1 {
                //set skeleton bone
                setLeg(leg: leg, skeleton: visualizerData.skeleton)
                
                //calculate angular velocity
                if let vector = visualizerData.calculateAngularVelocity(bone: LowerLeg!, frameIndex: i){
                    self.angleVeloX = vector.x
                    self.angleVeloY = vector.y
                    self.angleVeloZ = vector.z
                    
                    //function call for calulating angular acceleration
                    self.accelerationX = angularAcceleration(angleVelocityPrevious: Float(previousVeloX), angleVelocityCurrent: vector.x, samplesPerSecond: 40)
                    self.accelerationY = angularAcceleration(angleVelocityPrevious: Float(previousVeloY), angleVelocityCurrent: vector.x, samplesPerSecond: 40)
                    self.accelerationZ = angularAcceleration(angleVelocityPrevious: Float(previousVeloZ), angleVelocityCurrent: vector.x, samplesPerSecond: 40)
                    
                    // swap values acceleration calculation
                    self.previousVeloX = Float(vector.x)
                    self.previousVeloY = Float(vector.y)
                    self.previousVeloZ = Float(vector.z)
                }
                
                // MARK: Calculating Torque
                /// Calculating Torque
                // Step 1 collect angles
                if let angles = visualizerData.calculateRelativeAngleForReferenceBone(bone: LowerLeg!, referenceBone: Foot!, frameIndex: i){
                    angleX = angles.x
                    angleY = angles.y
                    angleZ = angles.z
                }
                
                torqueX = jointTorque(angularAcceleration: accelerationX, angle: angleX)
                torqueY = jointTorque(angularAcceleration: accelerationY, angle: angleY)
                torqueZ = jointTorque(angularAcceleration: accelerationZ, angle: angleZ)
                let torqueMag = externalWorkMagnitude(x:torqueX,y:torqueY,z:torqueZ )
                
                //position calculations
                if let position = visualizerData.getPosition(bone: Foot!, frameIndex: i) {
                    posX = position.x
                    posY = position.y
                    posZ = position.z
                }
                
                let posMag = externalWorkMagnitude(x: posX, y: posY, z: posZ)
                
                //data holder for all of the system
                let data: [String: Float] = ["angleX":self.angleX,"angleY":self.angleY, "angleZ":self.angleZ, "angleVeloX": angleVeloX, "angleVeloY": angleVeloY, "angleVeloZ": angleVeloZ, "angleAccelX": self.accelerationX, "angleAccelY": self.accelerationY, "angleAccelZ": self.accelerationZ,"torqueMag": torqueMag ,"torqueX":self.torqueX, "torqueY":self.torqueY, "torqueZ":self.torqueZ, "posX": self.posX, "posY": self.posY, "posZ": self.posZ, "posMag": posMag]
                self.imuData.append(data)
                
                
            }else {
                
                //set skeleton bone
                setLeg(leg: leg, skeleton: visualizerData.skeleton)
                
                // for zero case there is no acceleration tracked
                // Step 1 collect angles
                if let vector = visualizerData.calculateAngularVelocity(bone: LowerLeg!, frameIndex: i){
                    self.angleVeloX = vector.x
                    self.angleVeloY = vector.y
                    self.angleVeloZ = vector.z
                }
                if let angles = visualizerData.calculateRelativeAngleForReferenceBone(bone: self.LowerLeg!, referenceBone: self.Foot!, frameIndex: i){
                    angleX = angles.x
                    angleY = angles.y
                    angleZ = angles.z
                }
                let data: [String: Float] = ["angleX":self.angleX,"angleY":self.angleY, "angleZ":self.angleZ, "angleVeloX": angleVeloX, "angleVeloY": angleVeloY, "angleVeloZ": angleVeloZ, "angleAccelX": 0.0, "angleAccelY": 0.0, "angleAccelZ": 0.0,"torqueMag":0.0 ,"torqueX":self.torqueX, "torqueY":self.torqueY, "torqueZ":self.torqueZ, "posX": 0.0, "posY": 0.0, "posZ": 0.0, "posMag": 0.0]
                    self.imuData.append(data)
            }
        }
        
        return self.imuData
    }
}


