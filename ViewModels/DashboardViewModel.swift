import Foundation
import Combine

@MainActor
public final class DashboardViewModel: ObservableObject {
    
    @Published public var todaySummary: DailyMetricSummary
    @Published public var activeGoals: [FitnessGoal] = []
    @Published public var todaysWorkouts: [Workout] = []
    @Published public var isLoading: Bool = false
    @Published public var errorMessage: String? = nil
    @Published public var isHealthKitAuthorized: Bool = false
    
    private let healthKitService: HealthKitServiceProtocol
    private let cacheRepository: DailyMetricCacheRepositoryProtocol
    private let goalRepository: GoalRepositoryProtocol
    private let workoutRepository: WorkoutRepositoryProtocol
    
    public init(
        healthKitService: HealthKitServiceProtocol = HealthKitService.shared,
        cacheRepository: DailyMetricCacheRepositoryProtocol = DailyMetricCacheRepository(),
        goalRepository: GoalRepositoryProtocol = LocalGoalRepository(),
        workoutRepository: WorkoutRepositoryProtocol = LocalWorkoutRepository()
    ) {
        self.healthKitService = healthKitService
        self.cacheRepository = cacheRepository
        self.goalRepository = goalRepository
        self.workoutRepository = workoutRepository
        self.todaySummary = DailyMetricSummary(date: Date())
    }
    
    public func loadDashboardData() async {
        isLoading = true
        errorMessage = nil
        
        let today = Date()
        
        // 1. First load from local Core Data cache for instant display
        if let cached = try? await cacheRepository.fetchMetrics(for: today) {
            self.todaySummary = cached
        }
        
        // 2. Load active goals and today's manual/recorded workouts
        do {
            async let goalsTask = goalRepository.fetchActiveGoals()
            async let workoutsTask = workoutRepository.fetchWorkouts(
                from: today.startOfDay,
                to: today.endOfDay
            )
            
            let (goals, workouts) = try await (goalsTask, workoutsTask)
            self.activeGoals = goals
            self.todaysWorkouts = workouts
        } catch {
            self.errorMessage = "Failed to load local activity: \(error.localizedDescription)"
        }
        
        // 3. Query HealthKit live sensor values if authorized
        if healthKitService.isHealthDataAvailable() {
            do {
                let liveSummary = try await healthKitService.fetchDailySummary(for: today)
                self.todaySummary = liveSummary
                self.isHealthKitAuthorized = true
                
                // Cache into Core Data
                try? await cacheRepository.saveDailyMetrics(liveSummary)
            } catch {
                // If denied or failed, fallback remains on cached metrics
                self.isHealthKitAuthorized = false
            }
        }
        
        isLoading = false
    }
    
    public func requestHealthKitPermissions() async {
        do {
            let success = try await healthKitService.requestAuthorization()
            self.isHealthKitAuthorized = success
            if success {
                await loadDashboardData()
            }
        } catch {
            self.errorMessage = "HealthKit permission error: \(error.localizedDescription)"
            self.isHealthKitAuthorized = false
        }
    }
    
    /// Returns progress percentage (0.0 to 1.0+) for a given goal based on today's telemetry
    public func progress(for goal: FitnessGoal) -> Double {
        switch goal.metricType {
        case .steps:
            return goal.progress(currentValue: todaySummary.stepCount)
        case .activeEnergy:
            return goal.progress(currentValue: todaySummary.activeEnergyKcal)
        case .distance:
            return goal.progress(currentValue: todaySummary.distanceMeters)
        case .workoutDuration:
            let totalDuration = todaysWorkouts.reduce(0.0) { $0 + $1.duration }
            return goal.progress(currentValue: totalDuration)
        }
    }
}
