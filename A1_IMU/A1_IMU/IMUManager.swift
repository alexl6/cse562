//
//  IMUManager.swift
//  CSE 562
//
//  Created by Alex on 4/29/25.
//

import CoreMotion

class IMUManager {
    static let shared = IMUManager()
    
    let motion = CMMotionManager()
    let updateInterval = 1.0 / 30.0
    var accel_bias: (x: Double, y: Double, z: Double) = (0.0, 0.0, 0.0)
    var gyro_bias: (x: Double, y: Double, z: Double) = (0.0, 0.0, 0.0)
    
    func start() {
        if (self.motion.isAccelerometerAvailable && self.motion.isGyroAvailable) {
            self.motion.accelerometerUpdateInterval = updateInterval
            self.motion.gyroUpdateInterval = updateInterval
            self.motion.startAccelerometerUpdates()
            self.motion.startGyroUpdates()
        }
    }
    
    func isIMURunning() -> Bool {
        return (self.motion.isAccelerometerAvailable && self.motion.isGyroAvailable) &&
        (self.motion.isAccelerometerActive && self.motion.isGyroActive)
    }
    
    func stop() {
        if (self.motion.isAccelerometerAvailable && self.motion.isGyroAvailable) {
            self.motion.stopAccelerometerUpdates()
            self.motion.stopGyroUpdates()
        }
    }
    
    func getAccel() -> CMAccelerometerData? {
        return self.motion.accelerometerData
    }
    
    func getGyro() -> CMGyroData? {
        return self.motion.gyroData
    }
    
    func setSensorBias(bias: (acc_x: Double, acc_y: Double, acc_z: Double, gyro_x: Double, gyro_y: Double, gyro_z: Double)) {
        // https://developer.apple.com/documentation/coremotion/getting-raw-accelerometer-events
        accel_bias = (0 - bias.acc_x, 0 - bias.acc_y, -1 - bias.acc_z)
        gyro_bias = (0 - bias.gyro_x, 0 - bias.gyro_y, 0 - bias.gyro_z)
    }

}
