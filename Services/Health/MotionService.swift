import Foundation
import CoreMotion

public final class MotionService: MotionServiceProtocol, @unchecked Sendable {
    
    public static let shared = MotionService()
    
    private let pedometer: CMPedometer
    private var isUpdating: Bool = false
    
    public init(pedometer: CMPedometer = CMPedometer()) {
        self.pedometer = pedometer
    }
    
    public func isStepCountingAvailable() -> Bool {
        return CMPedometer.isStepCountingAvailable()
    }
    
    public func isDistanceAvailable() -> Bool {
        return CMPedometer.isDistanceAvailable()
    }
    
    public func isCadenceAvailable() -> Bool {
        return CMPedometer.isCadenceAvailable()
    }
    
    public func queryPedometer(from startDate: Date, to endDate: Date) async throws -> (steps: Int, distanceMeters: Double) {
        guard CMPedometer.isStepCountingAvailable() else {
            return (0, 0.0)
        }
        
        return try await withCheckedThrowingContinuation { continuation in
            pedometer.queryPedometerData(from: startDate, to: endDate) { data, error in
                if let error = error {
                    continuation.resume(throwing: error)
                } else if let data = data {
                    let steps = data.numberOfSteps.intValue
                    let distance = data.distance?.doubleValue ?? 0.0
                    continuation.resume(returning: (steps, distance))
                } else {
                    continuation.resume(returning: (0, 0.0))
                }
            }
        }
    }
    
    public func startLiveUpdates(handler: @escaping @Sendable (Int, Double) -> Void) {
        guard CMPedometer.isStepCountingAvailable(), !isUpdating else { return }
        
        isUpdating = true
        let startOfDay = Calendar.current.startOfDay(for: Date())
        
        pedometer.startUpdates(from: startOfDay) { data, error in
            guard let data = data, error == nil else { return }
            let steps = data.numberOfSteps.intValue
            let distance = data.distance?.doubleValue ?? 0.0
            handler(steps, distance)
        }
    }
    
    public func stopLiveUpdates() {
        if isUpdating {
            pedometer.stopUpdates()
            isUpdating = false
        }
    }
}
