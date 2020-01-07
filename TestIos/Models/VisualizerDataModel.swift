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
    var posX: Float = 0.0
    var posY: Float = 0.0
    var posZ: Float = 0.0
    var footSpeedX: Float = 0.0
    var footSpeedY: Float = 0.0
    var footSpeedZ: Float = 0.0
    var footAccelX: Float = 0.0
    var footAccelY: Float = 0.0
    var footAccelZ: Float = 0.0
    var lowerLegPosX: Float = 0.0
    var lowerLegPosY: Float = 0.0
    var lowerLegPosZ: Float = 0.0
    var lowerLegAccelX: Float = 0.0
    var lowerLegAccelY: Float = 0.0
    var lowerLegAccelZ: Float = 0.0
    var lowerLegSpeedX: Float = 0.00
    var lowerLegSpeedY: Float = 0.00
    var lowerlegSpeedZ: Float = 0.00
    var angleX:Float = 0.0
    var angleY:Float = 0.0
    var angleZ:Float = 0.0
    var lowerLegAngleX: Float = 0.00
    var lowerLegAngleY: Float = 0.00
    var lowerLegAngleZ: Float = 0.00
    var angleVeloX: Float = 0.0
    var angleVeloY: Float = 0.0
    var angleVeloZ: Float = 0.0
    var accelerationX: Float = 0.0
    var accelerationY:Float = 0.0
    var accelerationZ: Float = 0.0
    var previousVeloX:Float = 0.00
    var previousVeloY:Float = 0.00
    var previousVeloZ:Float = 0.00
    var footAngleX: Float = 0.00
    var footAngleY: Float = 0.00
    var footAngleZ: Float = 0.00
    var footAngleVeloX: Float = 0.00
    var footAngleVeloY: Float = 0.00
    var footAngleVeloZ: Float = 0.00
    var footAngleAccelX: Float = 0.00
    var footAngleAccelY: Float = 0.00
    var footAngleAccelZ: Float = 0.00
    var previousFootAngleX: Float = 0.00
    var previousFootAngleY: Float = 0.00
    var previousFootAngleZ: Float = 0.00
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
                let lowerLegAngleVeloMag = externalWorkMagnitude(x: angleVeloX, y: angleVeloY, z: angleVeloZ)
                
                
                // MARK: Calculating Torque
                /// Calculating Torque
                // Step 1 collect angles
                if let angles = visualizerData.calculateRelativeAngleForReferenceBone(bone: LowerLeg!, referenceBone: Foot!, frameIndex: i){
                    angleX = angles.x
                    angleY = angles.y
                    angleZ = angles.z
                }
                
                if let lowerLegAngles = visualizerData.calculateRelativeAngle(bone: LowerLeg!, frameIndex: i){
                    lowerLegAngleX = lowerLegAngles.x
                    lowerLegAngleY = lowerLegAngles.y
                    lowerLegAngleZ = lowerLegAngles.z
                }
                
                let lowerLegMag = externalWorkMagnitude(x: lowerLegAngleX, y: lowerLegAngleY, z: lowerLegAngleZ)
                
                
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
                
                if let footSpeed = visualizerData.calculateSpeed(bone: Foot!, frameIndex: i) {
                    footSpeedX = footSpeed.x
                    footSpeedY = footSpeed.y
                    footSpeedZ = footSpeed.z
                }
                let footSpeedMag = externalWorkMagnitude(x: footSpeedX, y: footSpeedY, z: footSpeedZ)
                
                if let footAccel = visualizerData.calculateAcceleration(bone: Foot!, frameIndex: i){
                    footAccelX = footAccel.x
                    footAccelY = footAccel.y
                    footAccelZ = footAccel.z
                }
                
                let footAccelMag = externalWorkMagnitude(x: footAccelX, y: footAccelY, z: footAccelZ)
                
                
                if let lowerLegPos = visualizerData.getPosition(bone: LowerLeg!, frameIndex: i) {
                    lowerLegPosX = lowerLegPos.x
                    lowerLegPosY = lowerLegPos.y
                    lowerLegPosZ = lowerLegPos.z
                }
                
                let lowerLegPosMag = externalWorkMagnitude(x: lowerLegPosX, y: lowerLegPosY, z: lowerLegPosZ)
                
                if let lowerLegAccel = visualizerData.calculateAcceleration(bone: LowerLeg!, frameIndex: i) {
                    lowerLegAccelX = lowerLegAccel.x
                    lowerLegAccelY = lowerLegAccel.y
                    lowerLegAccelZ = lowerLegAccel.z
                }
                
                let lowerLegAccelMag = externalWorkMagnitude(x: lowerLegAccelX, y: lowerLegAccelY, z: lowerLegAccelZ)
                
                if let lowerLegSpeed = visualizerData.calculateSpeed(bone: LowerLeg!, frameIndex: i){
                    lowerLegSpeedX = lowerLegSpeed.x
                    lowerLegSpeedY = lowerLegSpeed.y
                    lowerlegSpeedZ = lowerLegSpeed.z
                }
                let lowerLegSpeedMag = externalWorkMagnitude(x: lowerLegSpeedX, y: lowerLegSpeedY, z: lowerlegSpeedZ)
                
                if let footAnkle = visualizerData.calculateRelativeAngle(bone: Foot!, frameIndex: i){
                    footAngleX = footAnkle.x
                    footAngleY = footAnkle.y
                    footAngleZ = footAnkle.z
                }
                
                let footAngleMag = externalWorkMagnitude(x: footAngleX, y: footAngleY, z: footAngleZ)
                
                if let footAnkleAngleVelo = visualizerData.calculateAngularVelocity(bone: Foot!, frameIndex: i){
                    footAngleVeloX = footAnkleAngleVelo.x
                    footAngleVeloY = footAnkleAngleVelo.y
                    footAngleVeloZ = footAnkleAngleVelo.z
                    
                    //function call for calulating angular acceleration
                    self.footAngleAccelX = angularAcceleration(angleVelocityPrevious: Float(previousFootAngleX), angleVelocityCurrent: footAngleVeloX, samplesPerSecond: 40)
                    self.accelerationY = angularAcceleration(angleVelocityPrevious: Float(previousFootAngleY), angleVelocityCurrent: footAngleVeloY, samplesPerSecond: 40)
                    self.accelerationZ = angularAcceleration(angleVelocityPrevious: Float(previousFootAngleZ), angleVelocityCurrent: footAngleVeloZ, samplesPerSecond: 40)
                    
                    //swap values for angular acceleration of the foot
                    previousFootAngleX = footAngleVeloX
                    previousFootAngleY = footAngleVeloY
                    previousFootAngleZ = footAngleVeloZ
                }
                let footAngleAccelMag = externalWorkMagnitude(x: footAngleAccelX, y: footAngleAccelY, z: footAngleAccelZ)
                let footAngleVeloMag = externalWorkMagnitude(x: footAngleVeloX, y: footAngleVeloY, z: footAngleVeloZ)
                
                //data holder for all of the system
                let data: [String: Float] = ["angleX":self.angleX,"angleY":self.angleY, "angleZ":self.angleZ,"lowerLegAngleMag":lowerLegMag, "lowerLegAngleX":lowerLegAngleX, "lowerLegAngleY":lowerLegAngleY, "lowerLegAngleZ":lowerLegAngleZ, "lowerLegAngleVeloMag":lowerLegAngleVeloMag, "lowerLegAngleVeloX": angleVeloX, "lowerLegAngleVeloY": angleVeloY, "lowerLegAngleVeloZ": angleVeloZ, "angleAccelX": self.accelerationX, "angleAccelY": self.accelerationY, "angleAccelZ": self.accelerationZ,"torqueMag": torqueMag ,"torqueX":self.torqueX, "torqueY":self.torqueY, "torqueZ":self.torqueZ, "posX": self.posX, "posY": self.posY, "posZ": self.posZ, "posMag": posMag,"lowerLegPosMag":lowerLegPosMag, "lowerLegPosX":lowerLegPosX, "lowerLegPosY":lowerLegPosY, "lowerLegPosZ":lowerLegPosZ, "lowerLegAccelMag":lowerLegAccelMag, "lowerLegAccelX":lowerLegAccelX, "lowerLegAccelY":lowerLegAccelY, "lowerLegAccelZ":lowerLegAccelZ,"lowerLegSpeedMag":lowerLegSpeedMag, "lowerLegSpeedX":lowerLegSpeedX,"lowerLegSpeedY": lowerLegSpeedY,"lowerLegSpeedZ": lowerlegSpeedZ, "footSpeedX":footSpeedX, "footSpeedY":footSpeedY, "footSpeedZ":footSpeedZ, "footSpeedMag":footSpeedMag, "footAccelX":footAccelX, "footAccelY":footAccelY, "footAccelZ":footAccelZ,"footAccelMag":footAccelMag,"footAngleX": footAngleX,"footAngleY": footAngleY, "footAngleZ": footAngleZ,"footAngleMag":footAngleMag,"footAngleVeloX": footAngleVeloX,"footAngleVeloY": footAngleVeloY,"footAngleVeloZ": footAngleVeloZ, "footAngleVeloMag":footAngleVeloMag, "footAngleAccelX":footAngleAccelX, "footAngleAccelY":footAngleAccelY,"footAngleAccelZ":footAngleAccelZ, "footAngleAccelMag":footAngleAccelMag]
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
                let data: [String: Float] = ["angleX":self.angleX,"angleY":self.angleY, "angleZ":self.angleZ, "angleVeloX": angleVeloX, "angleVeloY": angleVeloY, "angleVeloZ": angleVeloZ, "angleAccelX": 0.0, "angleAccelY": 0.0, "angleAccelZ": 0.0,"torqueMag":0.0 ,"torqueX":self.torqueX, "torqueY":self.torqueY, "torqueZ":self.torqueZ, "posX": 0.0, "posY": 0.0, "posZ": 0.0, "posMag": 0.0, "lowerLegPosY":lowerLegPosY, "lowerLegPosZ":lowerLegPosZ, "lowerLegAccelX":lowerLegAccelX, "lowerLegAccelY":lowerLegAccelY,"lowerLegAccelMag":0.00, "lowerLegAccelZ":lowerLegAccelZ, "lowerLegSpeedMag":0.00, "lowerLegSpeedX":lowerLegSpeedX,"lowerLegSpeedY": lowerLegSpeedY,"lowerLegSpeedZ": lowerlegSpeedZ, "footSpeedX":footSpeedX, "footSpeedY":footSpeedY, "footSpeedZ":footSpeedZ, "footSpeedMag":0.0, "footAccelX":footAccelX, "footAccelY":footAccelY, "footAccelZ":footAccelZ,"footAccelMag":0.0,"footAngleX": footAngleX,"footAngleY": footAngleY, "footAngleZ": footAngleZ,"footAngleMag":0.00,"footAngleVeloX": footAngleVeloX,"footAngleVeloY": footAngleVeloY,"footAngleVeloZ": footAngleVeloZ, "footAngleVeloMag":0.0, "footAngleAccelX":footAngleAccelX, "footAngleAccelY":footAngleAccelY,"footAngleAccelZ":footAngleAccelZ, "footAngleAccelMag": 0.00]
                    self.imuData.append(data)
            }
        }
        
        return self.imuData
    }
}


