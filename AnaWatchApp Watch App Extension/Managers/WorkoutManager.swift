import Foundation
import HealthKit
import ClockKit
import Combine

final class WorkoutManager: NSObject, ObservableObject {
    enum AuthorizationState {
        case pending
        case authorized
        case denied(Error?)
    }

    struct IdentifiableError: Identifiable {
        let id = UUID()
        let title: String
        let message: String
    }

    @Published private(set) var authorizationState: AuthorizationState = .pending
    @Published private(set) var sessionState: HKWorkoutSessionState = .notStarted
    @Published var metrics: WorkoutMetrics
    @Published var configuration: WorkoutConfiguration
    @Published var summary: WorkoutSummary?
    @Published var showResumePrompt = false
    @Published var activeError: IdentifiableError?
    @Published var isSavingWorkout = false
    @Published var profile: UserProfile {
        didSet {
            AnaStorage.save(profile: profile)
        }
    }

    private let healthStore = HKHealthStore()
    private var session: HKWorkoutSession?
    private var builder: HKLiveWorkoutBuilder?
    private var liveDataSource: HKLiveWorkoutDataSource?
    private var timer: Timer?
    private var startDate: Date?
    private var pauseDate: Date?
    private var accumulatedPauseDuration: TimeInterval = 0
    private var pedometerDistance: Double = 0
    private var pedometerSteps: Int = 0
    private var peakHeartRate: Double?

    private let motionAnalyzer = MotionAnalyzer()

    override init() {
        configuration = AnaStorage.loadConfiguration() ?? .default
        metrics = AnaStorage.loadMetrics() ?? WorkoutMetrics()
        summary = AnaStorage.loadSummary()
        profile = AnaStorage.loadProfile() ?? .default
        super.init()
        configureMotionCallbacks()
    }

    func requestAuthorization() {
        guard HKHealthStore.isHealthDataAvailable() else {
            authorizationState = .denied(nil)
            return
        }

        let shareTypes: Set<HKSampleType> = [
            HKObjectType.workoutType(),
            HKQuantityType.quantityType(forIdentifier: .activeEnergyBurned)!,
            HKQuantityType.quantityType(forIdentifier: .distanceWalkingRunning)!,
            HKQuantityType.quantityType(forIdentifier: .stepCount)!,
            HKQuantityType.quantityType(forIdentifier: .heartRate)!
        ]

        var readTypes = shareTypes as Set<HKObjectType>
        if let height = HKQuantityType.quantityType(forIdentifier: .height) {
            readTypes.insert(height)
        }
        if let weight = HKQuantityType.quantityType(forIdentifier: .bodyMass) {
            readTypes.insert(weight)
        }
        if let rest = HKQuantityType.quantityType(forIdentifier: .restingHeartRate) {
            readTypes.insert(rest)
        }

        healthStore.requestAuthorization(toShare: shareTypes, read: readTypes) { [weak self] success, error in
            DispatchQueue.main.async {
                guard let self else { return }
                if success {
                    self.authorizationState = .authorized
                    self.fetchUserProfile()
                } else {
                    self.authorizationState = .denied(error)
                }
            }
        }
    }

    func persistForBackground() {
        AnaStorage.save(metrics: metrics)
        AnaStorage.save(configuration: configuration)
        AnaStorage.save(profile: profile)
        if let summary {
            AnaStorage.save(summary: summary)
        }
    }

    func refreshFromStore() {
        if let savedConfig = AnaStorage.loadConfiguration() {
            configuration = savedConfig
        }
        if let savedProfile = AnaStorage.loadProfile() {
            profile = savedProfile
        }
        if let savedMetrics = AnaStorage.loadMetrics(), sessionState == .running {
            metrics = savedMetrics
        }
        if summary == nil {
            summary = AnaStorage.loadSummary()
        }
    }

    func startWorkout() {
        guard authorizationState == .authorized else {
            presentError(title: "Enable Health Access", message: "Ana needs Health permissions to record workouts.")
            return
        }

        endCurrentSessionIfNeeded()

        configuration.clamp()
        metrics = WorkoutMetrics()
        metrics.speed = configuration.speedMeasurement
        metrics.incline = configuration.incline
        summary = nil
        pedometerDistance = 0
        pedometerSteps = 0
        accumulatedPauseDuration = 0
        peakHeartRate = nil
        startDate = Date()
        pauseDate = nil

        let workoutConfiguration = HKWorkoutConfiguration()
        workoutConfiguration.activityType = .walking
        workoutConfiguration.locationType = .indoor

        do {
            let session = try HKWorkoutSession(healthStore: healthStore, configuration: workoutConfiguration)
            let builder = session.associatedWorkoutBuilder()
            let dataSource = HKLiveWorkoutDataSource(healthStore: healthStore, workoutConfiguration: workoutConfiguration)
            builder.dataSource = dataSource
            builder.delegate = self
            session.delegate = self

            self.session = session
            self.builder = builder
            self.liveDataSource = dataSource

            let start = startDate ?? Date()
            session.startActivity(with: start)
            builder.beginCollection(withStart: start) { [weak self] _, error in
                if let error {
                    self?.presentError(title: "Workout", message: error.localizedDescription)
                }
            }

            motionAnalyzer.startMonitoring(from: start)
            startTimer()
            sessionState = .running
            AnaStorage.save(configuration: configuration)
        } catch {
            presentError(title: "Workout", message: error.localizedDescription)
        }
    }

    func pauseWorkout() {
        guard sessionState == .running else { return }
        pauseDate = Date()
        session?.pause()
        sessionState = .paused
        timer?.invalidate()
        motionAnalyzer.pause()
        persistForBackground()
    }

    func resumeWorkout() {
        guard sessionState == .paused else { return }
        if let pauseDate {
            accumulatedPauseDuration += Date().timeIntervalSince(pauseDate)
        }
        pauseDate = nil
        session?.resume()
        sessionState = .running
        startTimer()
        motionAnalyzer.resumeMonitoring()
        showResumePrompt = false
    }

    func endWorkout() {
        guard sessionState == .running || sessionState == .paused else { return }
        timer?.invalidate()
        motionAnalyzer.stop()
        session?.end()
        sessionState = .ended
        isSavingWorkout = true
        let endDate = Date()

        builder?.endCollection(withEnd: endDate) { [weak self] _, error in
            guard let self else { return }
            if let error {
                self.presentError(title: "Finish", message: error.localizedDescription)
            }
            self.addManualSamples(endDate: endDate) {
                self.builder?.finishWorkout { workout, finishError in
                    DispatchQueue.main.async {
                        self.isSavingWorkout = false
                        if let finishError {
                            self.presentError(title: "Save", message: finishError.localizedDescription)
                        } else if let workout {
                            self.complete(with: workout)
                        }
                        self.resetSession()
                    }
                }
            }
        }
    }

    func acknowledgePrompt() {
        showResumePrompt = false
    }

    // MARK: - Private helpers

    private func configureMotionCallbacks() {
        motionAnalyzer.onPedometerUpdate = { [weak self] steps, distance in
            guard let self else { return }
            DispatchQueue.main.async {
                self.pedometerSteps = steps
                self.pedometerDistance = distance
                self.updateMetricsFromInputs()
            }
        }

        motionAnalyzer.onInactivity = { [weak self] in
            guard let self else { return }
            if self.sessionState == .running {
                self.pauseWorkout()
                self.showResumePrompt = true
            }
        }

        motionAnalyzer.onActivityResumed = { [weak self] in
            self?.showResumePrompt = false
        }
    }

    private func startTimer() {
        timer?.invalidate()
        timer = Timer.scheduledTimer(withTimeInterval: 1.0, repeats: true) { [weak self] _ in
            self?.updateMetricsFromInputs()
        }
        if let timer {
            RunLoop.main.add(timer, forMode: .common)
        }
    }

    private func updateMetricsFromInputs() {
        guard let startDate else { return }
        let elapsed = Date().timeIntervalSince(startDate) - accumulatedPauseDuration
        metrics.elapsedTime = max(elapsed, 0)
        metrics.speed = configuration.speedMeasurement
        metrics.incline = configuration.incline

        let manualDistance = configuration.speedInMetersPerSecond * elapsed
        let totalDistance = max(manualDistance, pedometerDistance)
        let distanceMeasurement = Measurement(value: totalDistance, unit: UnitLength.meters)
        metrics.distance = distanceMeasurement

        if totalDistance > 0 {
            let convertedDistance = distanceMeasurement.converted(to: configuration.distanceUnit.unit).value
            if convertedDistance > 0 {
                let paceValue = (metrics.elapsedTime / 60.0) / convertedDistance
                metrics.pace = Measurement(value: paceValue, unit: configuration.distanceUnit.paceUnit)
            } else {
                metrics.pace = nil
            }
        } else {
            metrics.pace = nil
        }

        let manualSteps = estimatedSteps(fromDistance: totalDistance)
        metrics.steps = max(pedometerSteps, manualSteps)

        if motionAnalyzer.cadence > 0 {
            metrics.cadence = motionAnalyzer.cadence
        } else if let cadence = estimatedCadence(forSpeed: configuration.speedInMetersPerSecond) {
            metrics.cadence = cadence
        } else {
            metrics.cadence = nil
        }
        metrics.movementIntensity = motionAnalyzer.movementIntensity
        metrics.activeEnergy = estimateEnergyBurned(elapsed: elapsed, incline: configuration.incline)

        AnaStorage.save(metrics: metrics)
    }

    private func estimatedSteps(fromDistance meters: Double) -> Int {
        let stepLength = profile.resolvedStepLength
        guard stepLength > 0 else { return 0 }
        return Int((meters / stepLength).rounded())
    }

    private func estimatedCadence(forSpeed speed: Double) -> Double? {
        let stepLength = profile.resolvedStepLength
        guard stepLength > 0, speed > 0 else { return nil }
        let stepsPerSecond = speed / stepLength
        return stepsPerSecond * 60.0
    }

    private func estimateEnergyBurned(elapsed: TimeInterval, incline: Double) -> Double {
        guard elapsed > 0 else { return 0 }
        let weightKg = profile.weightInKilograms ?? 72.0
        let speedMetersPerMinute = configuration.speedInMetersPerSecond * 60.0
        let grade = max(incline, 0) / 100.0
        let met = (0.1 * speedMetersPerMinute) + (1.8 * speedMetersPerMinute * grade) + 3.5
        let caloriesPerMinute = (met * weightKg) / 200.0
        return caloriesPerMinute * (elapsed / 60.0)
    }

    private func addManualSamples(endDate: Date, completion: @escaping () -> Void) {
        guard let builder, let startDate else {
            completion()
            return
        }

        var samples: [HKSample] = []

        if metrics.distanceInMeters > 0,
           let distanceType = HKQuantityType.quantityType(forIdentifier: .distanceWalkingRunning) {
            let quantity = HKQuantity(unit: HKUnit.meter(), doubleValue: metrics.distanceInMeters)
            let sample = HKQuantitySample(type: distanceType, quantity: quantity, start: startDate, end: endDate)
            samples.append(sample)
        }

        if metrics.activeEnergy > 0,
           let energyType = HKQuantityType.quantityType(forIdentifier: .activeEnergyBurned) {
            let quantity = HKQuantity(unit: HKUnit.kilocalorie(), doubleValue: metrics.activeEnergy)
            let sample = HKQuantitySample(type: energyType, quantity: quantity, start: startDate, end: endDate)
            samples.append(sample)
        }

        if metrics.steps > 0,
           let stepsType = HKQuantityType.quantityType(forIdentifier: .stepCount) {
            let quantity = HKQuantity(unit: HKUnit.count(), doubleValue: Double(metrics.steps))
            let sample = HKQuantitySample(type: stepsType, quantity: quantity, start: startDate, end: endDate)
            samples.append(sample)
        }

        guard !samples.isEmpty else {
            completion()
            return
        }

        builder.add(samples) { [weak self] _, error in
            if let error {
                self?.presentError(title: "Health Save", message: error.localizedDescription)
            }
            completion()
        }
    }

    private func complete(with workout: HKWorkout) {
        let summary = WorkoutSummary(
            start: workout.startDate,
            end: workout.endDate,
            duration: workout.duration,
            distance: metrics.distance,
            steps: metrics.steps,
            averageHeartRate: metrics.averageHeartRate,
            activeEnergy: metrics.activeEnergy,
            configuration: configuration,
            peakHeartRate: peakHeartRate
        )
        self.summary = summary
        AnaStorage.save(summary: summary)
        reloadComplications()
    }

    private func resetSession() {
        session = nil
        builder = nil
        liveDataSource = nil
        timer?.invalidate()
        timer = nil
        startDate = nil
        pauseDate = nil
        accumulatedPauseDuration = 0
        pedometerDistance = 0
        pedometerSteps = 0
        motionAnalyzer.stop()
        sessionState = .notStarted
    }

    private func endCurrentSessionIfNeeded() {
        if session != nil {
            endWorkout()
        }
    }

    private func fetchUserProfile() {
        let group = DispatchGroup()
        var height: Double?
        var weight: Double?
        var resting: Double?

        if let heightType = HKQuantityType.quantityType(forIdentifier: .height) {
            group.enter()
            fetchMostRecentQuantitySample(for: heightType, unit: .meter()) { value in
                height = value
                group.leave()
            }
        }

        if let weightType = HKQuantityType.quantityType(forIdentifier: .bodyMass) {
            group.enter()
            fetchMostRecentQuantitySample(for: weightType, unit: .gram()) { value in
                if let value {
                    weight = value / 1000.0
                }
                group.leave()
            }
        }

        if let restType = HKQuantityType.quantityType(forIdentifier: .restingHeartRate) {
            group.enter()
            let bpmUnit = HKUnit.count().unitDivided(by: HKUnit.minute())
            fetchMostRecentQuantitySample(for: restType, unit: bpmUnit) { value in
                resting = value
                group.leave()
            }
        }

        group.notify(queue: .main) { [weak self] in
            guard let self else { return }
            var updatedProfile = self.profile
            if let height { updatedProfile.heightInMeters = height }
            if let weight { updatedProfile.weightInKilograms = weight }
            if let resting { updatedProfile.restingHeartRate = resting }
            self.profile = updatedProfile
        }
    }

    private func fetchMostRecentQuantitySample(for type: HKQuantityType, unit: HKUnit, completion: @escaping (Double?) -> Void) {
        let sort = NSSortDescriptor(key: HKSampleSortIdentifierEndDate, ascending: false)
        let query = HKSampleQuery(sampleType: type, predicate: nil, limit: 1, sortDescriptors: [sort]) { _, samples, _ in
            let quantitySample = samples?.first as? HKQuantitySample
            let value = quantitySample?.quantity.doubleValue(for: unit)
            completion(value)
        }
        healthStore.execute(query)
    }

    private func reloadComplications() {
        let server = CLKComplicationServer.sharedInstance()
        server.activeComplications?.forEach { server.reloadTimeline(for: $0) }
    }

    private func presentError(title: String, message: String) {
        activeError = IdentifiableError(title: title, message: message)
    }
}

// MARK: - HKLiveWorkoutBuilderDelegate

extension WorkoutManager: HKLiveWorkoutBuilderDelegate {
    func workoutBuilder(_ workoutBuilder: HKLiveWorkoutBuilder, didCollectDataOf collectedTypes: Set<HKSampleType>) {
        DispatchQueue.main.async { [weak self] in
            guard let self else { return }
            for sampleType in collectedTypes {
                guard let quantityType = sampleType as? HKQuantityType,
                      let statistics = workoutBuilder.statistics(for: quantityType) else { continue }
                self.updateMetrics(for: quantityType, statistics: statistics)
            }
        }
    }

    func workoutBuilderDidCollectEvent(_ workoutBuilder: HKLiveWorkoutBuilder) {}

    private func updateMetrics(for quantityType: HKQuantityType, statistics: HKStatistics) {
        switch quantityType.identifier {
        case HKQuantityTypeIdentifier.heartRate.rawValue:
            let unit = HKUnit.count().unitDivided(by: HKUnit.minute())
            if let mostRecent = statistics.mostRecentQuantity()?.doubleValue(for: unit) {
                metrics.heartRate = mostRecent
                peakHeartRate = max(peakHeartRate ?? mostRecent, mostRecent)
            }
            if let average = statistics.averageQuantity()?.doubleValue(for: unit) {
                metrics.averageHeartRate = average
            }
        case HKQuantityTypeIdentifier.activeEnergyBurned.rawValue:
            if let sum = statistics.sumQuantity()?.doubleValue(for: .kilocalorie()) {
                metrics.activeEnergy = max(metrics.activeEnergy, sum)
            }
        case HKQuantityTypeIdentifier.distanceWalkingRunning.rawValue:
            if let sum = statistics.sumQuantity()?.doubleValue(for: .meter()) {
                pedometerDistance = max(pedometerDistance, sum)
                metrics.distance = Measurement(value: max(metrics.distanceInMeters, sum), unit: .meters)
            }
        case HKQuantityTypeIdentifier.stepCount.rawValue:
            if let sum = statistics.sumQuantity()?.doubleValue(for: HKUnit.count()) {
                pedometerSteps = max(pedometerSteps, Int(sum))
            }
        default:
            break
        }
        AnaStorage.save(metrics: metrics)
    }
}

// MARK: - HKWorkoutSessionDelegate

extension WorkoutManager: HKWorkoutSessionDelegate {
    func workoutSession(_ workoutSession: HKWorkoutSession, didChangeTo toState: HKWorkoutSessionState, from fromState: HKWorkoutSessionState, date: Date) {
        DispatchQueue.main.async { [weak self] in
            guard let self else { return }
            self.sessionState = toState
            switch toState {
            case .ended:
                self.timer?.invalidate()
                self.motionAnalyzer.stop()
            default:
                break
            }
        }
    }

    func workoutSession(_ workoutSession: HKWorkoutSession, didFailWithError error: Error) {
        presentError(title: "Workout", message: error.localizedDescription)
    }
}
