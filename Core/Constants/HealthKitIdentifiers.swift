import Foundation
import HealthKit

public enum HealthKitIdentifiers {
    
    // Read Quantity Types
    public static let stepCount = HKQuantityType.quantityType(forIdentifier: .stepCount)!
    public static let activeEnergyBurned = HKQuantityType.quantityType(forIdentifier: .activeEnergyBurned)!
    public static let distanceWalkingRunning = HKQuantityType.quantityType(forIdentifier: .distanceWalkingRunning)!
    
    // Workout Type
    public static let workoutType = HKObjectType.workoutType()
    
    // Authorization Sets
    public static let readTypes: Set<HKObjectType> = [
        stepCount,
        activeEnergyBurned,
        distanceWalkingRunning,
        workoutType
    ]
    
    public static let shareTypes: Set<HKSampleType> = [
        workoutType
    ]
}
