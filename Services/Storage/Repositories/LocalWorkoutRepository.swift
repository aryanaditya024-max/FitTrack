import Foundation
import CoreData

public final class LocalWorkoutRepository: WorkoutRepositoryProtocol, @unchecked Sendable {
    
    private let coreDataStack: CoreDataStack
    private let syncQueueManager: SyncQueueManagerProtocol?
    
    public init(
        coreDataStack: CoreDataStack = .shared,
        syncQueueManager: SyncQueueManagerProtocol? = nil
    ) {
        self.coreDataStack = coreDataStack
        self.syncQueueManager = syncQueueManager
    }
    
    public func fetchWorkouts(includeDeleted: Bool = false) async throws -> [Workout] {
        try await coreDataStack.performBackgroundTask { context in
            let request: NSFetchRequest<CDWorkout> = CDWorkout.fetchRequest()
            if !includeDeleted {
                request.predicate = NSPredicate(format: "isDeleted == NO")
            }
            request.sortDescriptors = [NSSortDescriptor(key: "startDate", ascending: false)]
            
            let results = try context.fetch(request)
            return results.map { $0.toDomain() }
        }
    }
    
    public func fetchWorkout(byId id: UUID) async throws -> Workout? {
        try await coreDataStack.performBackgroundTask { context in
            let request: NSFetchRequest<CDWorkout> = CDWorkout.fetchRequest()
            request.predicate = NSPredicate(format: "id == %@", id as CVarArg)
            request.fetchLimit = 1
            
            return try context.fetch(request).first?.toDomain()
        }
    }
    
    public func fetchWorkouts(from startDate: Date, to endDate: Date) async throws -> [Workout] {
        try await coreDataStack.performBackgroundTask { context in
            let request: NSFetchRequest<CDWorkout> = CDWorkout.fetchRequest()
            request.predicate = NSPredicate(
                format: "isDeleted == NO AND startDate >= %@ AND startDate <= %@",
                startDate as NSDate,
                endDate as NSDate
            )
            request.sortDescriptors = [NSSortDescriptor(key: "startDate", ascending: true)]
            
            let results = try context.fetch(request)
            return results.map { $0.toDomain() }
        }
    }
    
    public func saveWorkout(_ workout: Workout) async throws {
        var mutableWorkout = workout
        mutableWorkout.updatedAt = Date()
        
        try await coreDataStack.performBackgroundTask { context in
            let request: NSFetchRequest<CDWorkout> = CDWorkout.fetchRequest()
            request.predicate = NSPredicate(format: "id == %@", mutableWorkout.id as CVarArg)
            request.fetchLimit = 1
            
            let cdWorkout: CDWorkout
            let isNew: Bool
            
            if let existing = try context.fetch(request).first {
                cdWorkout = existing
                mutableWorkout.version = existing.version + 1
                isNew = false
            } else {
                cdWorkout = CDWorkout(context: context)
                isNew = true
            }
            
            cdWorkout.update(from: mutableWorkout)
        }
        
        // Enqueue mutation for cloud synchronization
        if let syncQueue = syncQueueManager {
            let encoder = JSONEncoder()
            encoder.dateEncodingStrategy = .iso8601
            let payload = try? encoder.encode(mutableWorkout)
            let operation: SyncOperation = mutableWorkout.isDeleted ? .delete : .update
            try await syncQueue.enqueue(
                entityType: "workout",
                entityId: mutableWorkout.id,
                operation: operation,
                payload: payload
            )
        }
    }
    
    public func softDeleteWorkout(id: UUID) async throws {
        var workoutToQueue: Workout?
        
        try await coreDataStack.performBackgroundTask { context in
            let request: NSFetchRequest<CDWorkout> = CDWorkout.fetchRequest()
            request.predicate = NSPredicate(format: "id == %@", id as CVarArg)
            request.fetchLimit = 1
            
            if let existing = try context.fetch(request).first {
                existing.isDeleted = true
                existing.updatedAt = Date()
                existing.syncStatus = SyncStatus.pendingSync.rawValue
                existing.version += 1
                workoutToQueue = existing.toDomain()
            }
        }
        
        if let workout = workoutToQueue, let syncQueue = syncQueueManager {
            let encoder = JSONEncoder()
            encoder.dateEncodingStrategy = .iso8601
            let payload = try? encoder.encode(workout)
            try await syncQueue.enqueue(
                entityType: "workout",
                entityId: id,
                operation: .delete,
                payload: payload
            )
        }
    }
    
    public func hardDeleteWorkout(id: UUID) async throws {
        try await coreDataStack.performBackgroundTask { context in
            let request: NSFetchRequest<CDWorkout> = CDWorkout.fetchRequest()
            request.predicate = NSPredicate(format: "id == %@", id as CVarArg)
            request.fetchLimit = 1
            
            if let existing = try context.fetch(request).first {
                context.delete(existing)
            }
        }
    }
    
    public func updateSyncStatus(id: UUID, status: SyncStatus) async throws {
        try await coreDataStack.performBackgroundTask { context in
            let request: NSFetchRequest<CDWorkout> = CDWorkout.fetchRequest()
            request.predicate = NSPredicate(format: "id == %@", id as CVarArg)
            request.fetchLimit = 1
            
            if let existing = try context.fetch(request).first {
                existing.syncStatus = status.rawValue
            }
        }
    }
}
