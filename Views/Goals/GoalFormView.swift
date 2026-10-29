import SwiftUI

public struct GoalFormView: View {
    @Environment(\.dismiss) private var dismiss
    @State private var metricType: GoalMetricType = .steps
    @State private var frequency: GoalFrequency = .daily
    @State private var targetValueText: String = "10000"
    
    public let onSave: (GoalMetricType, Double, GoalFrequency) -> Void
    
    public init(onSave: @escaping (GoalMetricType, Double, GoalFrequency) -> Void) {
        self.onSave = onSave
    }
    
    public var body: some View {
        NavigationStack {
            Form {
                Section("Goal Type") {
                    Picker("Metric", selection: $metricType) {
                        ForEach(GoalMetricType.allCases, id: \.self) { metric in
                            Text(metric.displayName).tag(metric)
                        }
                    }
                    .onChange(of: metricType) { _, newMetric in
                        switch newMetric {
                        case .steps: targetValueText = "10000"
                        case .activeEnergy: targetValueText = "500"
                        case .distance: targetValueText = "5000"
                        case .workoutDuration: targetValueText = "1800"
                        }
                    }
                    
                    Picker("Frequency", selection: $frequency) {
                        ForEach(GoalFrequency.allCases, id: \.self) { freq in
                            Text(freq.displayName).tag(freq)
                        }
                    }
                    .pickerStyle(.segmented)
                }
                
                Section("Target") {
                    HStack {
                        Text("Target Value (\(metricType.defaultUnit))")
                        Spacer()
                        TextField("Value", text: $targetValueText)
                            .keyboardType(.decimalPad)
                            .multilineTextAlignment(.trailing)
                    }
                }
            }
            .navigationTitle("New Goal")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Save") {
                        if let val = Double(targetValueText), val > 0 {
                            onSave(metricType, val, frequency)
                            dismiss()
                        }
                    }
                    .disabled(Double(targetValueText) == nil || (Double(targetValueText) ?? 0) <= 0)
                }
            }
        }
    }
}
