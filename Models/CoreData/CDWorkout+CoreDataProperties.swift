import Foundation
import CoreData

extension CDWorkout {

    @nonobjc public class func fetchRequest() -> NSFetchRequest<CDWorkout> {
        return NSFetchRequest<CDWorkout>(entityName: "CDWorkout")
    }

    @NSManaged public var activityType: String?
    @NSManaged public var caloriesBurned: Double
    @NSManaged public var createdAt: Date?
    @NSManaged public var distance: Double
    @NSManaged public var duration: Double
    @NSManaged public var endDate: Date?
    @NSManaged public var id: UUID?
    @NSManaged public var isDeleted: Bool
    @NSManaged public var source: String?
    @NSManaged public var startDate: Date?
    @NSManaged public var syncStatus: Int16
    @NSManaged public var title: String?
    @NSManaged public var updatedAt: Date?
    @NSManaged public var userId: String?
    @NSManaged public var version: Int64

}

extension CDWorkout : Identifiable {

}
