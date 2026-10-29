import SwiftUI

@MainActor
public struct DashboardView: View {
    @StateObject private var viewModel: DashboardViewModel
    @AppStorage("fittrack.units.isImperial") private var isImperial: Bool = false
    
    public init(viewModel: DashboardViewModel) {
        _viewModel = StateObject(wrappedValue: viewModel)
    }
    
    public init() {
        _viewModel = StateObject(wrappedValue: DashboardViewModel())
    }
    
    public var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 20) {
                    
                    // HealthKit Connect Banner if unauthorized
                    HealthKitPermissionBanner(
                        isAuthorized: viewModel.isHealthKitAuthorized,
                        onRequestPermission: {
                            Task {
                                await viewModel.requestHealthKitPermissions()
                            }
                        }
                    )
                    
                    // Primary Metrics Grid
                    LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 14) {
                        MetricCardView(
                            title: "Steps",
                            value: viewModel.todaySummary.stepCount.formattedSteps,
                            subtitle: "Goal: 10,000",
                            iconName: "figure.walk",
                            tintColor: .fitSteps
                        )
                        
                        MetricCardView(
                            title: "Active Calories",
                            value: viewModel.todaySummary.activeEnergyKcal.formattedCalories,
                            subtitle: "Goal: 500 kcal",
                            iconName: "flame.fill",
                            tintColor: .fitCalories
                        )
                        
                        MetricCardView(
                            title: "Distance",
                            value: viewModel.todaySummary.formattedDistance(inImperial: isImperial),
                            subtitle: isImperial ? "Miles walked/run" : "Kilometers walked/run",
                            iconName: "location.fill",
                            tintColor: .fitDistance
                        )
                        
                        MetricCardView(
                            title: "Workouts",
                            value: "\(viewModel.todaysWorkouts.count)",
                            subtitle: "Logged today",
                            iconName: "dumbbell.fill",
                            tintColor: .fitAccent
                        )
                    }
                    
                    // Active Goals Section
                    if !viewModel.activeGoals.isEmpty {
                        VStack(alignment: .leading, spacing: 12) {
                            Text("Goal Progress")
                                .font(.headline)
                                .foregroundColor(.primary)
                            
                            ScrollView(.horizontal, showsIndicators: false) {
                                HStack(spacing: 16) {
                                    ForEach(viewModel.activeGoals) { goal in
                                        let currentProgress = viewModel.progress(for: goal)
                                        VStack(spacing: 8) {
                                            ActivityRingView(
                                                progress: currentProgress,
                                                ringColor: colorForMetric(goal.metricType),
                                                lineWidth: 8,
                                                iconName: goal.metricType.systemImageName
                                            )
                                            .frame(width: 55, height: 55)
                                            
                                            Text(goal.metricType.displayName)
                                                .font(.caption2)
                                                .fontWeight(.medium)
                                            
                                            Text("\(Int(currentProgress * 100))%")
                                                .font(.caption)
                                                .fontWeight(.bold)
                                                .foregroundColor(.secondary)
                                        }
                                        .frame(width: 90)
                                        .padding(.vertical, 12)
                                        .background(Color.fitCardBackground)
                                        .cornerRadius(12)
                                    }
                                }
                            }
                        }
                    }
                    
                    // Today's Workouts Snippet
                    VStack(alignment: .leading, spacing: 12) {
                        Text("Today's Workouts")
                            .font(.headline)
                            .foregroundColor(.primary)
                        
                        if viewModel.todaysWorkouts.isEmpty {
                            HStack {
                                Spacer()
                                VStack(spacing: 8) {
                                    Image(systemName: "figure.run.square.stack")
                                        .font(.system(size: 32))
                                        .foregroundColor(.secondary.opacity(0.6))
                                    Text("No workouts recorded yet today")
                                        .font(.subheadline)
                                        .foregroundColor(.secondary)
                                }
                                .padding(.vertical, 24)
                                Spacer()
                            }
                            .background(Color.fitCardBackground)
                            .cornerRadius(14)
                        } else {
                            VStack(spacing: 10) {
                                ForEach(viewModel.todaysWorkouts) { workout in
                                    WorkoutRowView(workout: workout, isImperial: isImperial)
                                }
                            }
                        }
                    }
                }
                .padding()
            }
            .navigationTitle("FitTrack")
            .refreshable {
                await viewModel.loadDashboardData()
            }
            .task {
                await viewModel.loadDashboardData()
            }
        }
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
