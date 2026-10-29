import SwiftUI
import Charts

@MainActor
public struct ChartsView: View {
    @StateObject private var viewModel: ChartsViewModel
    @AppStorage("fittrack.units.isImperial") private var isImperial: Bool = false
    
    public init(viewModel: ChartsViewModel) {
        _viewModel = StateObject(wrappedValue: viewModel)
    }
    
    public init() {
        _viewModel = StateObject(wrappedValue: ChartsViewModel())
    }
    
    public var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 20) {
                    
                    // Timeframe Selector
                    Picker("Timeframe", selection: $viewModel.selectedTimeframe) {
                        ForEach(ChartTimeframe.allCases) { timeframe in
                            Text(timeframe.rawValue).tag(timeframe)
                        }
                    }
                    .pickerStyle(.segmented)
                    .padding(.horizontal)
                    .onChange(of: viewModel.selectedTimeframe) { _, _ in
                        Task { await viewModel.loadChartData() }
                    }
                    
                    // Metric Selector
                    Picker("Metric", selection: $viewModel.selectedMetric) {
                        ForEach(ChartMetric.allCases) { metric in
                            Text(metric.rawValue).tag(metric)
                        }
                    }
                    .pickerStyle(.segmented)
                    .padding(.horizontal)
                    
                    // Summary Stat Header Card
                    VStack(alignment: .leading, spacing: 12) {
                        HStack {
                            VStack(alignment: .leading, spacing: 4) {
                                Text("Total")
                                    .font(.caption)
                                    .foregroundColor(.secondary)
                                Text(formatValue(viewModel.totalValue))
                                    .font(.system(size: 24, weight: .bold, design: .rounded))
                                    .foregroundColor(.primary)
                            }
                            
                            Spacer()
                            
                            VStack(alignment: .trailing, spacing: 4) {
                                Text("Daily Average")
                                    .font(.caption)
                                    .foregroundColor(.secondary)
                                Text(formatValue(viewModel.averageValue))
                                    .font(.system(size: 20, weight: .semibold, design: .rounded))
                                    .foregroundColor(.secondary)
                            }
                        }
                        
                        Divider()
                        
                        // Swift Charts Visualization
                        MetricBarChartView(
                            data: viewModel.chartData,
                            metric: viewModel.selectedMetric,
                            averageValue: viewModel.averageValue,
                            isImperial: isImperial
                        )
                        .frame(height: 240)
                        .padding(.top, 8)
                    }
                    .padding()
                    .background(Color.fitCardBackground)
                    .cornerRadius(16)
                    .padding(.horizontal)
                    
                    // Insights Tip Card
                    HStack(spacing: 12) {
                        Image(systemName: "lightbulb.fill")
                            .foregroundColor(.yellow)
                            .font(.system(size: 22))
                        
                        VStack(alignment: .leading, spacing: 2) {
                            Text("Activity Pattern")
                                .font(.subheadline)
                                .fontWeight(.semibold)
                            Text("Data includes Apple Health sensor measurements. Manual entries are logged under Workouts.")
                                .font(.caption)
                                .foregroundColor(.secondary)
                        }
                        Spacer()
                    }
                    .padding()
                    .background(Color.yellow.opacity(0.1))
                    .cornerRadius(12)
                    .padding(.horizontal)
                }
                .padding(.vertical)
            }
            .navigationTitle("Analytics")
            .task {
                await viewModel.loadChartData()
            }
            .refreshable {
                await viewModel.loadChartData()
            }
        }
    }
    
    private func formatValue(_ val: Double) -> String {
        switch viewModel.selectedMetric {
        case .steps:
            return "\(Int(val)) steps"
        case .calories:
            return "\(Int(val)) kcal"
        case .distance:
            if isImperial {
                let miles = val / 1609.344
                return String(format: "%.2f mi", miles)
            } else {
                let km = val / 1000.0
                return String(format: "%.2f km", km)
            }
        }
    }
}
