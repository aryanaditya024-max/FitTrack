import SwiftUI

@MainActor
public struct WorkoutFormView: View {
    @Environment(\.dismiss) private var dismiss
    @StateObject private var viewModel: WorkoutEditorViewModel
    public let onSaved: () -> Void
    
    public init(
        workout: Workout? = nil,
        isImperial: Bool = false,
        onSaved: @escaping () -> Void = {}
    ) {
        _viewModel = StateObject(wrappedValue: WorkoutEditorViewModel(workout: workout, isImperial: isImperial))
        self.onSaved = onSaved
    }
    
    public var body: some View {
        NavigationStack {
            Form {
                Section("Workout Details") {
                    TextField("Title (e.g., Morning Jog)", text: $viewModel.title)
                    
                    Picker("Activity", selection: $viewModel.activityType) {
                        ForEach(ActivityType.allCases, id: \.self) { type in
                            Label(type.displayName, systemImage: type.systemImageName)
                                .tag(type)
                        }
                    }
                }
                
                Section("Timing") {
                    DatePicker("Start Time", selection: $viewModel.startDate)
                    DatePicker("End Time", selection: $viewModel.endDate)
                }
                
                Section("Metrics") {
                    HStack {
                        Text("Distance")
                        Spacer()
                        TextField("0.0", text: $viewModel.distanceText)
                            .keyboardType(.decimalPad)
                            .multilineTextAlignment(.trailing)
                    }
                    
                    HStack {
                        Text("Active Energy (kcal)")
                        Spacer()
                        TextField("0", text: $viewModel.caloriesText)
                            .keyboardType(.numberPad)
                            .multilineTextAlignment(.trailing)
                    }
                }
                
                if let error = viewModel.errorMessage {
                    Section {
                        Text(error)
                            .foregroundColor(.red)
                            .font(.caption)
                    }
                }
            }
            .navigationTitle(viewModel.title.isEmpty ? "Log Workout" : "Edit Workout")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") {
                        dismiss()
                    }
                }
                
                ToolbarItem(placement: .confirmationAction) {
                    Button("Save") {
                        Task {
                            let success = await viewModel.save()
                            if success {
                                onSaved()
                                dismiss()
                            }
                        }
                    }
                    .disabled(!viewModel.isValid || viewModel.isSaving)
                }
            }
        }
    }
}
