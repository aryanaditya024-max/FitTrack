import XCTest
@testable import FitTrack

@MainActor
final class ChartsViewModelTests: XCTestCase {
    
    var inMemoryStack: CoreDataStack!
    var mockHealthKit: MockHealthKitService!
    var cacheRepo: DailyMetricCacheRepository!
    var viewModel: ChartsViewModel!
    
    override func setUp() {
        super.setUp()
        inMemoryStack = CoreDataStack(inMemory: true)
        mockHealthKit = MockHealthKitService()
        cacheRepo = DailyMetricCacheRepository(coreDataStack: inMemoryStack)
        
        viewModel = ChartsViewModel(
            healthKitService: mockHealthKit,
            cacheRepository: cacheRepo
        )
    }
    
    override func tearDown() {
        viewModel = nil
        cacheRepo = nil
        mockHealthKit = nil
        inMemoryStack = nil
        super.tearDown()
    }
    
    func test_loadChartData_weekTimeframe_calculatesTotalsAndAverages() async throws {
        mockHealthKit.mockStepCount = 8000
        viewModel.selectedTimeframe = .week
        viewModel.selectedMetric = .steps
        
        await viewModel.loadChartData()
        
        XCTAssertEqual(viewModel.chartData.count, 7)
        // 7 days * 8000 steps = 56000 total
        XCTAssertEqual(viewModel.totalValue, 56000)
        XCTAssertEqual(viewModel.averageValue, 8000)
    }
    
    func test_loadChartData_monthTimeframe_generates30Buckets() async throws {
        viewModel.selectedTimeframe = .month
        await viewModel.loadChartData()
        
        XCTAssertEqual(viewModel.chartData.count, 30)
    }
}
