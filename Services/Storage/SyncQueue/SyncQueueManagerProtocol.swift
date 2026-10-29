import Foundation

public protocol SyncQueueManagerProtocol: Sendable {
    func enqueue(
        entityType: String,
        entityId: UUID,
        operation: SyncOperation,
        payload: Data?
    ) async throws
    
    func fetchPendingItems(limit: Int) async throws -> [SyncQueueItem]
    
    func markCompleted(itemId: UUID) async throws
    
    func markFailed(itemId: UUID, error: String) async throws
    
    func countPending() async throws -> Int
    
    func clearQueue() async throws
}
