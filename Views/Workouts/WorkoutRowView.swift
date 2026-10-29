import SwiftUI

public struct WorkoutRowView: View {
    public let workout: Workout
    public let isImperial: Bool
    
    public init(workout: Workout, isImperial: Bool = false) {
        self.workout = workout
        self.isImperial = isImperial
    }
    
    public var body: some View {
        HStack(spacing: 14) {
            // Activity Icon
            ZStack {
                Circle()
                    .fill(Color.fitAccent.opacity(0.12))
                    .frame(width: 44, height: 44)
                
                Image(systemName: workout.activityType.systemImageName)
                    .font(.system(size: 20))
                    .foregroundColor(.fitAccent)
            }
            
            // Details
            VStack(alignment: .leading, spacing: 4) {
                HStack(spacing: 6) {
                    Text(workout.title)
                        .font(.headline)
                        .foregroundColor(.primary)
                    
                    // Source Badge: Highlights sensor vs manual
                    Text(workout.source == .manualEntry ? "Manual" : "HealthKit")
                        .font(.system(size: 9, weight: .bold))
                        .padding(.horizontal, 6)
                        .padding(.vertical, 2)
                        .background(workout.source == .manualEntry ? Color.orange.opacity(0.15) : Color.blue.opacity(0.15))
                        .foregroundColor(workout.source == .manualEntry ? .orange : .blue)
                        .cornerRadius(6)
                }
                
                HStack(spacing: 12) {
                    Label(workout.formattedDuration, systemImage: "clock")
                    if workout.distance > 0 {
                        Label(workout.formattedDistance(inImperial: isImperial), systemImage: "location")
                    }
                    if workout.caloriesBurned > 0 {
                        Label(workout.formattedCalories, systemImage: "flame")
                    }
                }
                .font(.caption)
                .foregroundColor(.secondary)
            }
            
            Spacer()
            
            // Start Date Time
            Text(workout.startDate.formattedTime())
                .font(.caption2)
                .foregroundColor(.secondary)
        }
        .padding()
        .background(Color.fitCardBackground)
        .cornerRadius(14)
    }
}
