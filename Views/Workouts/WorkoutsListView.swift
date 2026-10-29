import SwiftUI

public struct WorkoutsListView: View {
    @StateObject private var viewModel: WorkoutsViewModel
    @AppStorage("fittrack.units.isImperial") private var isImperial: Bool = false
    @State private var showingAddSheet: Bool = false
    @State private var selectedWorkoutForEdit: Workout? = nil
    
    public init(viewModel: WorkoutsViewModel = WorkoutsViewModel()) {
        _viewModel = StateObject(wrappedValue: viewModel)
    }
    
    public var body: some View {
        NavigationStack {
            VStack(spacing: 0) {
                
                // Activity Filter Chips
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: 10) {
                        FilterChip(
                            title: "All",
                            isSelected: viewModel.selectedActivityFilter == nil,
                            action: { viewModel.selectedActivityFilter = nil }
                        )
                        
                        ForEach(ActivityType.allCases, id: \.self) { type in
                            FilterChip(
                                title: type.displayName,
                                isSelected: viewModel.selectedActivityFilter == type,
                                action: { viewModel.selectedActivityFilter = type }
                            )
                        }
                    }
                    .padding(.horizontal)
                    .padding(.vertical, 10)
                }
                .background(Color.fitBackground)
                
                // Workout List
                if viewModel.filteredWorkouts.isEmpty {
                    Spacer()
                    VStack(spacing: 12) {
                        Image(systemName: "figure.walk.circle")
                            .font(.system(size: 48))
                            .foregroundColor(.secondary)
                        Text("No Workouts Found")
                            .font(.headline)
                        Text("Log your fitness sessions manually or track with Apple Health.")
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                            .multilineTextAlignment(.center)
                            .padding(.horizontal, 32)
                        
                        Button {
                            showingAddSheet = true
                        } label: {
                            Label("Log Workout", systemImage: "plus")
                                .fontWeight(.semibold)
                                .padding(.horizontal, 20)
                                .padding(.vertical, 10)
                                .background(Color.blue)
                                .foregroundColor(.white)
                                .cornerRadius(22)
                        }
                        .padding(.top, 8)
                    }
                    Spacer()
                } else {
                    List {
                        ForEach(viewModel.filteredWorkouts) { workout in
                            WorkoutRowView(workout: workout, isImperial: isImperial)
                                .listRowSeparator(.hidden)
                                .listRowInsets(EdgeInsets(top: 6, leading: 16, bottom: 6, trailing: 16))
                                .contentShape(Rectangle())
                                .onTapGesture {
                                    selectedWorkoutForEdit = workout
                                }
                                .swipeActions(edge: .trailing, allowsFullSwipe: true) {
                                    Button(role: .destructive) {
                                        Task {
                                            await viewModel.deleteWorkout(id: workout.id)
                                        }
                                    } label: {
                                        Label("Delete", systemImage: "trash")
                                    }
                                }
                        }
                    }
                    .listStyle(.plain)
                    .refreshable {
                        await viewModel.loadWorkouts()
                    }
                }
            }
            .navigationTitle("Workouts")
            .toolbar {
                ToolbarItem(placement: .primaryAction) {
                    Button {
                        showingAddSheet = true
                    } label: {
                        Image(systemName: "plus.circle.fill")
                            .font(.system(size: 20))
                    }
                }
            }
            .sheet(isPresented: $showingAddSheet) {
                WorkoutFormView(isImperial: isImperial) {
                    Task {
                        await viewModel.loadWorkouts()
                    }
                }
            }
            .sheet(item: $selectedWorkoutForEdit) { workout in
                WorkoutFormView(workout: workout, isImperial: isImperial) {
                    Task {
                        await viewModel.loadWorkouts()
                    }
                }
            }
            .task {
                await viewModel.loadWorkouts()
            }
        }
    }
}

private struct FilterChip: View {
    let title: String
    let isSelected: Bool
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            Text(title)
                .font(.subheadline)
                .fontWeight(isSelected ? .semibold : .regular)
                .padding(.horizontal, 14)
                .padding(.vertical, 6)
                .background(isSelected ? Color.blue : Color.fitSecondaryBackground)
                .foregroundColor(isSelected ? .white : .primary)
                .cornerRadius(18)
        }
    }
}
