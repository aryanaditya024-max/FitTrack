import Foundation
import Combine

public enum ChartTimeframe: String, CaseIterable, Identifiable, Sendable {
    case day = "Day"
    case week = "Week"
    case month = "Month"
    
    public var id: String { rawValue }
    
    public var daysCount: Int {
        switch self {
        case .day: return 1
        case .week: return 7
        case .month: return 30
        }
    }
}

public enum ChartMetric: String, CaseIterable, Identifiable, Sendable {
    case steps = "Steps"
    case calories = "Active Energy"
    case distance = "Distance"
    
    public var id: String { rawValue }
    
    public var unitLabel: String {
        switch self {
        case .steps: return "steps"
        case .calories: return "kcal"
        case .distance: return "km"
        }
    }
}

@MainActor
public final class ChartsViewModel: ObservableObject {
    
    @Published public var selectedTimeframe: ChartTimeframe = .week
    @Published public var selectedMetric: ChartMetric = .steps
    @Published public var chartData: [DailyMetricSummary] = []
    @Published public var isLoading: Bool = false
    @Published public var errorMessage: String? = nil
    
    private let healthKitService: HealthKitServiceProtocol
    private let cacheRepository: DailyMetricCacheRepositoryProtocol
    
    public init(
        healthKitService: HealthKitServiceProtocol = HealthKitService.shared,
        cacheRepository: DailyMetricCacheRepositoryProtocol = DailyMetricCacheRepository()
    ) {
        self.healthKitService = healthKitService
        self.cacheRepository = cacheRepository
    }
    
    public var totalValue: Double {
        chartData.reduce(0.0) { sum, item in
            switch selectedMetric {
            case .steps: return sum + item.stepCount
            case .calories: return sum + item.activeEnergyKcal
            case .distance: return sum + item.distanceMeters
            }
        }
    }
    
    public var averageValue: Double {
        guard !chartData.isEmpty else { return 0.0 }
        return totalValue / Double(chartData.count)
    }
    
    public func loadChartData() async {
        isLoading = true
        errorMessage = nil
        
        let calendar = Calendar.current
        let today = calendar.startOfDay(for: Date())
        let daysToSubtract = selectedTimeframe.daysCount - 1
        let startDate = calendar.date(byAdding: .day, value: -daysToSubtract, to: today) ?? today
        
        // 1. Fetch cached metrics from Core Data
        if let cached = try? await cacheRepository.fetchMetrics(from: startDate, to: today), !cached.isEmpty {
            self.chartData = cached
        }
        
        // 2. Fetch fresh sensor data from HealthKit if available
        if healthKitService.isHealthDataAvailable() {
            do {
                let freshSummaries = try await healthKitService.fetchDailySummaries(from: startDate, to: today)
                self.chartData = freshSummaries
                
                // Cache summaries locally
                for item in freshSummaries {
                    try? await cacheRepository.saveDailyMetrics(item)
                }
            } catch {
                // Keep cached data
            }
        }
        
        // If data is empty (e.g. simulator without HealthKit), populate zero-filled buckets for visual continuity
        if chartData.isEmpty {
            var placeholders: [DailyMetricSummary] = []
            var current = startDate
            while current <= today {
                placeholders.append(DailyMetricSummary(date: current, source: .sensorHealthKit))
                guard let next = calendar.date(byAdding: .day, value: 1, to: current) else { break }
                current = next
            }
            self.chartData = placeholders
        }
        
        isLoading = false
    }
}
