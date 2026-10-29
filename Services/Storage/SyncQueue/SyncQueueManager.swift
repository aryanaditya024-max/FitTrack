import Foundation
import CoreData

public final class SyncQueueManager: SyncQueueManagerProtocol, @unchecked Sendable {
    
    private let coreDataStack: CoreDataStack
    
    public init(coreDataStack: CoreDataStack = .shared) {
        self.coreDataStack = coreDataStack
    }
    
    public func enqueue(
        entityType: String,
        entityId: UUID,
        operation: SyncOperation,
        payload: Data?
    ) async throws {
        try await coreDataStack.performBackgroundTask { context in
            // Check if an existing pending mutation exists for this entity to deduplicate or coalesce
            let request: NSFetchRequest<CDSyncQueueItem> = CDSyncQueueItem.fetchRequest()
            request.predicate = NSPredicate(format: "entityId == %@ AND entityType == %@", entityId as CVarArg, entityType)
            
            let existingItems = try context.fetch(request)
            
            // If it's a delete operation, remove previous pending creations/updates and store the delete
            if operation == .delete {
                for item in existingItems {
                    context.delete(item)
                }
            }
            
            let queueItem = CDSyncQueueItem(context: context)
            queueItem.id = UUID()
            queueItem.entityType = entityType
            queueItem.entityId = entityId
            queueItem.operation = operation.rawValue
            queueItem.payload = payload
            queueItem.retryCount = 0
            queueItem.createdAt = Date()
            queueItem.lastAttempt = nil
            queueItem.errorMessage = nil
        }
    }
    
    public func fetchPendingItems(limit: Int = 50) async throws -> [SyncQueueItem] {
        try await coreDataStack.performBackgroundTask { context in
            let request: NSFetchRequest<CDSyncQueueItem> = CDSyncQueueItem.fetchRequest()
            request.sortDescriptors = [NSSortDescriptor(key: "createdAt", ascending: true)]
            request.fetchLimit = limit
            
            let results = try context.fetch(request)
            return results.map { $0.toDomain() }
        }
    }
    
    public func markCompleted(itemId: UUID) async throws {
        try await coreDataStack.performBackgroundTask { context in
            let request: NSFetchRequest<CDSyncQueueItem> = CDSyncQueueItem.fetchRequest()
            request.predicate = NSPredicate(format: "id == %@", itemId as CVarArg)
            
            if let item = try context.fetch(request).first {
                context.delete(item)
            }
        }
    }
    
    public func markFailed(itemId: UUID, error: String) async throws {
        try await coreDataStack.performBackgroundTask { context in
            let request: NSFetchRequest<CDSyncQueueItem> = CDSyncQueueItem.fetchRequest()
            request.predicate = NSPredicate(format: "id == %@", itemId as CVarArg)
            
            if let item = try context.fetch(request).first {
                item.retryCount += 1
                item.lastAttempt = Date()
                item.errorMessage = error
            }
        }
    }
    
    public func countPending() async throws -> Int {
        try await coreDataStack.performBackgroundTask { context in
            let request: NSFetchRequest<CDSyncQueueItem> = CDSyncQueueItem.fetchRequest()
            return try context.count(for: request)
        }
    }
    
    public func clearQueue() async throws {
        try await coreDataStack.performBackgroundTask { context in
            let request: NSFetchRequest<NSFetchRequestResult> = CDSyncQueueItem.fetchRequest()
            let deleteRequest = NSBatchDeleteRequest(fetchRequest: request)
            try context.execute(deleteRequest)
        }
    }
}
