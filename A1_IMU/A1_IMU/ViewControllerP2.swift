//
//  ViewControllerP2.swift
//  CSE 562
//
//  Created by Alex on 4/28/25.
//

import UIKit
import CoreMotion
import DGCharts

class ViewControllerP2: UIViewController {
    var timer: Timer?
    
    var gyro_roll: Double = 0
    var gyro_pitch: Double = 0
    var comp_roll: Double = 0
    var comp_pitch: Double = 0
    var alpha: Double = 0.9
    
    var roll_data: [ChartDataEntry] = []
    var pitch_data: [ChartDataEntry] = []
    var time_elapsed: Double = 0
    var last_time: Date?
    
    @IBOutlet weak var pitch_chart: LineChartView!
    @IBOutlet weak var roll_chart: LineChartView!
    
    @IBOutlet weak var sensor_selector: UISegmentedControl!
    
    @IBAction func sensor_select_changed(_ sender: UISegmentedControl, forEvent event: UIEvent) {
        // We don't want to mix up different sensors
        roll_chart.data = nil
        roll_chart.notifyDataSetChanged()
        
        pitch_chart.data = nil
        pitch_chart.notifyDataSetChanged()
        
        roll_data.removeAll()
        pitch_data.removeAll()
    }
    
    required init?(coder: NSCoder) {
        super.init(coder: coder)
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        
        if !IMUManager.shared.isIMURunning() {
            IMUManager.shared.start()
        }
        last_time = Date()
        gyro_roll = -720
        gyro_pitch = -720
        timer = Timer.scheduledTimer(timeInterval: IMUManager.shared.updateInterval,
                             target: self,
                             selector: #selector(ViewControllerP2.runLoop),
                             userInfo: nil, repeats: true)
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        timer?.invalidate()
        timer = nil
        pitch_data.removeAll()
        roll_data.removeAll()
        time_elapsed = 0
        if !IMUManager.shared.isIMURunning() {
            IMUManager.shared.stop()
        }
    }
    
    
    
    override func viewDidLoad() {
        super.viewDidLoad()
        // Do any additional setup after loading the view.
        roll_chart.rightAxis.enabled = false
        roll_chart.xAxis.labelPosition = .bottom
        roll_chart.leftAxis.axisMinimum = -180
        roll_chart.leftAxis.axisMaximum = 180
        roll_chart.noDataText = ""

        pitch_chart.rightAxis.enabled = false
        pitch_chart.xAxis.labelPosition = .bottom
        pitch_chart.leftAxis.axisMinimum = -180
        pitch_chart.leftAxis.axisMaximum = 180
        pitch_chart.noDataText = ""
        
        if !IMUManager.shared.isIMURunning() {
            IMUManager.shared.start()
        }

    }
    

    @objc func runLoop() {
        updateIMU(accel: IMUManager.shared.getAccel()!.acceleration, gyro: IMUManager.shared.getGyro()!.rotationRate, deltaTime: Date().timeIntervalSince(last_time!))
        last_time = Date()
    }
    
    func updateIMU(accel: CMAcceleration, gyro: CMRotationRate, deltaTime: Double) {
        let accel_x = accel.x + IMUManager.shared.accel_bias.x
        let accel_y = accel.y + IMUManager.shared.accel_bias.y
        let accel_z = accel.z + IMUManager.shared.accel_bias.z
        let gyro_x = gyro.x + IMUManager.shared.gyro_bias.x
        let gyro_y = gyro.y + IMUManager.shared.gyro_bias.y
        
        let accel_roll = normalize(atan2(accel_y, accel_z) + .pi)
        let accel_pitch = atan2(-accel_x, sqrt(accel_y * accel_y + accel_z * accel_z))
        
        // Use accelerometer to estimate starting orientation
        if gyro_roll == -720 && gyro_pitch == -720 {
            gyro_roll = accel_roll
            gyro_pitch = accel_pitch
            comp_roll = accel_roll
            comp_pitch = accel_pitch
        }
        gyro_roll += gyro_x * deltaTime
        gyro_pitch -= gyro_y * deltaTime
        
        gyro_roll = normalize(gyro_roll)
        gyro_pitch = normalize(gyro_pitch)
        
        comp_roll = alpha * (comp_roll + gyro_x * deltaTime) + (1 - alpha) * accel_roll
        comp_pitch = alpha * (comp_pitch - gyro_y * deltaTime) + (1 - alpha) * accel_pitch
        comp_roll = normalize(comp_roll)
        comp_pitch = normalize(comp_pitch)
        
        time_elapsed += deltaTime
        
        var roll: Double, pitch: Double
        switch sensor_selector.selectedSegmentIndex {
        case 0:
            roll = accel_roll
            pitch = accel_pitch
        case 1:
            roll = gyro_roll
            pitch = gyro_pitch
        case 2:
            roll = comp_roll
            pitch = comp_pitch
        default:
            roll = 0
            pitch = 0
            NSLog("Invalid sensor selection")
        }

        updateChart(roll_deg: rad2deg(roll), pitch_deg: rad2deg(pitch))
    }
    
    func updateChart(roll_deg: Double, pitch_deg: Double) {
        roll_data.append(ChartDataEntry(x: time_elapsed, y: roll_deg))
        pitch_data.append(ChartDataEntry(x: time_elapsed, y: pitch_deg))
        // Only show the data from last 150/30 = 5 seconds
        if roll_data.count > 1800 {
            roll_data.removeFirst()
            pitch_data.removeFirst()
        }
        
        let roll_ds = LineChartDataSet(entries: roll_data, label: "Roll")
        let pitch_ds = LineChartDataSet(entries: pitch_data, label: "Pitch")
        
        roll_ds.setColor(.systemBlue)
        roll_ds.drawCircleHoleEnabled = false
        roll_ds.circleRadius = 3
        roll_ds.drawValuesEnabled = false
        roll_chart.data = LineChartData(dataSet: roll_ds)
        roll_chart.notifyDataSetChanged()
        
        pitch_ds.setColor(.systemBlue)
        pitch_ds.drawCircleHoleEnabled = false
        pitch_ds.circleRadius = 3
        pitch_ds.drawValuesEnabled = false
        pitch_chart.data = LineChartData(dataSet: pitch_ds)
        pitch_chart.notifyDataSetChanged()
    }
    
    func rad2deg(_ radians: Double) -> Double {
        return radians * 180 / .pi
    }

    func normalize(_ rad: Double) -> Double {
        var normalized = fmod(rad + .pi, 2 * .pi)
        if normalized < 0 {
            normalized += 2 * .pi
        }
        return normalized - .pi
    }
    
    func normalizeAngle(_ angle: Double) -> Double {
        var normalized = fmod(angle + 180, 360)
        if normalized < 0 {
            normalized += 360
        }
        return normalized - 180
    }
}
