import Foundation
import CoreData

public enum SyncOperation: String, Codable, Sendable {
    case create = "create"
    case update = "update"
    case delete = "delete"
}

public struct SyncQueueItem: Identifiable, Sendable {
    public let id: UUID
    public let entityType: String
    public let entityId: UUID
    public let operation: SyncOperation
    public let payload: Data?
    public let retryCount: Int16
    public let lastAttempt: Date?
    public let createdAt: Date
    public let errorMessage: String?
}

@objc(CDSyncQueueItem)
public class CDSyncQueueItem: NSManagedObject {

    public func toDomain() -> SyncQueueItem {
        let op = SyncOperation(rawValue: operation ?? "") ?? .create
        return SyncQueueItem(
            id: id ?? UUID(),
            entityType: entityType ?? "",
            entityId: entityId ?? UUID(),
            operation: op,
            payload: payload,
            retryCount: retryCount,
            lastAttempt: lastAttempt,
            createdAt: createdAt ?? Date(),
            errorMessage: errorMessage
        )
    }
}
