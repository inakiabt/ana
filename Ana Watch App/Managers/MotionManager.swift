import Foundation
import CoreMotion
import Combine

class MotionManager: ObservableObject {
    private let pedometer = CMPedometer()
    private let motionManager = CMMotionManager()
    
    @Published var isAuthorized = false
    @Published var stepCount: Int = 0
    @Published var distance: Double = 0
    
    private var startDate: Date?
    
    init() {
        checkAuthorization()
    }
    
    private func checkAuthorization() {
        isAuthorized = CMPedometer.isStepCountingAvailable() && CMPedometer.isDistanceAvailable()
    }
    
    func startTracking() {
        guard CMPedometer.isStepCountingAvailable() else { return }
        
        startDate = Date()
        
        pedometer.startUpdates(from: startDate!) { [weak self] data, error in
            guard let data = data, error == nil else { return }
            
            DispatchQueue.main.async {
                self?.stepCount = data.numberOfSteps.intValue
                if let distance = data.distance {
                    self?.distance = distance.doubleValue * 0.000621371 // Convert meters to miles
                }
            }
        }
        
        // Start accelerometer updates for additional motion detection
        if motionManager.isAccelerometerAvailable {
            motionManager.accelerometerUpdateInterval = 0.1
            motionManager.startAccelerometerUpdates()
        }
    }
    
    func stopTracking() {
        pedometer.stopUpdates()
        motionManager.stopAccelerometerUpdates()
        
        stepCount = 0
        distance = 0
        startDate = nil
    }
    
    func requestPermission() {
        // CMPedometer automatically requests permission when startUpdates is called
        startTracking()
        stopTracking()
        checkAuthorization()
    }
    
    // Estimate steps based on speed and time for treadmill workouts
    func estimateSteps(speed: Double, timeInterval: TimeInterval) -> Int {
        // Average steps per mile for walking/running
        let stepsPerMile: Double
        if speed < 4.0 {
            stepsPerMile = 2200 // Walking
        } else {
            stepsPerMile = 1800 // Running
        }
        
        let milesWalked = (speed / 3600.0) * timeInterval
        return Int(milesWalked * stepsPerMile)
    }
}