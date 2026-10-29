import XCTest
@testable import FitTrack

final class MockNetworkMonitor: NetworkMonitorProtocol, @unchecked Sendable {
    var isConnected: Bool = true
    var isConstrained: Bool = false
    
    func startMonitoring(onStatusChange: @escaping @Sendable (Bool) -> Void) {}
    func stopMonitoring() {}
}

final class MockSupabaseDataService: SupabaseDataServiceProtocol, @unchecked Sendable {
    var upsertedWorkouts: [RemoteWorkout] = []
    var upsertedGoals: [RemoteGoal] = []
    var workoutsToReturn: [RemoteWorkout] = []
    var goalsToReturn: [RemoteGoal] = []
    var shouldFail: Bool = false
    
    func upsertWorkout(_ workout: RemoteWorkout) async throws {
        if shouldFail { throw NSError(domain: "test", code: 500, userInfo: [NSLocalizedDescriptionKey: "Server error"]) }
        upsertedWorkouts.append(workout)
    }
    
    func upsertGoal(_ goal: RemoteGoal) async throws {
        if shouldFail { throw NSError(domain: "test", code: 500, userInfo: [NSLocalizedDescriptionKey: "Server error"]) }
        upsertedGoals.append(goal)
    }
    
    func fetchWorkoutsUpdatedSince(_ date: Date) async throws -> [RemoteWorkout] {
        return workoutsToReturn
    }
    
    func fetchGoalsUpdatedSince(_ date: Date) async throws -> [RemoteGoal] {
        return goalsToReturn
    }
    
    func uploadDailyMetricSummary(_ metric: RemoteDailyMetric) async throws {}
}

final class SyncEngineTests: XCTestCase {
    
    var inMemoryStack: CoreDataStack!
    var queueManager: SyncQueueManager!
    var workoutRepo: LocalWorkoutRepository!
    var goalRepo: LocalGoalRepository!
    var mockNetwork: MockNetworkMonitor!
    var mockAuth: MockAuthService!
    var mockDataService: MockSupabaseDataService!
    var syncEngine: SyncEngine!
    
    override func setUp() {
        super.setUp()
        inMemoryStack = CoreDataStack(inMemory: true)
        queueManager = SyncQueueManager(coreDataStack: inMemoryStack)
        workoutRepo = LocalWorkoutRepository(coreDataStack: inMemoryStack, syncQueueManager: queueManager)
        goalRepo = LocalGoalRepository(coreDataStack: inMemoryStack, syncQueueManager: queueManager)
        
        mockNetwork = MockNetworkMonitor()
        mockAuth = MockAuthService()
        mockAuth.isAuth = true
        mockDataService = MockSupabaseDataService()
        
        syncEngine = SyncEngine(
            networkMonitor: mockNetwork,
            syncQueueManager: queueManager,
            workoutRepository: workoutRepo,
            goalRepository: goalRepo,
            authService: mockAuth,
            dataService: mockDataService
        )
    }
    
    override func tearDown() {
        syncEngine = nil
        mockDataService = nil
        mockAuth = nil
        mockNetwork = nil
        goalRepo = nil
        workoutRepo = nil
        queueManager = nil
        inMemoryStack = nil
        super.tearDown()
    }
    
    func test_synchronize_offlineMutationsArePushedWhenOnline() async throws {
        // 1. User records a workout locally while offline
        let localWorkout = Workout(
            title: "Trail Run",
            activityType: .running,
            startDate: Date(),
            duration: 1800,
            distance: 4500,
            source: .manualEntry
        )
        try await workoutRepo.saveWorkout(localWorkout)
        
        // Assert queued
        let initialPending = try await queueManager.countPending()
        XCTAssertEqual(initialPending, 1)
        
        // 2. Synchronize
        let result = try await syncEngine.synchronize()
        
        // Assert pushed to cloud
        XCTAssertEqual(result.pushedCount, 1)
        XCTAssertEqual(mockDataService.upsertedWorkouts.count, 1)
        XCTAssertEqual(mockDataService.upsertedWorkouts.first?.id, localWorkout.id)
        
        // Assert queue drained
        let remainingPending = try await queueManager.countPending()
        XCTAssertEqual(remainingPending, 0)
    }
    
    func test_synchronize_networkFailure_incrementsRetryCountAndPreservesQueue() async throws {
        let workout = Workout(
            title: "Morning Swim",
            activityType: .swimming,
            startDate: Date(),
            duration: 1200,
            source: .manualEntry
        )
        try await workoutRepo.saveWorkout(workout)
        
        // Simulate network failure on cloud push
        mockDataService.shouldFail = true
        
        let result = try await syncEngine.synchronize()
        XCTAssertEqual(result.pushedCount, 0)
        
        // Queue item must still be present with retry count incremented
        let pending = try await queueManager.fetchPendingItems(limit: 5)
        XCTAssertEqual(pending.count, 1)
        XCTAssertEqual(pending.first?.retryCount, 1)
        XCTAssertNotNil(pending.first?.errorMessage)
    }
    
    func test_conflictResolution_remoteNewerWins() async throws {
        let workoutId = UUID()
        let olderDate = Date().addingTimeInterval(-3600)
        let newerDate = Date()
        
        // Local workout has older timestamp
        let localWorkout = Workout(
            id: workoutId,
            title: "Local Title (Old)",
            activityType: .running,
            startDate: olderDate,
            updatedAt: olderDate,
            source: .manualEntry
        )
        try await workoutRepo.saveWorkout(localWorkout)
        try await queueManager.clearQueue()
        
        // Remote workout has newer timestamp
        let remoteWorkout = RemoteWorkout(
            from: Workout(
                id: workoutId,
                title: "Remote Title (Updated on Web)",
                activityType: .running,
                startDate: olderDate,
                updatedAt: newerDate,
                source: .manualEntry
            ),
            userId: mockAuth.userIdToReturn
        )
        mockDataService.workoutsToReturn = [remoteWorkout]
        
        let result = try await syncEngine.synchronize()
        XCTAssertEqual(result.pulledCount, 1)
        
        let fetched = try await workoutRepo.fetchWorkout(byId: workoutId)
        XCTAssertEqual(fetched?.title, "Remote Title (Updated on Web)")
    }
    
    func test_conflictResolution_localNewerKept() async throws {
        let workoutId = UUID()
        let olderDate = Date().addingTimeInterval(-3600)
        let newerDate = Date()
        
        // Local workout has newer timestamp
        let localWorkout = Workout(
            id: workoutId,
            title: "Local Title (Latest on Phone)",
            activityType: .running,
            startDate: olderDate,
            updatedAt: newerDate,
            source: .manualEntry
        )
        try await workoutRepo.saveWorkout(localWorkout)
        try await queueManager.clearQueue()
        
        // Remote workout has older timestamp
        let remoteWorkout = RemoteWorkout(
            from: Workout(
                id: workoutId,
                title: "Stale Remote Title",
                activityType: .running,
                startDate: olderDate,
                updatedAt: olderDate,
                source: .manualEntry
            ),
            userId: mockAuth.userIdToReturn
        )
        mockDataService.workoutsToReturn = [remoteWorkout]
        
        let result = try await syncEngine.synchronize()
        XCTAssertEqual(result.pulledCount, 0)
        
        let fetched = try await workoutRepo.fetchWorkout(byId: workoutId)
        XCTAssertEqual(fetched?.title, "Local Title (Latest on Phone)")
    }
}
