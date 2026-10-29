import SwiftUI

public struct GoalRowView: View {
    public let goal: FitnessGoal
    public let isImperial: Bool
    public let onToggleActive: () -> Void
    
    public init(goal: FitnessGoal, isImperial: Bool = false, onToggleActive: @escaping () -> Void = {}) {
        self.goal = goal
        self.isImperial = isImperial
        self.onToggleActive = onToggleActive
    }
    
    public var body: some View {
        HStack(spacing: 14) {
            ZStack {
                Circle()
                    .fill(colorForMetric(goal.metricType).opacity(0.15))
                    .frame(width: 44, height: 44)
                
                Image(systemName: goal.metricType.systemImageName)
                    .font(.system(size: 20))
                    .foregroundColor(colorForMetric(goal.metricType))
            }
            
            VStack(alignment: .leading, spacing: 4) {
                HStack(spacing: 8) {
                    Text(goal.metricType.displayName)
                        .font(.headline)
                        .foregroundColor(goal.isActive ? .primary : .secondary)
                    
                    Text(goal.frequency.displayName)
                        .font(.caption2)
                        .fontWeight(.semibold)
                        .padding(.horizontal, 6)
                        .padding(.vertical, 2)
                        .background(Color.secondary.opacity(0.15))
                        .cornerRadius(6)
                }
                
                Text("Target: \(goal.formattedTarget(inImperial: isImperial))")
                    .font(.subheadline)
                    .foregroundColor(.secondary)
            }
            
            Spacer()
            
            Toggle("", isOn: Binding(
                get: { goal.isActive },
                set: { _ in onToggleActive() }
            ))
            .labelsHidden()
        }
        .padding()
        .background(Color.fitCardBackground)
        .cornerRadius(14)
        .opacity(goal.isActive ? 1.0 : 0.6)
    }
    
    private func colorForMetric(_ type: GoalMetricType) -> Color {
        switch type {
        case .steps: return .fitSteps
        case .activeEnergy: return .fitCalories
        case .distance: return .fitDistance
        case .workoutDuration: return .fitAccent
        }
    }
}
