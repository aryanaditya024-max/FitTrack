import Foundation
import CoreData

@objc(CDWorkout)
public class CDWorkout: NSManagedObject {
    
    /// Converts this Core Data managed object into a pure Swift domain Workout.
    public func toDomain() -> Workout {
        let activity = ActivityType(rawValue: activityType ?? "") ?? .other
        let src = DataSourceType(rawValue: source ?? "") ?? .manualEntry
        let status = SyncStatus(rawValue: syncStatus) ?? .pendingSync
        
        return Workout(
            id: id ?? UUID(),
            userId: userId,
            title: title ?? "Untitled Workout",
            activityType: activity,
            startDate: startDate ?? Date(),
            endDate: endDate ?? Date(),
            duration: duration,
            distance: distance,
            caloriesBurned: caloriesBurned,
            source: src,
            createdAt: createdAt ?? Date(),
            updatedAt: updatedAt ?? Date(),
            isDeleted: isDeleted,
            syncStatus: status,
            version: version
        )
    }
    
    /// Updates properties on this managed object using a domain Workout.
    public func update(from workout: Workout) {
        self.id = workout.id
        self.userId = workout.userId
        self.title = workout.title
        self.activityType = workout.activityType.rawValue
        self.startDate = workout.startDate
        self.endDate = workout.endDate
        self.duration = workout.duration
        self.distance = workout.distance
        self.caloriesBurned = workout.caloriesBurned
        self.source = workout.source.rawValue
        self.createdAt = workout.createdAt
        self.updatedAt = workout.updatedAt
        self.isDeleted = workout.isDeleted
        self.syncStatus = workout.syncStatus.rawValue
        self.version = workout.version
    }
}
