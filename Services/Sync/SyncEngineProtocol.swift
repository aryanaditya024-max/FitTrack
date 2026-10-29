import Foundation

public protocol SyncEngineProtocol: Sendable {
    var isSyncing: Bool { get }
    var lastSyncDate: Date? { get }
    func synchronize() async throws -> (pushedCount: Int, pulledCount: Int)
}
