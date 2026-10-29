import Foundation
import CoreData

extension CDDailyMetricCache {

    @nonobjc public class func fetchRequest() -> NSFetchRequest<CDDailyMetricCache> {
        return NSFetchRequest<CDDailyMetricCache>(entityName: "CDDailyMetricCache")
    }

    @NSManaged public var activeEnergyKcal: Double
    @NSManaged public var date: Date?
    @NSManaged public var distanceMeters: Double
    @NSManaged public var id: UUID?
    @NSManaged public var lastFetchedAt: Date?
    @NSManaged public var source: String?
    @NSManaged public var stepCount: Double

}

extension CDDailyMetricCache : Identifiable {

}
