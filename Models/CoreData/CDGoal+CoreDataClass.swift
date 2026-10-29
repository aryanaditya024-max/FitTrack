import Foundation
import CoreData

@objc(CDGoal)
public class CDGoal: NSManagedObject {

    /// Converts this Core Data managed object into a pure Swift domain FitnessGoal.
    public func toDomain() -> FitnessGoal {
        let metric = GoalMetricType(rawValue: metricType ?? "") ?? .steps
        let freq = GoalFrequency(rawValue: frequency ?? "") ?? .daily
        let status = SyncStatus(rawValue: syncStatus) ?? .pendingSync

        return FitnessGoal(
            id: id ?? UUID(),
            userId: userId,
            metricType: metric,
            targetValue: targetValue,
            frequency: freq,
            startDate: startDate ?? Date(),
            endDate: endDate,
            isActive: isActive,
            createdAt: createdAt ?? Date(),
            updatedAt: updatedAt ?? Date(),
            isDeleted: isDeleted,
            syncStatus: status,
            version: version
        )
    }

    /// Updates properties on this managed object using a domain FitnessGoal.
    public func update(from goal: FitnessGoal) {
        self.id = goal.id
        self.userId = goal.userId
        self.metricType = goal.metricType.rawValue
        self.targetValue = goal.targetValue
        self.frequency = goal.frequency.rawValue
        self.startDate = goal.startDate
        self.endDate = goal.endDate
        self.isActive = goal.isActive
        self.createdAt = goal.createdAt
        self.updatedAt = goal.updatedAt
        self.isDeleted = goal.isDeleted
        self.syncStatus = goal.syncStatus.rawValue
        self.version = goal.version
    }
}
