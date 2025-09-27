import Foundation
import CoreMotion
import Combine

final class MotionAnalyzer: ObservableObject {
    @Published private(set) var stepCount: Int = 0
    @Published private(set) var cadence: Double = 0
    @Published private(set) var movementIntensity: Double = 0

    var onInactivity: (() -> Void)?
    var onActivityResumed: (() -> Void)?
    var onPedometerUpdate: ((Int, Double) -> Void)?

    private let pedometer = CMPedometer()
    private let motionManager = CMMotionManager()
    private let queue = OperationQueue()
    private var lastSignificantMotion: Date = Date()
    private var inactivityTimer: Timer?
    private var isInactive = false
    private var pedometerDistance: Double = 0
    private var monitoringStart: Date?

    var inactivityThreshold: TimeInterval = 15

    func startMonitoring(from startDate: Date) {
        monitoringStart = startDate
        resetMetrics()
        startSensors(from: startDate)
    }

    func resumeMonitoring() {
        guard let monitoringStart else { return }
        startSensors(from: monitoringStart)
    }

    func pause() {
        pedometer.stopUpdates()
        motionManager.stopDeviceMotionUpdates()
        invalidateTimer()
    }

    func stop() {
        pause()
        resetMetrics()
        monitoringStart = nil
    }

    private func startSensors(from startDate: Date) {
        pedometer.stopUpdates()
        startPedometer(from: startDate)
        startDeviceMotion()
        scheduleInactivityTimer()
    }

    private func resetMetrics() {
        stepCount = 0
        cadence = 0
        movementIntensity = 0
        pedometerDistance = 0
        lastSignificantMotion = Date()
        isInactive = false
    }

    private func startPedometer(from startDate: Date) {
        guard CMPedometer.isStepCountingAvailable() else { return }
        pedometer.startUpdates(from: startDate) { [weak self] data, _ in
            guard let self, let data else { return }
            DispatchQueue.main.async {
                self.stepCount = data.numberOfSteps.intValue
                if let cadence = data.currentCadence?.doubleValue {
                    self.cadence = cadence * 60.0
                }
                if let distance = data.distance?.doubleValue {
                    self.pedometerDistance = distance
                }
                self.onPedometerUpdate?(self.stepCount, self.pedometerDistance)
                if self.cadence > 10 {
                    self.registerMotionEvent()
                }
            }
        }
    }

    private func startDeviceMotion() {
        guard motionManager.isDeviceMotionAvailable else { return }
        motionManager.stopDeviceMotionUpdates()
        motionManager.deviceMotionUpdateInterval = 0.2
        motionManager.startDeviceMotionUpdates(to: queue) { [weak self] motion, _ in
            guard let self, let motion else { return }
            let acceleration = motion.userAcceleration
            let magnitude = sqrt(acceleration.x * acceleration.x + acceleration.y * acceleration.y + acceleration.z * acceleration.z)
            DispatchQueue.main.async {
                self.movementIntensity = magnitude
                if magnitude > 0.12 {
                    self.registerMotionEvent()
                }
            }
        }
    }

    private func scheduleInactivityTimer() {
        invalidateTimer()
        inactivityTimer = Timer.scheduledTimer(withTimeInterval: 3.0, repeats: true) { [weak self] _ in
            self?.evaluateInactivity()
        }
    }

    private func invalidateTimer() {
        inactivityTimer?.invalidate()
        inactivityTimer = nil
    }

    private func evaluateInactivity() {
        let elapsed = Date().timeIntervalSince(lastSignificantMotion)
        if elapsed > inactivityThreshold {
            if !isInactive {
                isInactive = true
                onInactivity?()
            }
        } else if isInactive {
            isInactive = false
            onActivityResumed?()
        }
    }

    private func registerMotionEvent() {
        lastSignificantMotion = Date()
    }
}
