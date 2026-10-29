import Foundation
import HealthKit

public enum HealthKitError: LocalizedError, Sendable {
    case notAvailableOnDevice
    case authorizationDenied
    case queryExecutionFailed(String)
    
    public var errorDescription: String? {
        switch self {
        case .notAvailableOnDevice:
            return "HealthKit is not available on this device (e.g., iPad or non-supported simulator)."
        case .authorizationDenied:
            return "HealthKit authorization was denied by the user in Settings."
        case .queryExecutionFailed(let message):
            return "Failed to execute HealthKit statistics query: \(message)"
        }
    }
}

public final class HealthKitService: HealthKitServiceProtocol, @unchecked Sendable {
    
    public static let shared = HealthKitService()
    
    private let healthStore: HKHealthStore?
    
    public init(healthStore: HKHealthStore? = HKHealthStore.isHealthDataAvailable() ? HKHealthStore() : nil) {
        self.healthStore = healthStore
    }
    
    public func isHealthDataAvailable() -> Bool {
        return HKHealthStore.isHealthDataAvailable() && healthStore != nil
    }
    
    public func requestAuthorization() async throws -> Bool {
        guard let store = healthStore, isHealthDataAvailable() else {
            throw HealthKitError.notAvailableOnDevice
        }
        
        return try await withCheckedThrowingContinuation { continuation in
            store.requestAuthorization(toShare: HealthKitIdentifiers.shareTypes, read: HealthKitIdentifiers.readTypes) { success, error in
                if let error = error {
                    continuation.resume(throwing: error)
                } else {
                    continuation.resume(returning: success)
                }
            }
        }
    }
    
    // MARK: - Single Day Statistical Queries
    
    public func fetchDailyStepCount(for date: Date) async throws -> Double {
        let predicate = createDayPredicate(for: date)
        return try await executeStatisticsQuery(
            for: HealthKitIdentifiers.stepCount,
            predicate: predicate,
            unit: .count()
        )
    }
    
    public func fetchDailyActiveEnergy(for date: Date) async throws -> Double {
        let predicate = createDayPredicate(for: date)
        return try await executeStatisticsQuery(
            for: HealthKitIdentifiers.activeEnergyBurned,
            predicate: predicate,
            unit: .kilocalorie()
        )
    }
    
    public func fetchDailyDistance(for date: Date) async throws -> Double {
        let predicate = createDayPredicate(for: date)
        return try await executeStatisticsQuery(
            for: HealthKitIdentifiers.distanceWalkingRunning,
            predicate: predicate,
            unit: .meter()
        )
    }
    
    public func fetchDailySummary(for date: Date) async throws -> DailyMetricSummary {
        async let steps = fetchDailyStepCount(for: date)
        async let energy = fetchDailyActiveEnergy(for: date)
        async let distance = fetchDailyDistance(for: date)
        
        let (stepCount, activeEnergy, distanceMeters) = try await (steps, energy, distance)
        
        return DailyMetricSummary(
            date: Calendar.current.startOfDay(for: date),
            stepCount: stepCount,
            activeEnergyKcal: activeEnergy,
            distanceMeters: distanceMeters,
            source: .sensorHealthKit
        )
    }
    
    // MARK: - Multi-Day Statistics Collection Query (Day Buckets)
    
    public func fetchDailySummaries(from startDate: Date, to endDate: Date) async throws -> [DailyMetricSummary] {
        guard let store = healthStore, isHealthDataAvailable() else {
            throw HealthKitError.notAvailableOnDevice
        }
        
        let calendar = Calendar.current
        let startOfDay = calendar.startOfDay(for: startDate)
        var interval = DateComponents()
        interval.day = 1
        
        let predicate = HKQuery.predicateForSamples(withStart: startOfDay, end: endDate, options: .strictStartDate)
        
        // Execute parallel queries for steps, energy, and distance
        async let stepDict = executeCollectionQuery(
            store: store,
            type: HealthKitIdentifiers.stepCount,
            unit: .count(),
            predicate: predicate,
            anchorDate: startOfDay,
            interval: interval
        )
        
        async let energyDict = executeCollectionQuery(
            store: store,
            type: HealthKitIdentifiers.activeEnergyBurned,
            unit: .kilocalorie(),
            predicate: predicate,
            anchorDate: startOfDay,
            interval: interval
        )
        
        async let distDict = executeCollectionQuery(
            store: store,
            type: HealthKitIdentifiers.distanceWalkingRunning,
            unit: .meter(),
            predicate: predicate,
            anchorDate: startOfDay,
            interval: interval
        )
        
        let (steps, energy, distance) = try await (stepDict, energyDict, distDict)
        
        // Collate by date bucket
        var summaries: [DailyMetricSummary] = []
        var currentDate = startOfDay
        let finalDate = calendar.startOfDay(for: endDate)
        
        while currentDate <= finalDate {
            let s = steps[currentDate] ?? 0.0
            let e = energy[currentDate] ?? 0.0
            let d = distance[currentDate] ?? 0.0
            
            summaries.append(
                DailyMetricSummary(
                    date: currentDate,
                    stepCount: s,
                    activeEnergyKcal: e,
                    distanceMeters: d,
                    source: .sensorHealthKit
                )
            )
            
            guard let next = calendar.date(byAdding: .day, value: 1, to: currentDate) else { break }
            currentDate = next
        }
        
        return summaries
    }
    
    // MARK: - Export Recorded Workout to HealthKit
    
    public func exportWorkoutToHealthKit(_ workout: Workout) async throws {
        guard let store = healthStore, isHealthDataAvailable() else {
            throw HealthKitError.notAvailableOnDevice
        }
        
        let hkActivityType = mapToHKActivityType(workout.activityType)
        let energyQuantity = HKQuantity(unit: .kilocalorie(), doubleValue: workout.caloriesBurned)
        let distanceQuantity = HKQuantity(unit: .meter(), doubleValue: workout.distance)
        
        let hkWorkout = HKWorkout(
            activityType: hkActivityType,
            start: workout.startDate,
            end: workout.endDate,
            duration: workout.duration,
            totalEnergyBurned: energyQuantity,
            totalDistance: distanceQuantity,
            metadata: [
                HKMetadataKeySyncIdentifier: workout.id.uuidString,
                HKMetadataKeySyncVersion: NSNumber(value: workout.version),
                "FitTrackDataSource": workout.source.rawValue
            ]
        )
        
        try await withCheckedThrowingContinuation { (continuation: CheckedContinuation<Void, Error>) in
            store.save(hkWorkout) { success, error in
                if let error = error {
                    continuation.resume(throwing: error)
                } else {
                    continuation.resume(returning: ())
                }
            }
        }
    }
    
    // MARK: - Private Helpers
    
    private func createDayPredicate(for date: Date) -> NSPredicate {
        let calendar = Calendar.current
        let startOfDay = calendar.startOfDay(for: date)
        let endOfDay = calendar.date(byAdding: .day, value: 1, to: startOfDay)
        return HKQuery.predicateForSamples(withStart: startOfDay, end: endOfDay, options: .strictStartDate)
    }
    
    private func executeStatisticsQuery(
        for quantityType: HKQuantityType,
        predicate: NSPredicate,
        unit: HKUnit
    ) async throws -> Double {
        guard let store = healthStore, isHealthDataAvailable() else {
            return 0.0
        }
        
        return try await withCheckedThrowingContinuation { continuation in
            let query = HKStatisticsQuery(
                quantityType: quantityType,
                quantitySamplePredicate: predicate,
                options: .cumulativeSum
            ) { _, statistics, error in
                if let error = error {
                    continuation.resume(throwing: HealthKitError.queryExecutionFailed(error.localizedDescription))
                    return
                }
                let sum = statistics?.sumQuantity()?.doubleValue(for: unit) ?? 0.0
                continuation.resume(returning: sum)
            }
            store.execute(query)
        }
    }
    
    private func executeCollectionQuery(
        store: HKHealthStore,
        type: HKQuantityType,
        unit: HKUnit,
        predicate: NSPredicate,
        anchorDate: Date,
        interval: DateComponents
    ) async throws -> [Date: Double] {
        return try await withCheckedThrowingContinuation { continuation in
            let query = HKStatisticsCollectionQuery(
                quantityType: type,
                quantitySamplePredicate: predicate,
                options: .cumulativeSum,
                anchorDate: anchorDate,
                intervalComponents: interval
            )
            
            query.initialResultsHandler = { _, collection, error in
                if let error = error {
                    continuation.resume(throwing: HealthKitError.queryExecutionFailed(error.localizedDescription))
                    return
                }
                
                var dict: [Date: Double] = [:]
                collection?.enumerateStatistics(from: anchorDate, to: Date()) { statistics, _ in
                    let value = statistics.sumQuantity()?.doubleValue(for: unit) ?? 0.0
                    let bucketDate = Calendar.current.startOfDay(for: statistics.startDate)
                    dict[bucketDate] = value
                }
                continuation.resume(returning: dict)
            }
            
            store.execute(query)
        }
    }
    
    private func mapToHKActivityType(_ activity: ActivityType) -> HKWorkoutActivityType {
        switch activity {
        case .running: return .running
        case .walking: return .walking
        case .cycling: return .cycling
        case .swimming: return .swimming
        case .hiit: return .highIntensityIntervalTraining
        case .strength: return .traditionalStrengthTraining
        case .yoga: return .yoga
        case .other: return .other
        }
    }
}
