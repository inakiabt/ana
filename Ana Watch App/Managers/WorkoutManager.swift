import Foundation
import HealthKit
import Combine

class WorkoutManager: NSObject, ObservableObject {
    let healthStore = HKHealthStore()
    var session: HKWorkoutSession?
    var builder: HKLiveWorkoutBuilder?
    
    @Published var isWorkoutActive = false
    @Published var isPaused = false
    @Published var hasHealthPermissions = false
    @Published var settings = WorkoutSettings()
    @Published var stats = WorkoutStats()
    
    private var startDate: Date?
    private var lastUpdateTime: Date?
    private var timer: Timer?
    private var userWeight: Double = 150.0 // Default weight in lbs
    
    override init() {
        super.init()
        checkHealthPermissions()
    }
    
    func requestHealthPermissions() {
        let typesToShare: Set = [
            HKQuantityType.workoutType(),
            HKQuantityType(.activeEnergyBurned),
            HKQuantityType(.distanceWalkingRunning),
            HKQuantityType(.stepCount)
        ]
        
        let typesToRead: Set = [
            HKQuantityType(.heartRate),
            HKQuantityType(.bodyMass),
            HKQuantityType(.stepCount),
            HKQuantityType(.activeEnergyBurned),
            HKQuantityType(.distanceWalkingRunning)
        ]
        
        healthStore.requestAuthorization(toShare: typesToShare, read: typesToRead) { [weak self] success, error in
            DispatchQueue.main.async {
                self?.hasHealthPermissions = success
                if success {
                    self?.fetchUserWeight()
                }
            }
        }
    }
    
    private func checkHealthPermissions() {
        let heartRateType = HKQuantityType(.heartRate)
        hasHealthPermissions = healthStore.authorizationStatus(for: heartRateType) == .sharingAuthorized
    }
    
    private func fetchUserWeight() {
        let weightType = HKQuantityType(.bodyMass)
        let query = HKSampleQuery(sampleType: weightType, predicate: nil, limit: 1, sortDescriptors: [NSSortDescriptor(key: HKSampleSortIdentifierEndDate, ascending: false)]) { [weak self] _, samples, _ in
            if let sample = samples?.first as? HKQuantitySample {
                let weightInKg = sample.quantity.doubleValue(for: .gramUnit(with: .kilo))
                DispatchQueue.main.async {
                    self?.userWeight = weightInKg * 2.20462 // Convert to lbs
                }
            }
        }
        healthStore.execute(query)
    }
    
    func startWorkout() {
        let configuration = HKWorkoutConfiguration()
        configuration.activityType = .walking
        configuration.locationType = .indoor
        
        do {
            session = try HKWorkoutSession(healthStore: healthStore, configuration: configuration)
            builder = session?.associatedWorkoutBuilder()
            
            session?.delegate = self
            builder?.delegate = self
            
            builder?.dataSource = HKLiveWorkoutDataSource(healthStore: healthStore, workoutConfiguration: configuration)
            
            startDate = Date()
            lastUpdateTime = startDate
            
            session?.startActivity(with: startDate)
            builder?.beginCollection(withStart: startDate!) { [weak self] success, error in
                DispatchQueue.main.async {
                    if success {
                        self?.isWorkoutActive = true
                        self?.startTimer()
                    }
                }
            }
        } catch {
            print("Failed to start workout: \(error)")
        }
    }
    
    func pauseWorkout() {
        session?.pause()
        isPaused = true
        timer?.invalidate()
    }
    
    func resumeWorkout() {
        session?.resume()
        isPaused = false
        lastUpdateTime = Date()
        startTimer()
    }
    
    func endWorkout() {
        session?.end()
        timer?.invalidate()
        isWorkoutActive = false
        isPaused = false
        
        builder?.endCollection(withEnd: Date()) { [weak self] success, error in
            if success {
                self?.finishWorkout()
            }
        }
    }
    
    private func finishWorkout() {
        guard let builder = builder else { return }
        
        builder.finishWorkout { [weak self] workout, error in
            DispatchQueue.main.async {
                if let workout = workout {
                    self?.saveWorkoutToHealth(workout)
                }
                self?.resetWorkout()
            }
        }
    }
    
    private func saveWorkoutToHealth(_ workout: HKWorkout) {
        healthStore.save(workout) { success, error in
            if success {
                print("Workout saved to Health app")
            } else {
                print("Failed to save workout: \(error?.localizedDescription ?? "Unknown error")")
            }
        }
    }
    
    private func resetWorkout() {
        stats.reset()
        session = nil
        builder = nil
        startDate = nil
        lastUpdateTime = nil
    }
    
    private func startTimer() {
        timer = Timer.scheduledTimer(withTimeInterval: 1.0, repeats: true) { [weak self] _ in
            self?.updateWorkoutStats()
        }
    }
    
    private func updateWorkoutStats() {
        guard let startDate = startDate, !isPaused else { return }
        
        let now = Date()
        let currentDuration = now.timeIntervalSince(startDate)
        let timeInterval = now.timeIntervalSince(lastUpdateTime ?? startDate)
        
        DispatchQueue.main.async { [weak self] in
            guard let self = self else { return }
            
            self.stats.duration = currentDuration
            self.stats.updateDistance(speed: self.settings.speed, timeInterval: timeInterval)
            self.stats.estimateCalories(
                weight: self.userWeight,
                speed: self.settings.speed,
                incline: self.settings.incline,
                timeInterval: timeInterval
            )
            
            self.lastUpdateTime = now
        }
    }
}

// MARK: - HKWorkoutSessionDelegate
extension WorkoutManager: HKWorkoutSessionDelegate {
    func workoutSession(_ workoutSession: HKWorkoutSession, didChangeTo toState: HKWorkoutSessionState, from fromState: HKWorkoutSessionState, date: Date) {
        // Handle workout session state changes
    }
    
    func workoutSession(_ workoutSession: HKWorkoutSession, didFailWithError error: Error) {
        print("Workout session failed: \(error)")
    }
}

// MARK: - HKLiveWorkoutBuilderDelegate
extension WorkoutManager: HKLiveWorkoutBuilderDelegate {
    func workoutBuilder(_ workoutBuilder: HKLiveWorkoutBuilder, didCollectDataOf collectedTypes: Set<HKSampleType>) {
        for type in collectedTypes {
            guard let quantityType = type as? HKQuantityType else { continue }
            
            if quantityType == HKQuantityType(.heartRate) {
                if let statistics = workoutBuilder.statistics(for: quantityType),
                   let mostRecentSample = statistics.mostRecentQuantity() {
                    let heartRate = mostRecentSample.doubleValue(for: .count().unitDivided(by: .minute()))
                    DispatchQueue.main.async {
                        self.stats.updateHeartRate(heartRate)
                    }
                }
            } else if quantityType == HKQuantityType(.stepCount) {
                if let statistics = workoutBuilder.statistics(for: quantityType),
                   let sum = statistics.sumQuantity() {
                    let steps = Int(sum.doubleValue(for: .count()))
                    DispatchQueue.main.async {
                        self.stats.steps = steps
                    }
                }
            }
        }
    }
    
    func workoutBuilderDidCollectEvent(_ workoutBuilder: HKLiveWorkoutBuilder) {
        // Handle workout events
    }
}