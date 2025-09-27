import Foundation

enum AnaStorage {
    private static let metricsKey = "com.ana.currentMetrics"
    private static let summaryKey = "com.ana.lastSummary"
    private static let configurationKey = "com.ana.configuration"
    private static let userProfileKey = "com.ana.profile"

    private static let encoder: JSONEncoder = {
        let encoder = JSONEncoder()
        encoder.dateEncodingStrategy = .iso8601
        return encoder
    }()

    private static let decoder: JSONDecoder = {
        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .iso8601
        return decoder
    }()

    static func save(metrics: WorkoutMetrics) {
        if let data = try? encoder.encode(metrics) {
            UserDefaults.standard.set(data, forKey: metricsKey)
        }
    }

    static func loadMetrics() -> WorkoutMetrics? {
        guard let data = UserDefaults.standard.data(forKey: metricsKey) else { return nil }
        return try? decoder.decode(WorkoutMetrics.self, from: data)
    }

    static func save(summary: WorkoutSummary) {
        if let data = try? encoder.encode(summary) {
            UserDefaults.standard.set(data, forKey: summaryKey)
        }
    }

    static func loadSummary() -> WorkoutSummary? {
        guard let data = UserDefaults.standard.data(forKey: summaryKey) else { return nil }
        return try? decoder.decode(WorkoutSummary.self, from: data)
    }

    static func save(configuration: WorkoutConfiguration) {
        if let data = try? encoder.encode(configuration) {
            UserDefaults.standard.set(data, forKey: configurationKey)
        }
    }

    static func loadConfiguration() -> WorkoutConfiguration? {
        guard let data = UserDefaults.standard.data(forKey: configurationKey) else { return nil }
        return try? decoder.decode(WorkoutConfiguration.self, from: data)
    }

    static func save(profile: UserProfile) {
        if let data = try? encoder.encode(profile) {
            UserDefaults.standard.set(data, forKey: userProfileKey)
        }
    }

    static func loadProfile() -> UserProfile? {
        guard let data = UserDefaults.standard.data(forKey: userProfileKey) else { return nil }
        return try? decoder.decode(UserProfile.self, from: data)
    }
}
