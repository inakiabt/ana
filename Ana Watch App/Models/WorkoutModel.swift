import Foundation
import HealthKit

enum UnitSystem: String, CaseIterable {
    case imperial = "Imperial"
    case metric = "Metric"
    
    var speedUnit: String {
        switch self {
        case .imperial: return "mph"
        case .metric: return "km/h"
        }
    }
    
    var distanceUnit: String {
        switch self {
        case .imperial: return "mi"
        case .metric: return "km"
        }
    }
    
    var lengthUnit: String {
        switch self {
        case .imperial: return "inches"
        case .metric: return "cm"
        }
    }
}

enum Gender: String, CaseIterable {
    case male = "Male"
    case female = "Female"
    case other = "Other"
}

struct UserProfile {
    var height: Double = 170.0 // cm
    var gender: Gender = .other
    var stepLength: Double = 75.0 // cm - user's stride length
    var hasCustomStepLength: Bool = false // whether user has manually set or calibrated step length
    
    // Calculate estimated step length based on height using standard formula
    func estimatedStepLength() -> Double {
        let multiplier: Double
        switch gender {
        case .male: return height * 0.415
        case .female: return height * 0.413
        case .other: return height * 0.414 // average
        }
    }
    
    // Convert step length to user's preferred unit system
    func stepLengthInUserUnits(unitSystem: UnitSystem) -> Double {
        switch unitSystem {
        case .imperial: return stepLength * 0.393701 // cm to inches
        case .metric: return stepLength
        }
    }
}

struct WorkoutSettings {
    var speed: Double = 3.0 // mph or km/h based on unit system
    var incline: Double = 0.0 // percentage
    var unitSystem: UnitSystem = .imperial
    var walkingSpeedThreshold: Double = 4.0 // speed threshold between walking and running (mph)
    var userProfile: UserProfile = UserProfile()
}

class WorkoutStats: ObservableObject {
    @Published var duration: TimeInterval = 0
    @Published var distance: Double = 0 // miles or km based on unit system
    @Published var steps: Int = 0
    @Published var heartRate: Double = 0 // BPM
    @Published var averageHeartRate: Double = 0
    @Published var calories: Double = 0
    @Published var pace: Double = 0 // minutes per mile or per km
    
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
    
    func updateDistance(speed: Double, timeInterval: TimeInterval, unitSystem: UnitSystem) {
        // Convert speed to distance per second, then multiply by time
        let speedInDistancePerSecond = speed / 3600.0
        distance += speedInDistancePerSecond * timeInterval
        
        // Calculate pace (minutes per distance unit)
        if speed > 0 {
            pace = 60.0 / speed
        }
    }
    
    func estimateCalories(weight: Double, speed: Double, incline: Double, timeInterval: TimeInterval, unitSystem: UnitSystem) {
        // Convert speed to mph for METs calculation if using metric
        let speedInMph = unitSystem == .metric ? speed * 0.621371 : speed
        
        // METs calculation for treadmill walking/running
        var mets: Double
        
        if speedInMph < 4.0 {
            // Walking
            mets = 3.5 + (speedInMph - 2.0) * 0.5 + (incline / 100.0) * 2.0
        } else {
            // Running
            mets = speedInMph * 1.2 + (incline / 100.0) * 3.0
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