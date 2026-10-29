import Foundation
import CoreMotion

public protocol MotionServiceProtocol: Sendable {
    func isStepCountingAvailable() -> Bool
    func isDistanceAvailable() -> Bool
    func isCadenceAvailable() -> Bool
    func queryPedometer(from startDate: Date, to endDate: Date) async throws -> (steps: Int, distanceMeters: Double)
    func startLiveUpdates(handler: @escaping @Sendable (Int, Double) -> Void)
    func stopLiveUpdates()
}
