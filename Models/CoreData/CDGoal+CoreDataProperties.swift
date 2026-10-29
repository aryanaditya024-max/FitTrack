import Foundation
import CoreData

extension CDGoal {

    @nonobjc public class func fetchRequest() -> NSFetchRequest<CDGoal> {
        return NSFetchRequest<CDGoal>(entityName: "CDGoal")
    }

    @NSManaged public var createdAt: Date?
    @NSManaged public var endDate: Date?
    @NSManaged public var frequency: String?
    @NSManaged public var id: UUID?
    @NSManaged public var isActive: Bool
    @NSManaged public var isMarkedDeleted: Bool
    @NSManaged public var metricType: String?
    @NSManaged public var startDate: Date?
    @NSManaged public var syncStatus: Int16
    @NSManaged public var targetValue: Double
    @NSManaged public var updatedAt: Date?
    @NSManaged public var userId: String?
    @NSManaged public var version: Int64

}

extension CDGoal : Identifiable {

}
