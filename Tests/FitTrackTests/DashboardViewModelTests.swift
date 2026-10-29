import XCTest
@testable import FitTrack

@MainActor
final class DashboardViewModelTests: XCTestCase {
    
    var inMemoryStack: CoreDataStack!
    var mockHealthKit: MockHealthKitService!
    var cacheRepo: DailyMetricCacheRepository!
    var goalRepo: LocalGoalRepository!
    var workoutRepo: LocalWorkoutRepository!
    var viewModel: DashboardViewModel!
    
    override func setUp() {
        super.setUp()
        inMemoryStack = CoreDataStack(inMemory: true)
        mockHealthKit = MockHealthKitService()
        cacheRepo = DailyMetricCacheRepository(coreDataStack: inMemoryStack)
        goalRepo = LocalGoalRepository(coreDataStack: inMemoryStack)
        workoutRepo = LocalWorkoutRepository(coreDataStack: inMemoryStack)
        
        viewModel = DashboardViewModel(
            healthKitService: mockHealthKit,
            cacheRepository: cacheRepo,
            goalRepository: goalRepo,
            workoutRepository: workoutRepo
        )
    }
    
    override func tearDown() {
        viewModel = nil
        workoutRepo = nil
        goalRepo = nil
        cacheRepo = nil
        mockHealthKit = nil
        inMemoryStack = nil
        super.tearDown()
    }
    
    func test_loadDashboardData_populatesLiveMetricsFromHealthKit() async throws {
        mockHealthKit.mockStepCount = 9200
        mockHealthKit.mockActiveEnergy = 450
        mockHealthKit.mockDistance = 6100
        
        await viewModel.loadDashboardData()
        
        XCTAssertEqual(viewModel.todaySummary.stepCount, 9200)
        XCTAssertEqual(viewModel.todaySummary.activeEnergyKcal, 450)
        XCTAssertEqual(viewModel.todaySummary.distanceMeters, 6100)
        XCTAssertEqual(viewModel.todaySummary.source, .sensorHealthKit)
        XCTAssertTrue(viewModel.isHealthKitAuthorized)
    }
    
    func test_progressCalculation_computesAccuratePercentageForActiveGoals() async throws {
        mockHealthKit.mockStepCount = 8000
        mockHealthKit.mockActiveEnergy = 600
        await viewModel.loadDashboardData()
        
        let stepGoal = FitnessGoal(metricType: .steps, targetValue: 10000)
        let energyGoal = FitnessGoal(metricType: .activeEnergy, targetValue: 500)
        
        let stepProgress = viewModel.progress(for: stepGoal)
        let energyProgress = viewModel.progress(for: energyGoal)
        
        XCTAssertEqual(stepProgress, 0.8)
        XCTAssertEqual(energyProgress, 1.2) // Over-achievement supported
    }
    
    func test_loadDashboardData_includesLocalManualWorkouts() async throws {
        let manualWorkout = Workout(
            title: "Lunch Gym Session",
            activityType: .strength,
            startDate: Date(),
            duration: 2700,
            caloriesBurned: 260,
            source: .manualEntry
        )
        try await workoutRepo.saveWorkout(manualWorkout)
        
        await viewModel.loadDashboardData()
        
        XCTAssertEqual(viewModel.todaysWorkouts.count, 1)
        XCTAssertEqual(viewModel.todaysWorkouts.first?.title, "Lunch Gym Session")
        XCTAssertEqual(viewModel.todaysWorkouts.first?.source, .manualEntry)
    }
}
