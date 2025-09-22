import Foundation
import HealthKit

struct WorkoutSettings {
    var speed: Double = 3.0 // mph
    var incline: Double = 0.0 // percentage
}

class WorkoutStats: ObservableObject {
    @Published var duration: TimeInterval = 0
    @Published var distance: Double = 0 // miles
    @Published var steps: Int = 0
    @Published var heartRate: Double = 0 // BPM
    @Published var averageHeartRate: Double = 0
    @Published var calories: Double = 0
    @Published var pace: Double = 0 // minutes per mile
    
    private var heartRateSum: Double = 0
    private var heartRateCount: Int = 0
    
    func updateHeartRate(_ newRate: Double) {
        heartRate = newRate
        if newRate > 0 {
            heartRateSum += newRate
            heartRateCount += 1
            averageHeartRate = heartRateSum / Double(heartRateCount)
        }
    }
    
    func updateDistance(speed: Double, timeInterval: TimeInterval) {
        // Convert speed from mph to miles per second, then multiply by time
        let speedInMilesPerSecond = speed / 3600.0
        distance += speedInMilesPerSecond * timeInterval
        
        // Calculate pace (minutes per mile)
        if speed > 0 {
            pace = 60.0 / speed
        }
    }
    
    func estimateCalories(weight: Double, speed: Double, incline: Double, timeInterval: TimeInterval) {
        // METs calculation for treadmill walking/running
        var mets: Double
        
        if speed < 4.0 {
            // Walking
            mets = 3.5 + (speed - 2.0) * 0.5 + (incline / 100.0) * 2.0
        } else {
            // Running
            mets = speed * 1.2 + (incline / 100.0) * 3.0
        }
        
        // Calories = METs * weight(kg) * time(hours)
        let weightInKg = weight * 0.453592 // Convert lbs to kg
        let timeInHours = timeInterval / 3600.0
        let caloriesBurned = mets * weightInKg * timeInHours
        
        calories += caloriesBurned
    }
    
    func reset() {
        duration = 0
        distance = 0
        steps = 0
        heartRate = 0
        averageHeartRate = 0
        calories = 0
        pace = 0
        heartRateSum = 0
        heartRateCount = 0
    }
}