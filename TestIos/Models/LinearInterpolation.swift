//
//  LinearInterpolation.swift
//  TestIos
//
//  Created by kehlin swain on 12/18/19.
//  Copyright © 2019 kehlin swain. All rights reserved.
//

import Foundation
import Accelerate

struct LinearInterpolation {

private var n : Int
private var x : [Double]
private var y : [Double]
init (x: [Double], y: [Double]) {
    assert(x.count == y.count)
    self.n = x.count-1
    self.x = x
    self.y = y
}

func Interpolate(t: Double) -> Double {
    if t <= x[0] { return y[0] }
    for i in 1...n {
        if t <= x[i] {
            let ans = (t-x[i-1]) * (y[i] - y[i-1]) / (x[i]-x[i-1]) + y[i-1]
            return ans
        }
    }
    return y[n]
    }
}

class LinearInterpolationResult {
    var original_times:[Double] = []
    var original_values: [Double] = []
    var newValueLength:Int
    var new_values = [Double]()
    
    init(newValue: Int) {
        self.newValueLength = newValue
    }
    
    func setLinearInterpolation (originalTimes: [Double], originalValues:[Double]){
        let stride = vDSP_Stride(1)
        new_values = [Double](repeating: 0,
        count: newValueLength)
    

        vDSP_vgenpD(original_values, stride,
                    original_times, stride,
                    &self.new_values, stride,
                    vDSP_Length(self.newValueLength),
                    vDSP_Length(original_values.count))
        let myVar = self.new_values
    }
    
    func getLinearInterpolation () -> [Double] {
        return self.new_values
    }
    
    
}
