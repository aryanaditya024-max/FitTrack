import Foundation

public final class SyncEngine: SyncEngineProtocol, @unchecked Sendable {
    
    public static let shared = SyncEngine()
    
    public private(set) var isSyncing: Bool = false
    public private(set) var lastSyncDate: Date? {
        get {
            let timestamp = UserDefaults.standard.double(forKey: "fittrack.sync.lastTimestamp")
            return timestamp > 0 ? Date(timeIntervalSince1970: timestamp) : nil
        }
        set {
            if let date = newValue {
                UserDefaults.standard.set(date.timeIntervalSince1970, forKey: "fittrack.sync.lastTimestamp")
            }
        }
    }
    
    private let networkMonitor: NetworkMonitorProtocol
    private let syncQueueManager: SyncQueueManagerProtocol
    private let workoutRepository: WorkoutRepositoryProtocol
    private let goalRepository: GoalRepositoryProtocol
    private let authService: SupabaseAuthServiceProtocol
    private let dataService: SupabaseDataServiceProtocol
    
    public init(
        networkMonitor: NetworkMonitorProtocol = NetworkMonitor.shared,
        syncQueueManager: SyncQueueManagerProtocol = SyncQueueManager(),
        workoutRepository: WorkoutRepositoryProtocol = LocalWorkoutRepository(),
        goalRepository: GoalRepositoryProtocol = LocalGoalRepository(),
        authService: SupabaseAuthServiceProtocol = SupabaseAuthService.shared,
        dataService: SupabaseDataServiceProtocol = SupabaseDataService.shared
    ) {
        self.networkMonitor = networkMonitor
        self.syncQueueManager = syncQueueManager
        self.workoutRepository = workoutRepository
        self.goalRepository = goalRepository
        self.authService = authService
        self.dataService = dataService
    }
    
    public func synchronize() async throws -> (pushedCount: Int, pulledCount: Int) {
        guard !isSyncing else {
            return (0, 0)
        }
        
        guard networkMonitor.isConnected else {
            return (0, 0)
        }
        
        guard let currentUserId = authService.currentUserId(), authService.isAuthenticated() else {
            return (0, 0)
        }
        
        isSyncing = true
        defer { isSyncing = false }
        
        var pushed = 0
        var pulled = 0
        
        // ====================================================================
        // PHASE 1: DRAIN OUTBOUND QUEUE (PUSH TO CLOUD)
        // ====================================================================
        let pendingItems = try await syncQueueManager.fetchPendingItems(limit: 50)
        
        for item in pendingItems {
            // Guard against excessive retries (max 5)
            if item.retryCount >= 5 {
                continue
            }
            
            do {
                if item.entityType == "workout" {
                    if let workout = try await workoutRepository.fetchWorkout(byId: item.entityId) {
                        let remote = RemoteWorkout(from: workout, userId: currentUserId)
                        try await dataService.upsertWorkout(remote)
                        
                        try await syncQueueManager.markCompleted(itemId: item.id)
                        try await workoutRepository.updateSyncStatus(id: workout.id, status: .synced)
                        pushed += 1
                    } else if item.operation == .delete {
                        // Soft delete tombstone upload
                        let deletedTombstone = RemoteWorkout(
                            from: Workout(
                                id: item.entityId,
                                title: "Deleted",
                                activityType: .other,
                                startDate: Date(),
                                isDeleted: true
                            ),
                            userId: currentUserId
                        )
                        try await dataService.upsertWorkout(deletedTombstone)
                        try await syncQueueManager.markCompleted(itemId: item.id)
                        pushed += 1
                    }
                } else if item.entityType == "goal" {
                    if let goal = try await goalRepository.fetchGoal(byId: item.entityId) {
                        let remote = RemoteGoal(from: goal, userId: currentUserId)
                        try await dataService.upsertGoal(remote)
                        
                        try await syncQueueManager.markCompleted(itemId: item.id)
                        try await goalRepository.updateSyncStatus(id: goal.id, status: .synced)
                        pushed += 1
                    } else if item.operation == .delete {
                        let deletedTombstone = RemoteGoal(
                            from: FitnessGoal(
                                id: item.entityId,
                                metricType: .steps,
                                targetValue: 1,
                                isDeleted: true
                            ),
                            userId: currentUserId
                        )
                        try await dataService.upsertGoal(deletedTombstone)
                        try await syncQueueManager.markCompleted(itemId: item.id)
                        pushed += 1
                    }
                }
            } catch {
                try await syncQueueManager.markFailed(itemId: item.id, error: error.localizedDescription)
            }
        }
        
        // ====================================================================
        // PHASE 2: INBOUND DELTA FETCH & CONFLICT RESOLUTION (LAST-WRITE-WINS)
        // ====================================================================
        let sinceDate = lastSyncDate ?? Calendar.current.date(byAdding: .day, value: -30, to: Date()) ?? Date()
        
        // 1. Inbound Workouts
        let remoteWorkouts = try await dataService.fetchWorkoutsUpdatedSince(sinceDate)
        for remote in remoteWorkouts {
            let local = try await workoutRepository.fetchWorkout(byId: remote.id)
            
            if let localWorkout = local {
                // Conflict resolution: Last-Write-Wins (LWW)
                if remote.updatedAt > localWorkout.updatedAt {
                    var updatedDomain = remote.toDomain()
                    updatedDomain.syncStatus = .synced
                    try await workoutRepository.saveWorkout(updatedDomain)
                    pulled += 1
                }
            } else if !remote.isDeleted {
                var newDomain = remote.toDomain()
                newDomain.syncStatus = .synced
                try await workoutRepository.saveWorkout(newDomain)
                pulled += 1
            }
        }
        
        // 2. Inbound Goals
        let remoteGoals = try await dataService.fetchGoalsUpdatedSince(sinceDate)
        for remote in remoteGoals {
            let local = try await goalRepository.fetchGoal(byId: remote.id)
            
            if let localGoal = local {
                if remote.updatedAt > localGoal.updatedAt {
                    var updatedDomain = remote.toDomain()
                    updatedDomain.syncStatus = .synced
                    try await goalRepository.saveGoal(updatedDomain)
                    pulled += 1
                }
            } else if !remote.isDeleted {
                var newDomain = remote.toDomain()
                newDomain.syncStatus = .synced
                try await goalRepository.saveGoal(newDomain)
                pulled += 1
            }
        }
        
        self.lastSyncDate = Date()
        return (pushed, pulled)
    }
}
