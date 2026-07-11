import Foundation

nonisolated final class GameStatsStore {
    private let defaults: UserDefaults?
    private var memory: [String: Any] = [:]

    init(defaults: UserDefaults? = GameStatsStore.defaultDefaults) {
        self.defaults = defaults
    }

    func integer(forKey key: String) -> Int {
        defaults?.integer(forKey: key) ?? memory[key] as? Int ?? 0
    }

    func double(forKey key: String) -> Double {
        defaults?.double(forKey: key) ?? memory[key] as? Double ?? 0
    }

    func optionalInteger(forKey key: String) -> Int? {
        if let defaults {
            guard defaults.object(forKey: key) != nil else { return nil }
            return defaults.integer(forKey: key)
        }
        return memory[key] as? Int
    }

    func set(_ value: Int, forKey key: String) {
        if let defaults {
            defaults.set(value, forKey: key)
        } else {
            memory[key] = value
        }
    }

    func set(_ value: Double, forKey key: String) {
        if let defaults {
            defaults.set(value, forKey: key)
        } else {
            memory[key] = value
        }
    }

    func removeValue(forKey key: String) {
        if let defaults {
            defaults.removeObject(forKey: key)
        } else {
            memory.removeValue(forKey: key)
        }
    }

    private static var defaultDefaults: UserDefaults? {
        ProcessInfo.processInfo.environment["XCTestConfigurationFilePath"] == nil ? .standard : nil
    }
}
