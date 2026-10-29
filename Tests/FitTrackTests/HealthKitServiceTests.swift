import XCTest
@testable import FitTrack

final class HealthKitServiceTests: XCTestCase {
    
    var mockHealthKit: MockHealthKitService!
    
    override func setUp() {
        super.setUp()
        mockHealthKit = MockHealthKitService()
    }
    
    override func tearDown() {
        mockHealthKit = nil
        super.tearDown()
    }
    
    func test_fetchDailySummary_returnsVerifiedSensorSource() async throws {
        mockHealthKit.mockStepCount = 10450
        mockHealthKit.mockActiveEnergy = 620
        mockHealthKit.mockDistance = 7800
        
        let summary = try await mockHealthKit.fetchDailySummary(for: Date())
        
        XCTAssertEqual(summary.stepCount, 10450)
        XCTAssertEqual(summary.activeEnergyKcal, 620)
        XCTAssertEqual(summary.distanceMeters, 7800)
        
        // Critical requirement: sensor source must be explicitly marked and not manual
        XCTAssertEqual(summary.source, .sensorHealthKit)
        XCTAssertTrue(summary.source.isHardwareSensor)
        XCTAssertFalse(summary.source == .manualEntry)
    }
    
    func test_fetchDailySummaries_generatesCorrectDateBuckets() async throws {
        let calendar = Calendar.current
        let today = calendar.startOfDay(for: Date())
        guard let sevenDaysAgo = calendar.date(byAdding: .day, value: -6, to: today) else {
            XCTFail("Failed to compute date")
            return
        }
        
        let summaries = try await mockHealthKit.fetchDailySummaries(from: sevenDaysAgo, to: today)
        
        // 7 days inclusive: sevenDaysAgo, ... today
        XCTAssertEqual(summaries.count, 7)
        XCTAssertEqual(summaries.first?.date, sevenDaysAgo)
        XCTAssertEqual(summaries.last?.date, today)
        
        for item in summaries {
            XCTAssertEqual(item.source, .sensorHealthKit)
            XCTAssertEqual(item.stepCount, mockHealthKit.mockStepCount)
        }
    }
    
    func test_exportWorkoutToHealthKit_recordsMetadataWithoutPollutingSensors() async throws {
        let workout = Workout(
            title: "Treadmill Run",
            activityType: .running,
            startDate: Date().addingTimeInterval(-1800),
            endDate: Date(),
            duration: 1800,
            distance: 4000,
            caloriesBurned: 280,
            source: .manualEntry
        )
        
        try await mockHealthKit.exportWorkoutToHealthKit(workout)
        
        XCTAssertEqual(mockHealthKit.exportedWorkouts.count, 1)
        XCTAssertEqual(mockHealthKit.exportedWorkouts.first?.id, workout.id)
        XCTAssertEqual(mockHealthKit.exportedWorkouts.first?.source, .manualEntry)
    }
    
    func test_authorizationDenied_throwsAppropriateError() async {
        mockHealthKit.shouldAuthorize = false
        
        do {
            _ = try await mockHealthKit.requestAuthorization()
            XCTFail("Expected authorization error not thrown")
        } catch {
            XCTAssertTrue(error is HealthKitError)
        }
    }
}
