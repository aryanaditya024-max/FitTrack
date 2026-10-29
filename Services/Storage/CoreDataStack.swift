import Foundation
import CoreData

/// Production-grade Core Data Stack supporting both persistent SQLite disk storage
/// and transient in-memory stores for unit testing and SwiftUI Previews.
public final class CoreDataStack: @unchecked Sendable {
    
    public static let shared = CoreDataStack()
    
    public let container: NSPersistentContainer
    
    public var viewContext: NSManagedObjectContext {
        container.viewContext
    }
    
    public init(inMemory: Bool = false) {
        // Attempt to load the model from bundle, fallback to programmatic model for tests
        let model: NSManagedObjectModel
        if let modelURL = Bundle.main.url(forResource: "FitTrack", withExtension: "momd"),
           let managedModel = NSManagedObjectModel(contentsOf: modelURL) {
            model = managedModel
        } else {
            model = CoreDataStack.createManagedObjectModel()
        }
        
        container = NSPersistentContainer(name: "FitTrack", managedObjectModel: model)
        
        if inMemory {
            let description = NSPersistentStoreDescription()
            description.url = URL(fileURLWithPath: "/dev/null")
            description.type = NSInMemoryStoreType
            container.persistentStoreDescriptions = [description]
        } else {
            if let description = container.persistentStoreDescriptions.first {
                description.setOption(true as NSNumber, forKey: NSPersistentHistoryTrackingKey)
                description.setOption(true as NSNumber, forKey: NSPersistentStoreRemoteChangeNotificationPostOptionKey)
            }
        }
        
        container.loadPersistentStores { [container] description, error in
            if let error = error as NSError? {
                fatalError("Unresolved Core Data error \(error), \(error.userInfo) for store \(description)")
            }
            
            container.viewContext.automaticallyMergesChangesFromParent = true
            container.viewContext.mergePolicy = NSMergeByPropertyObjectTrumpMergePolicy
        }
    }
    
    /// Creates a dedicated background context with trump merge policy
    public func newBackgroundContext() -> NSManagedObjectContext {
        let context = container.newBackgroundContext()
        context.mergePolicy = NSMergeByPropertyObjectTrumpMergePolicy
        context.automaticallyMergesChangesFromParent = true
        return context
    }
    
    /// Executes a closure on a private background context and automatically saves changes
    public func performBackgroundTask<T>(_ block: @escaping (NSManagedObjectContext) throws -> T) async throws -> T {
        let context = newBackgroundContext()
        return try await context.perform {
            let result = try block(context)
            if context.hasChanges {
                try context.save()
            }
            return result
        }
    }
    
    /// Helper to save any context if changes are present
    public func saveContext(_ context: NSManagedObjectContext) throws {
        if context.hasChanges {
            try context.save()
        }
    }
    
    // MARK: - Programmatic Model Fallback
    
    /// Constructs the Core Data model programmatically to ensure tests and previews
    /// execute without requiring a pre-compiled .momd file.
    public static func createManagedObjectModel() -> NSManagedObjectModel {
        let model = NSManagedObjectModel()
        
        // 1. CDWorkout Entity
        let workoutEntity = NSEntityDescription()
        workoutEntity.name = "CDWorkout"
        workoutEntity.managedObjectClassName = NSStringFromClass(CDWorkout.self)
        
        let wId = NSAttributeDescription()
        wId.name = "id"
        wId.attributeType = .UUIDAttributeType
        wId.isOptional = false
        
        let wUserId = NSAttributeDescription()
        wUserId.name = "userId"
        wUserId.attributeType = .stringAttributeType
        wUserId.isOptional = true
        
        let wTitle = NSAttributeDescription()
        wTitle.name = "title"
        wTitle.attributeType = .stringAttributeType
        wTitle.isOptional = false
        wTitle.defaultValue = "Workout"
        
        let wActivity = NSAttributeDescription()
        wActivity.name = "activityType"
        wActivity.attributeType = .stringAttributeType
        wActivity.isOptional = false
        wActivity.defaultValue = "other"
        
        let wStart = NSAttributeDescription()
        wStart.name = "startDate"
        wStart.attributeType = .dateAttributeType
        wStart.isOptional = false
        
        let wEnd = NSAttributeDescription()
        wEnd.name = "endDate"
        wEnd.attributeType = .dateAttributeType
        wEnd.isOptional = false
        
        let wDuration = NSAttributeDescription()
        wDuration.name = "duration"
        wDuration.attributeType = .doubleAttributeType
        wDuration.isOptional = false
        wDuration.defaultValue = 0.0
        
        let wDist = NSAttributeDescription()
        wDist.name = "distance"
        wDist.attributeType = .doubleAttributeType
        wDist.isOptional = false
        wDist.defaultValue = 0.0
        
        let wCal = NSAttributeDescription()
        wCal.name = "caloriesBurned"
        wCal.attributeType = .doubleAttributeType
        wCal.isOptional = false
        wCal.defaultValue = 0.0
        
        let wSrc = NSAttributeDescription()
        wSrc.name = "source"
        wSrc.attributeType = .stringAttributeType
        wSrc.isOptional = false
        wSrc.defaultValue = "manual_entry"
        
        let wCreated = NSAttributeDescription()
        wCreated.name = "createdAt"
        wCreated.attributeType = .dateAttributeType
        wCreated.isOptional = false
        
        let wUpdated = NSAttributeDescription()
        wUpdated.name = "updatedAt"
        wUpdated.attributeType = .dateAttributeType
        wUpdated.isOptional = false
        
        let wDel = NSAttributeDescription()
        wDel.name = "isMarkedDeleted"
        wDel.attributeType = .booleanAttributeType
        wDel.isOptional = false
        wDel.defaultValue = false
        
        let wSync = NSAttributeDescription()
        wSync.name = "syncStatus"
        wSync.attributeType = .integer16AttributeType
        wSync.isOptional = false
        wSync.defaultValue = 1
        
        let wVer = NSAttributeDescription()
        wVer.name = "version"
        wVer.attributeType = .integer64AttributeType
        wVer.isOptional = false
        wVer.defaultValue = 1
        
        workoutEntity.properties = [
            wId, wUserId, wTitle, wActivity, wStart, wEnd,
            wDuration, wDist, wCal, wSrc, wCreated, wUpdated,
            wDel, wSync, wVer
        ]
        
        // 2. CDGoal Entity
        let goalEntity = NSEntityDescription()
        goalEntity.name = "CDGoal"
        goalEntity.managedObjectClassName = NSStringFromClass(CDGoal.self)
        
        let gId = NSAttributeDescription()
        gId.name = "id"
        gId.attributeType = .UUIDAttributeType
        gId.isOptional = false
        
        let gUserId = NSAttributeDescription()
        gUserId.name = "userId"
        gUserId.attributeType = .stringAttributeType
        gUserId.isOptional = true
        
        let gMetric = NSAttributeDescription()
        gMetric.name = "metricType"
        gMetric.attributeType = .stringAttributeType
        gMetric.isOptional = false
        
        let gTarget = NSAttributeDescription()
        gTarget.name = "targetValue"
        gTarget.attributeType = .doubleAttributeType
        gTarget.isOptional = false
        gTarget.defaultValue = 0.0
        
        let gFreq = NSAttributeDescription()
        gFreq.name = "frequency"
        gFreq.attributeType = .stringAttributeType
        gFreq.isOptional = false
        gFreq.defaultValue = "daily"
        
        let gStart = NSAttributeDescription()
        gStart.name = "startDate"
        gStart.attributeType = .dateAttributeType
        gStart.isOptional = false
        
        let gEnd = NSAttributeDescription()
        gEnd.name = "endDate"
        gEnd.attributeType = .dateAttributeType
        gEnd.isOptional = true
        
        let gActive = NSAttributeDescription()
        gActive.name = "isActive"
        gActive.attributeType = .booleanAttributeType
        gActive.isOptional = false
        gActive.defaultValue = true
        
        let gCreated = NSAttributeDescription()
        gCreated.name = "createdAt"
        gCreated.attributeType = .dateAttributeType
        gCreated.isOptional = false
        
        let gUpdated = NSAttributeDescription()
        gUpdated.name = "updatedAt"
        gUpdated.attributeType = .dateAttributeType
        gUpdated.isOptional = false
        
        let gDel = NSAttributeDescription()
        gDel.name = "isMarkedDeleted"
        gDel.attributeType = .booleanAttributeType
        gDel.isOptional = false
        gDel.defaultValue = false
        
        let gSync = NSAttributeDescription()
        gSync.name = "syncStatus"
        gSync.attributeType = .integer16AttributeType
        gSync.isOptional = false
        gSync.defaultValue = 1
        
        let gVer = NSAttributeDescription()
        gVer.name = "version"
        gVer.attributeType = .integer64AttributeType
        gVer.isOptional = false
        gVer.defaultValue = 1
        
        goalEntity.properties = [
            gId, gUserId, gMetric, gTarget, gFreq, gStart,
            gEnd, gActive, gCreated, gUpdated, gDel, gSync, gVer
        ]
        
        // 3. CDDailyMetricCache Entity
        let cacheEntity = NSEntityDescription()
        cacheEntity.name = "CDDailyMetricCache"
        cacheEntity.managedObjectClassName = NSStringFromClass(CDDailyMetricCache.self)
        
        let cId = NSAttributeDescription()
        cId.name = "id"
        cId.attributeType = .UUIDAttributeType
        cId.isOptional = false
        
        let cDate = NSAttributeDescription()
        cDate.name = "date"
        cDate.attributeType = .dateAttributeType
        cDate.isOptional = false
        
        let cSteps = NSAttributeDescription()
        cSteps.name = "stepCount"
        cSteps.attributeType = .doubleAttributeType
        cSteps.isOptional = false
        cSteps.defaultValue = 0.0
        
        let cDist = NSAttributeDescription()
        cDist.name = "distanceMeters"
        cDist.attributeType = .doubleAttributeType
        cDist.isOptional = false
        cDist.defaultValue = 0.0
        
        let cEnergy = NSAttributeDescription()
        cEnergy.name = "activeEnergyKcal"
        cEnergy.attributeType = .doubleAttributeType
        cEnergy.isOptional = false
        cEnergy.defaultValue = 0.0
        
        let cSrc = NSAttributeDescription()
        cSrc.name = "source"
        cSrc.attributeType = .stringAttributeType
        cSrc.isOptional = false
        cSrc.defaultValue = "sensor_healthkit"
        
        let cFetched = NSAttributeDescription()
        cFetched.name = "lastFetchedAt"
        cFetched.attributeType = .dateAttributeType
        cFetched.isOptional = false
        
        cacheEntity.properties = [cId, cDate, cSteps, cDist, cEnergy, cSrc, cFetched]
        
        // 4. CDSyncQueueItem Entity
        let queueEntity = NSEntityDescription()
        queueEntity.name = "CDSyncQueueItem"
        queueEntity.managedObjectClassName = NSStringFromClass(CDSyncQueueItem.self)
        
        let qId = NSAttributeDescription()
        qId.name = "id"
        qId.attributeType = .UUIDAttributeType
        qId.isOptional = false
        
        let qEntType = NSAttributeDescription()
        qEntType.name = "entityType"
        qEntType.attributeType = .stringAttributeType
        qEntType.isOptional = false
        
        let qEntId = NSAttributeDescription()
        qEntId.name = "entityId"
        qEntId.attributeType = .UUIDAttributeType
        qEntId.isOptional = false
        
        let qOp = NSAttributeDescription()
        qOp.name = "operation"
        qOp.attributeType = .stringAttributeType
        qOp.isOptional = false
        
        let qPayload = NSAttributeDescription()
        qPayload.name = "payload"
        qPayload.attributeType = .binaryDataAttributeType
        qPayload.isOptional = true
        
        let qRetry = NSAttributeDescription()
        qRetry.name = "retryCount"
        qRetry.attributeType = .integer16AttributeType
        qRetry.isOptional = false
        qRetry.defaultValue = 0
        
        let qAttempt = NSAttributeDescription()
        qAttempt.name = "lastAttempt"
        qAttempt.attributeType = .dateAttributeType
        qAttempt.isOptional = true
        
        let qCreated = NSAttributeDescription()
        qCreated.name = "createdAt"
        qCreated.attributeType = .dateAttributeType
        qCreated.isOptional = false
        
        let qErr = NSAttributeDescription()
        qErr.name = "errorMessage"
        qErr.attributeType = .stringAttributeType
        qErr.isOptional = true
        
        queueEntity.properties = [
            qId, qEntType, qEntId, qOp, qPayload,
            qRetry, qAttempt, qCreated, qErr
        ]
        
        model.entities = [workoutEntity, goalEntity, cacheEntity, queueEntity]
        return model
    }
}
