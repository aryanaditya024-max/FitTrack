import XCTest
import CoreData
@testable import FitTrack

final class WorkoutRepositoryTests: XCTestCase {
    
    var inMemoryStack: CoreDataStack!
    var syncQueue: SyncQueueManager!
    var repository: LocalWorkoutRepository!
    
    override func setUp() {
        super.setUp()
        inMemoryStack = CoreDataStack(inMemory: true)
        syncQueue = SyncQueueManager(coreDataStack: inMemoryStack)
        repository = LocalWorkoutRepository(coreDataStack: inMemoryStack, syncQueueManager: syncQueue)
    }
    
    override func tearDown() {
        repository = nil
        syncQueue = nil
        inMemoryStack = nil
        super.tearDown()
    }
    
    func test_saveWorkout_createsRecordAndEnqueuesSyncMutation() async throws {
        let workout = Workout(
            title: "Evening Interval Run",
            activityType: .running,
            startDate: Date(),
            duration: 2400,
            distance: 6500,
            caloriesBurned: 480,
            source: .manualEntry
        )
        
        try await repository.saveWorkout(workout)
        
        // 1. Verify retrieval from local repository
        let fetched = try await repository.fetchWorkout(byId: workout.id)
        XCTAssertNotNil(fetched)
        XCTAssertEqual(fetched?.title, "Evening Interval Run")
        XCTAssertEqual(fetched?.activityType, .running)
        XCTAssertEqual(fetched?.source, .manualEntry)
        XCTAssertEqual(fetched?.isDeleted, false)
        XCTAssertEqual(fetched?.version, 1)
        
        // 2. Verify Sync Queue item was enqueued
        let pending = try await syncQueue.fetchPendingItems(limit: 10)
        XCTAssertEqual(pending.count, 1)
        XCTAssertEqual(pending.first?.entityId, workout.id)
        XCTAssertEqual(pending.first?.entityType, "workout")
        XCTAssertEqual(pending.first?.operation, .update)
    }
    
    func test_updateWorkout_incrementsVersionAndUpdatesTimestamp() async throws {
        let workout = Workout(
            title: "Morning Walk",
            activityType: .walking,
            startDate: Date(),
            duration: 1200,
            distance: 2000,
            source: .manualEntry
        )
        try await repository.saveWorkout(workout)
        
        // Mutate and save update
        var updatedWorkout = workout
        updatedWorkout.title = "Brisk Morning Walk"
        updatedWorkout.distance = 2500
        
        try await repository.saveWorkout(updatedWorkout)
        
        let fetched = try await repository.fetchWorkout(byId: workout.id)
        XCTAssertEqual(fetched?.title, "Brisk Morning Walk")
        XCTAssertEqual(fetched?.distance, 2500)
        XCTAssertEqual(fetched?.version, 2)
    }
    
    func test_softDeleteWorkout_marksTombstoneAndEnqueuesDelete() async throws {
        let workout = Workout(
            title: "Leg Day Gym",
            activityType: .strength,
            startDate: Date(),
            duration: 3600,
            caloriesBurned: 300,
            source: .manualEntry
        )
        try await repository.saveWorkout(workout)
        
        // Clear queue to isolate delete test
        try await syncQueue.clearQueue()
        
        // Soft delete
        try await repository.softDeleteWorkout(id: workout.id)
        
        // Fetch active should omit it
        let activeWorkouts = try await repository.fetchWorkouts(includeDeleted: false)
        XCTAssertFalse(activeWorkouts.contains(where: { $0.id == workout.id }))
        
        // Fetch including deleted should contain it
        let allWorkouts = try await repository.fetchWorkouts(includeDeleted: true)
        let deletedRecord = allWorkouts.first(where: { $0.id == workout.id })
        XCTAssertNotNil(deletedRecord)
        XCTAssertTrue(deletedRecord?.isDeleted == true)
        XCTAssertEqual(deletedRecord?.syncStatus, .pendingSync)
        
        // Verify delete operation enqueued
        let pending = try await syncQueue.fetchPendingItems(limit: 10)
        XCTAssertEqual(pending.count, 1)
        XCTAssertEqual(pending.first?.operation, .delete)
    }
    
    func test_sensorData_preservesDataSourceSeparation() async throws {
        let sensorWorkout = Workout(
            title: "Outdoor Bike Ride",
            activityType: .cycling,
            startDate: Date(),
            duration: 1800,
            distance: 10000,
            source: .sensorHealthKit
        )
        try await repository.saveWorkout(sensorWorkout)
        
        let fetched = try await repository.fetchWorkout(byId: sensorWorkout.id)
        XCTAssertEqual(fetched?.source, .sensorHealthKit)
        XCTAssertTrue(fetched?.source.isHardwareSensor == true)
    }
}
