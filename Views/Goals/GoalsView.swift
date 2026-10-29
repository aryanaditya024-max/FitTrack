import SwiftUI

@MainActor
public struct GoalsView: View {
    @StateObject private var viewModel: GoalsViewModel
    @AppStorage("fittrack.units.isImperial") private var isImperial: Bool = false
    @State private var showingAddGoal: Bool = false
    
    public init(viewModel: GoalsViewModel) {
        _viewModel = StateObject(wrappedValue: viewModel)
    }
    
    public init() {
        _viewModel = StateObject(wrappedValue: GoalsViewModel())
    }
    
    public var body: some View {
        NavigationStack {
            List {
                // Daily Goals Section
                Section("Daily Goals") {
                    if viewModel.dailyGoals.isEmpty {
                        Text("No daily goals set. Tap '+' to create one.")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    } else {
                        ForEach(viewModel.dailyGoals) { goal in
                            GoalRowView(goal: goal, isImperial: isImperial) {
                                Task {
                                    await viewModel.toggleGoalActive(goal: goal)
                                }
                            }
                            .listRowSeparator(.hidden)
                            .listRowInsets(EdgeInsets(top: 4, leading: 16, bottom: 4, trailing: 16))
                            .swipeActions(edge: .trailing, allowsFullSwipe: true) {
                                Button(role: .destructive) {
                                    Task {
                                        await viewModel.deleteGoal(id: goal.id)
                                    }
                                } label: {
                                    Label("Delete", systemImage: "trash")
                                }
                            }
                        }
                    }
                }
                
                // Weekly Goals Section
                Section("Weekly Goals") {
                    if viewModel.weeklyGoals.isEmpty {
                        Text("No weekly goals set. Tap '+' to create one.")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    } else {
                        ForEach(viewModel.weeklyGoals) { goal in
                            GoalRowView(goal: goal, isImperial: isImperial) {
                                Task {
                                    await viewModel.toggleGoalActive(goal: goal)
                                }
                            }
                            .listRowSeparator(.hidden)
                            .listRowInsets(EdgeInsets(top: 4, leading: 16, bottom: 4, trailing: 16))
                            .swipeActions(edge: .trailing, allowsFullSwipe: true) {
                                Button(role: .destructive) {
                                    Task {
                                        await viewModel.deleteGoal(id: goal.id)
                                    }
                                } label: {
                                    Label("Delete", systemImage: "trash")
                                }
                            }
                        }
                    }
                }
            }
            .listStyle(.insetGrouped)
            .navigationTitle("Fitness Goals")
            .toolbar {
                ToolbarItem(placement: .primaryAction) {
                    Button {
                        showingAddGoal = true
                    } label: {
                        Image(systemName: "plus.circle.fill")
                            .font(.system(size: 20))
                    }
                }
            }
            .sheet(isPresented: $showingAddGoal) {
                GoalFormView { metric, target, freq in
                    Task {
                        _ = await viewModel.saveGoal(metricType: metric, targetValue: target, frequency: freq)
                    }
                }
            }
            .task {
                await viewModel.loadGoals()
            }
            .refreshable {
                await viewModel.loadGoals()
            }
        }
    }
}
