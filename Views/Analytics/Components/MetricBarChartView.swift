import SwiftUI
import Charts

public struct MetricBarChartView: View {
    public let data: [DailyMetricSummary]
    public let metric: ChartMetric
    public let averageValue: Double
    public let isImperial: Bool
    
    public init(
        data: [DailyMetricSummary],
        metric: ChartMetric,
        averageValue: Double,
        isImperial: Bool = false
    ) {
        self.data = data
        self.metric = metric
        self.averageValue = averageValue
        self.isImperial = isImperial
    }
    
    public var body: some View {
        Chart {
            // Bars
            ForEach(data) { item in
                let val = value(for: item)
                
                BarMark(
                    x: .value("Date", item.date, unit: .day),
                    y: .value("Value", val)
                )
                .foregroundStyle(barGradient(for: metric))
                .clipShape(RoundedRectangle(cornerRadius: 6))
            }
            
            // Average Reference Line
            if averageValue > 0 {
                RuleMark(
                    y: .value("Average", averageValue)
                )
                .lineStyle(StrokeStyle(lineWidth: 1.5, dash: [5, 5]))
                .foregroundStyle(Color.secondary.opacity(0.8))
                .annotation(position: .top, alignment: .leading) {
                    Text("Avg: \(formattedVal(averageValue))")
                        .font(.caption2)
                        .fontWeight(.bold)
                        .foregroundColor(.secondary)
                }
            }
        }
        .chartXAxis {
            AxisMarks(values: .stride(by: .day, count: data.count > 10 ? 5 : 1)) { value in
                if let date = value.as(Date.self) {
                    AxisValueLabel {
                        Text(data.count > 7 ? date.formattedDayMonth() : date.formattedWeekday())
                            .font(.caption2)
                    }
                }
                AxisTick()
                AxisGridLine()
            }
        }
        .chartYAxis {
            AxisMarks(position: .leading) { value in
                AxisValueLabel {
                    if let doubleVal = value.as(Double.self) {
                        Text(formatYAxis(doubleVal))
                            .font(.caption2)
                    }
                }
                AxisGridLine()
            }
        }
    }
    
    private func value(for summary: DailyMetricSummary) -> Double {
        switch metric {
        case .steps:
            return summary.stepCount
        case .calories:
            return summary.activeEnergyKcal
        case .distance:
            return isImperial ? (summary.distanceMeters / 1609.344) : (summary.distanceMeters / 1000.0)
        }
    }
    
    private func formattedVal(_ val: Double) -> String {
        switch metric {
        case .steps:
            return "\(Int(val))"
        case .calories:
            return "\(Int(val)) kcal"
        case .distance:
            return isImperial ? String(format: "%.1f mi", val) : String(format: "%.1f km", val)
        }
    }
    
    private func formatYAxis(_ val: Double) -> String {
        if val >= 1000 {
            return String(format: "%.0fk", val / 1000)
        }
        return "\(Int(val))"
    }
    
    private func barGradient(for metric: ChartMetric) -> LinearGradient {
        let baseColor: Color
        switch metric {
        case .steps: baseColor = .fitSteps
        case .calories: baseColor = .fitCalories
        case .distance: baseColor = .fitDistance
        }
        
        return LinearGradient(
            colors: [baseColor, baseColor.opacity(0.65)],
            startPoint: .top,
            endPoint: .bottom
        )
    }
}
