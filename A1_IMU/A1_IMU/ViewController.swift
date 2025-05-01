//
//  ViewController.swift
//  CSE 562
//
//  Created by Alex on 4/7/25.
//

import UIKit
import CoreMotion

class ViewController: UIViewController {

    var data_list: [(timestamp: Double, acc_x: Double, acc_y: Double, acc_z: Double, gyro_x: Double, gyro_y: Double, gyro_z: Double )] = []
    var startTime: Date?
    var timer: Timer?
    let duration: Double = 60
    var logData: Bool = false


    @IBOutlet weak var progressLabel: UILabel!
    @IBOutlet weak var accel_x_data: UILabel!
    @IBOutlet weak var accel_y_data: UILabel!
    @IBOutlet weak var accel_z_data: UILabel!

    @IBOutlet weak var gyro_x_data: UILabel!
    @IBOutlet weak var gyro_y_data: UILabel!
    @IBOutlet weak var gyro_z_data: UILabel!
    
    @IBOutlet weak var start_stop_btn: UIButton!
    @IBOutlet weak var progressBar: UIProgressView!
    
    @IBAction func startLogging(_ sender: UIButton) {
        if (!logData) {
            data_list.removeAll()
            logData = true;
            startTime = Date()
            if !IMUManager.shared.isIMURunning() {
                IMUManager.shared.start()
            }
            sender.setTitle("Part 1: Cancel", for: UIControl.State.normal)
            timer = Timer.scheduledTimer(timeInterval: IMUManager.shared.updateInterval,
                                 target: self,
                                 selector: #selector(ViewController.collectData),
                                 userInfo: nil, repeats: true)
        } else {
            logData = false;
            clearAccelAndGyroDisp()
            if !IMUManager.shared.isIMURunning() {
                IMUManager.shared.stop()
            }
            sender.setTitle("Part 1: Start", for: UIControl.State.normal)
            progressBar.progress = 0
            progressLabel.text = ""
        }
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        
        timer?.invalidate()
        timer = nil
        logData = false
        saveDataToCSV();
        start_stop_btn.setTitle("Part 1: Start", for: UIControl.State.normal)
        clearAccelAndGyroDisp()
    }

    
    // Initialization
    required init?(coder: NSCoder) {
        super.init(coder: coder)
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        // Do any additional setup after loading the view.
        progressBar.progress = 0
        progressLabel.text = ""
    }

    @objc func collectData() {
        if !logData {
            return
        }
        
        let elapsedTime: Double = Date().timeIntervalSince(startTime!)
        if let accelData = IMUManager.shared.getAccel() {
            if let gyroData = IMUManager.shared.getGyro() {
                let acc = accelData.acceleration
                let gyro = gyroData.rotationRate
                data_list.append((elapsedTime, acc.x, acc.y, acc.z, gyro.x, gyro.y, gyro.z))
                displayAccelAndGyro(accel: acc, rotRate: gyro)
                progressBar.progress = Float(elapsedTime/duration)
                progressLabel.text = "\(Int(duration - elapsedTime))s left"
            }
        }
        if elapsedTime >= duration {
            timer?.invalidate()
            timer = nil
            logData = false
            if !IMUManager.shared.isIMURunning() {
                IMUManager.shared.stop()
            }
            saveDataToCSV();
            let avg = computeAverages()
            displayMean(mean: avg)
            IMUManager.shared.setSensorBias(bias: avg)
            start_stop_btn.setTitle("Part 1: Start", for: UIControl.State.normal)
        }
        
    }
    

    func displayAccelAndGyro(accel: CMAcceleration, rotRate: CMRotationRate) {
        accel_x_data.text = String(format: "x: %2.3f", accel.x)
        accel_y_data.text = String(format: "y: %2.3f", accel.y)
        accel_z_data.text = String(format: "z: %2.3f", accel.z)
        gyro_x_data.text = String(format: "x: %2.3f", rotRate.x)
        gyro_y_data.text = String(format: "y: %2.3f", rotRate.y)
        gyro_z_data.text = String(format: "z: %2.3f", rotRate.z)
        NSLog("accel_x: %2.3f | accel_y: %2.3f | accel_z: %2.3f | gyro_x: %2.3f | gyro_y: %2.3f | gyro_z: %2.3f",
              accel.x,
              accel.y,
              accel.z,
              rotRate.x,
              rotRate.y,
              rotRate.z)
    }
    
    func displayMean(mean: (acc_x: Double, acc_y: Double, acc_z: Double, gyro_x: Double, gyro_y: Double, gyro_z: Double)) {
        accel_x_data.text = String(format: "x_mean: %2.3f", mean.acc_x)
        accel_y_data.text = String(format: "y_mean: %2.3f", mean.acc_y)
        accel_z_data.text = String(format: "z_mean: %2.3f", mean.acc_z)
        gyro_x_data.text = String(format: "x_mean: %2.3f", mean.gyro_x)
        gyro_y_data.text = String(format: "y_mean: %2.3f", mean.gyro_y)
        gyro_z_data.text = String(format: "z_mean: %2.3f", mean.gyro_z)
    }
    
    func clearAccelAndGyroDisp(){
        accel_x_data.text = "x: N/A"
        accel_y_data.text = "y: N/A"
        accel_z_data.text = "z: N/A"
        gyro_x_data.text = "x: N/A"
        gyro_y_data.text = "y: N/A"
        gyro_z_data.text = "z: N/A"
    }
    
    func saveDataToCSV(){
        var csvString = "timestamp,accel_x,accel_y,accel_z,gyro_x,gyro_y,gyro_z\n"
        for entry in data_list {
            csvString.append("\(entry.timestamp),\(entry.acc_x),\(entry.acc_y),\(entry.acc_z),\(entry.gyro_x),\(entry.gyro_y),\(entry.gyro_z)\n")
        }
        
        if let documentsDirectory = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first {
            let fileURL = documentsDirectory.appendingPathComponent("collected_data.csv")
            
            do {
                try csvString.write(to: fileURL, atomically: true, encoding: .utf8)
                print("CSV file saved at: \(fileURL)")
                progressLabel.text = "Saved"
            } catch {
                print("Failed to save CSV: \(error)")
                progressLabel.text = "Saving failed"
            }
        }
    }
    
    func computeAverages() -> (acc_x: Double, acc_y: Double, acc_z: Double, gyro_x: Double, gyro_y: Double, gyro_z: Double) {
        var sum_acc_x = 0.0, sum_acc_y = 0.0, sum_acc_z = 0.0
        var sum_gyro_x = 0.0, sum_gyro_y = 0.0, sum_gyro_z = 0.0

        for entry in data_list {
            sum_acc_x += entry.acc_x
            sum_acc_y += entry.acc_y
            sum_acc_z += entry.acc_z
            sum_gyro_x += entry.gyro_x
            sum_gyro_y += entry.gyro_y
            sum_gyro_z += entry.gyro_z
        }
        
        let count = Double(data_list.count)
        let mean_acc_x = sum_acc_x / count
        let mean_acc_y = sum_acc_y / count
        let mean_acc_z = sum_acc_z / count
        let mean_gyro_x = sum_gyro_x / count
        let mean_gyro_y = sum_gyro_y / count
        let mean_gyro_z = sum_gyro_z / count

        var var_acc_x = 0.0, var_acc_y = 0.0, var_acc_z = 0.0
        var var_gyro_x = 0.0, var_gyro_y = 0.0, var_gyro_z = 0.0

        for entry in data_list {
            var_acc_x += pow(entry.acc_x - mean_acc_x, 2)
            var_acc_y += pow(entry.acc_y - mean_acc_y, 2)
            var_acc_z += pow(entry.acc_z - mean_acc_z, 2)
            var_gyro_x += pow(entry.gyro_x - mean_gyro_x, 2)
            var_gyro_y += pow(entry.gyro_y - mean_gyro_y, 2)
            var_gyro_z += pow(entry.gyro_z - mean_gyro_z, 2)
        }
        
        let variance = (
            var_acc_x / count,
            var_acc_y / count,
            var_acc_z / count,
            var_gyro_x / count,
            var_gyro_y / count,
            var_gyro_z / count
        )
        print("Calculated mean: ")
        print(variance)
        print("Calculated variance: ")
        print(variance)
        

        return (mean_acc_x, mean_acc_y, mean_acc_z, mean_gyro_x, mean_gyro_y, mean_gyro_z)
    }

}

