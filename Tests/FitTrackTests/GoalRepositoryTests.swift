import XCTest
import CoreData
@testable import FitTrack

final class GoalRepositoryTests: XCTestCase {
    
    var inMemoryStack: CoreDataStack!
    var syncQueue: SyncQueueManager!
    var repository: LocalGoalRepository!
    
    override func setUp() {
        super.setUp()
        inMemoryStack = CoreDataStack(inMemory: true)
        syncQueue = SyncQueueManager(coreDataStack: inMemoryStack)
        repository = LocalGoalRepository(coreDataStack: inMemoryStack, syncQueueManager: syncQueue)
    }
    
    override func tearDown() {
        repository = nil
        syncQueue = nil
        inMemoryStack = nil
        super.tearDown()
    }
    
    func test_saveAndFetchActiveGoals() async throws {
        let dailyStepsGoal = FitnessGoal(
            metricType: .steps,
            targetValue: 10000,
            frequency: .daily,
            isActive: true
        )
        
        let inactiveGoal = FitnessGoal(
            metricType: .activeEnergy,
            targetValue: 700,
            frequency: .daily,
            isActive: false
        )
        
        try await repository.saveGoal(dailyStepsGoal)
        try await repository.saveGoal(inactiveGoal)
        
        let activeGoals = try await repository.fetchActiveGoals()
        XCTAssertEqual(activeGoals.count, 1)
        XCTAssertEqual(activeGoals.first?.id, dailyStepsGoal.id)
        XCTAssertEqual(activeGoals.first?.targetValue, 10000)
        
        // Progress verification helper
        let progress = activeGoals.first?.progress(currentValue: 7500)
        XCTAssertEqual(progress, 0.75)
    }
    
    func test_softDeleteGoal_marksDeletedAndEnqueuesSync() async throws {
        let weeklyDistanceGoal = FitnessGoal(
            metricType: .distance,
            targetValue: 25000, // 25 km
            frequency: .weekly
        )
        try await repository.saveGoal(weeklyDistanceGoal)
        
        try await syncQueue.clearQueue()
        try await repository.softDeleteGoal(id: weeklyDistanceGoal.id)
        
        let active = try await repository.fetchActiveGoals()
        XCTAssertFalse(active.contains(where: { $0.id == weeklyDistanceGoal.id }))
        
        let pending = try await syncQueue.fetchPendingItems(limit: 5)
        XCTAssertEqual(pending.count, 1)
        XCTAssertEqual(pending.first?.entityType, "goal")
        XCTAssertEqual(pending.first?.operation, .delete)
    }
}
