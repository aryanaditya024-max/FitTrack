import Foundation
import CoreData

public protocol DailyMetricCacheRepositoryProtocol: Sendable {
    func saveDailyMetrics(_ summary: DailyMetricSummary) async throws
    func fetchMetrics(for date: Date) async throws -> DailyMetricSummary?
    func fetchMetrics(from startDate: Date, to endDate: Date) async throws -> [DailyMetricSummary]
}

public final class DailyMetricCacheRepository: DailyMetricCacheRepositoryProtocol, @unchecked Sendable {
    
    private let coreDataStack: CoreDataStack
    
    public init(coreDataStack: CoreDataStack = .shared) {
        self.coreDataStack = coreDataStack
    }
    
    public func saveDailyMetrics(_ summary: DailyMetricSummary) async throws {
        let calendar = Calendar.current
        let startOfDay = calendar.startOfDay(for: summary.date)
        
        try await coreDataStack.performBackgroundTask { context in
            let request: NSFetchRequest<CDDailyMetricCache> = CDDailyMetricCache.fetchRequest()
            request.predicate = NSPredicate(format: "date == %@", startOfDay as NSDate)
            request.fetchLimit = 1
            
            let entity: CDDailyMetricCache
            if let existing = try context.fetch(request).first {
                entity = existing
            } else {
                entity = CDDailyMetricCache(context: context)
                entity.id = UUID()
            }
            
            var normalizedSummary = summary
            // Force source to sensor to prevent accidental pollution
            normalizedSummary = DailyMetricSummary(
                date: startOfDay,
                stepCount: summary.stepCount,
                activeEnergyKcal: summary.activeEnergyKcal,
                distanceMeters: summary.distanceMeters,
                workoutCount: summary.workoutCount,
                totalWorkoutDuration: summary.totalWorkoutDuration,
                source: .sensorHealthKit
            )
            entity.update(from: normalizedSummary)
        }
    }
    
    public func fetchMetrics(for date: Date) async throws -> DailyMetricSummary? {
        let calendar = Calendar.current
        let startOfDay = calendar.startOfDay(for: date)
        
        return try await coreDataStack.performBackgroundTask { context in
            let request: NSFetchRequest<CDDailyMetricCache> = CDDailyMetricCache.fetchRequest()
            request.predicate = NSPredicate(format: "date == %@", startOfDay as NSDate)
            request.fetchLimit = 1
            
            return try context.fetch(request).first?.toDomain()
        }
    }
    
    public func fetchMetrics(from startDate: Date, to endDate: Date) async throws -> [DailyMetricSummary] {
        let calendar = Calendar.current
        let start = calendar.startOfDay(for: startDate)
        let end = calendar.date(bySettingHour: 23, minute: 59, second: 59, of: endDate) ?? endDate
        
        return try await coreDataStack.performBackgroundTask { context in
            let request: NSFetchRequest<CDDailyMetricCache> = CDDailyMetricCache.fetchRequest()
            request.predicate = NSPredicate(
                format: "date >= %@ AND date <= %@",
                start as NSDate,
                end as NSDate
            )
            request.sortDescriptors = [NSSortDescriptor(key: "date", ascending: true)]
            
            let results = try context.fetch(request)
            return results.map { $0.toDomain() }
        }
    }
}
