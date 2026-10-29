import Foundation

/// Differentiates verified hardware sensor data (HealthKit / CoreMotion)
/// from manually entered user records to preserve fitness data integrity.
public enum DataSourceType: String, Codable, CaseIterable, Sendable {
    case sensorHealthKit = "sensor_healthkit"
    case manualEntry = "manual_entry"
    
    public var displayName: String {
        switch self {
        case .sensorHealthKit:
            return "HealthKit Sensor"
        case .manualEntry:
            return "Manual Entry"
        }
    }
    
    public var iconName: String {
        switch self {
        case .sensorHealthKit:
            return "waveform.path.ecg"
        case .manualEntry:
            return "square.and.pencil"
        }
    }
    
    public var isHardwareSensor: Bool {
        self == .sensorHealthKit
    }
}
