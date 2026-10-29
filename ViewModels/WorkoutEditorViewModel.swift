import Foundation
import Combine

@MainActor
public final class WorkoutEditorViewModel: ObservableObject {
    
    @Published public var title: String
    @Published public var activityType: ActivityType
    @Published public var startDate: Date
    @Published public var endDate: Date
    @Published public var distanceText: String // in km or mi
    @Published public var caloriesText: String
    @Published public var isSaving: Bool = false
    @Published public var errorMessage: String? = nil
    
    private let existingWorkout: Workout?
    private let repository: WorkoutRepositoryProtocol
    private let isImperial: Bool
    
    public init(
        workout: Workout? = nil,
        repository: WorkoutRepositoryProtocol = LocalWorkoutRepository(),
        isImperial: Bool = false
    ) {
        self.existingWorkout = workout
        self.repository = repository
        self.isImperial = isImperial
        
        if let w = workout {
            self.title = w.title
            self.activityType = w.activityType
            self.startDate = w.startDate
            self.endDate = w.endDate
            
            if isImperial {
                let miles = w.distance / 1609.344
                self.distanceText = miles > 0 ? String(format: "%.2f", miles) : ""
            } else {
                let km = w.distance / 1000.0
                self.distanceText = km > 0 ? String(format: "%.2f", km) : ""
            }
            self.caloriesText = w.caloriesBurned > 0 ? String(format: "%.0f", w.caloriesBurned) : ""
        } else {
            self.title = ""
            self.activityType = .running
            self.startDate = Date().addingTimeInterval(-1800)
            self.endDate = Date()
            self.distanceText = ""
            self.caloriesText = ""
        }
    }
    
    public var isValid: Bool {
        !title.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty && endDate > startDate
    }
    
    public func save() async -> Bool {
        guard isValid else {
            errorMessage = "Please enter a title and verify workout duration."
            return false
        }
        
        isSaving = true
        errorMessage = nil
        
        let rawDistance = Double(distanceText) ?? 0.0
        let distanceMeters = isImperial ? (rawDistance * 1609.344) : (rawDistance * 1000.0)
        let calories = Double(caloriesText) ?? 0.0
        let duration = endDate.timeIntervalSince(startDate)
        
        let workoutToSave = Workout(
            id: existingWorkout?.id ?? UUID(),
            userId: existingWorkout?.userId,
            title: title.trimmingCharacters(in: .whitespacesAndNewlines),
            activityType: activityType,
            startDate: startDate,
            endDate: endDate,
            duration: duration,
            distance: distanceMeters,
            caloriesBurned: calories,
            source: existingWorkout?.source ?? .manualEntry,
            version: existingWorkout?.version ?? 1
        )
        
        do {
            try await repository.saveWorkout(workoutToSave)
            isSaving = false
            return true
        } catch {
            self.errorMessage = "Failed to save workout: \(error.localizedDescription)"
            isSaving = false
            return false
        }
    }
}
