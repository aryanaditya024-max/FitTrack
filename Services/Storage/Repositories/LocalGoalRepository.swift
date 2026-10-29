import Foundation
import CoreData

public final class LocalGoalRepository: GoalRepositoryProtocol, @unchecked Sendable {
    
    private let coreDataStack: CoreDataStack
    private let syncQueueManager: SyncQueueManagerProtocol?
    
    public init(
        coreDataStack: CoreDataStack = .shared,
        syncQueueManager: SyncQueueManagerProtocol? = nil
    ) {
        self.coreDataStack = coreDataStack
        self.syncQueueManager = syncQueueManager
    }
    
    public func fetchGoals(includeDeleted: Bool = false) async throws -> [FitnessGoal] {
        try await coreDataStack.performBackgroundTask { context in
            let request: NSFetchRequest<CDGoal> = CDGoal.fetchRequest()
            if !includeDeleted {
                request.predicate = NSPredicate(format: "isDeleted == NO")
            }
            request.sortDescriptors = [NSSortDescriptor(key: "createdAt", ascending: false)]
            
            let results = try context.fetch(request)
            return results.map { $0.toDomain() }
        }
    }
    
    public func fetchActiveGoals() async throws -> [FitnessGoal] {
        try await coreDataStack.performBackgroundTask { context in
            let request: NSFetchRequest<CDGoal> = CDGoal.fetchRequest()
            request.predicate = NSPredicate(format: "isDeleted == NO AND isActive == YES")
            request.sortDescriptors = [NSSortDescriptor(key: "frequency", ascending: true)]
            
            let results = try context.fetch(request)
            return results.map { $0.toDomain() }
        }
    }
    
    public func fetchGoal(byId id: UUID) async throws -> FitnessGoal? {
        try await coreDataStack.performBackgroundTask { context in
            let request: NSFetchRequest<CDGoal> = CDGoal.fetchRequest()
            request.predicate = NSPredicate(format: "id == %@", id as CVarArg)
            request.fetchLimit = 1
            
            return try context.fetch(request).first?.toDomain()
        }
    }
    
    public func saveGoal(_ goal: FitnessGoal) async throws {
        var mutableGoal = goal
        mutableGoal.updatedAt = Date()
        
        try await coreDataStack.performBackgroundTask { context in
            let request: NSFetchRequest<CDGoal> = CDGoal.fetchRequest()
            request.predicate = NSPredicate(format: "id == %@", mutableGoal.id as CVarArg)
            request.fetchLimit = 1
            
            let cdGoal: CDGoal
            let isNew: Bool
            
            if let existing = try context.fetch(request).first {
                cdGoal = existing
                mutableGoal.version = existing.version + 1
                isNew = false
            } else {
                cdGoal = CDGoal(context: context)
                isNew = true
            }
            
            cdGoal.update(from: mutableGoal)
        }
        
        if let syncQueue = syncQueueManager {
            let encoder = JSONEncoder()
            encoder.dateEncodingStrategy = .iso8601
            let payload = try? encoder.encode(mutableGoal)
            let operation: SyncOperation = mutableGoal.isDeleted ? .delete : .update
            try await syncQueue.enqueue(
                entityType: "goal",
                entityId: mutableGoal.id,
                operation: operation,
                payload: payload
            )
        }
    }
    
    public func softDeleteGoal(id: UUID) async throws {
        var goalToQueue: FitnessGoal?
        
        try await coreDataStack.performBackgroundTask { context in
            let request: NSFetchRequest<CDGoal> = CDGoal.fetchRequest()
            request.predicate = NSPredicate(format: "id == %@", id as CVarArg)
            request.fetchLimit = 1
            
            if let existing = try context.fetch(request).first {
                existing.isDeleted = true
                existing.updatedAt = Date()
                existing.syncStatus = SyncStatus.pendingSync.rawValue
                existing.version += 1
                goalToQueue = existing.toDomain()
            }
        }
        
        if let goal = goalToQueue, let syncQueue = syncQueueManager {
            let encoder = JSONEncoder()
            encoder.dateEncodingStrategy = .iso8601
            let payload = try? encoder.encode(goal)
            try await syncQueue.enqueue(
                entityType: "goal",
                entityId: id,
                operation: .delete,
                payload: payload
            )
        }
    }
    
    public func hardDeleteGoal(id: UUID) async throws {
        try await coreDataStack.performBackgroundTask { context in
            let request: NSFetchRequest<CDGoal> = CDGoal.fetchRequest()
            request.predicate = NSPredicate(format: "id == %@", id as CVarArg)
            request.fetchLimit = 1
            
            if let existing = try context.fetch(request).first {
                context.delete(existing)
            }
        }
    }
    
    public func updateSyncStatus(id: UUID, status: SyncStatus) async throws {
        try await coreDataStack.performBackgroundTask { context in
            let request: NSFetchRequest<CDGoal> = CDGoal.fetchRequest()
            request.predicate = NSPredicate(format: "id == %@", id as CVarArg)
            request.fetchLimit = 1
            
            if let existing = try context.fetch(request).first {
                existing.syncStatus = status.rawValue
            }
        }
    }
}
