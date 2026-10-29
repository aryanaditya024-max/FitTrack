import Foundation
import CoreData

@objc(CDDailyMetricCache)
public class CDDailyMetricCache: NSManagedObject {

    public func toDomain() -> DailyMetricSummary {
        let src = DataSourceType(rawValue: source ?? "") ?? .sensorHealthKit
        return DailyMetricSummary(
            date: date ?? Date(),
            stepCount: stepCount,
            activeEnergyKcal: activeEnergyKcal,
            distanceMeters: distanceMeters,
            source: src
        )
    }

    public func update(from summary: DailyMetricSummary) {
        self.date = summary.date
        self.stepCount = summary.stepCount
        self.activeEnergyKcal = summary.activeEnergyKcal
        self.distanceMeters = summary.distanceMeters
        self.source = summary.source.rawValue
        self.lastFetchedAt = Date()
    }
}
