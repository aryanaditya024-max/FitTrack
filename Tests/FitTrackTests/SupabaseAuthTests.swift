import XCTest
@testable import FitTrack

final class MockAuthService: SupabaseAuthServiceProtocol, @unchecked Sendable {
    var userIdToReturn = UUID()
    var emailToReturn: String? = "testuser@fittrack.com"
    var isAuth = false
    
    func signUp(email: String, password: String) async throws -> UUID {
        isAuth = true
        emailToReturn = email
        return userIdToReturn
    }
    
    func signIn(email: String, password: String) async throws -> UUID {
        isAuth = true
        emailToReturn = email
        return userIdToReturn
    }
    
    func signOut() async throws {
        isAuth = false
        emailToReturn = nil
    }
    
    func currentUserId() -> UUID? {
        return isAuth ? userIdToReturn : nil
    }
    
    func currentUserEmail() -> String? {
        return emailToReturn
    }
    
    func isAuthenticated() -> Bool {
        return isAuth
    }
}

@MainActor
final class SupabaseAuthTests: XCTestCase {
    
    var mockAuth: MockAuthService!
    var viewModel: AuthViewModel!
    
    override func setUp() {
        super.setUp()
        mockAuth = MockAuthService()
        viewModel = AuthViewModel(authService: mockAuth)
    }
    
    override func tearDown() {
        viewModel = nil
        mockAuth = nil
        super.tearDown()
    }
    
    func test_validation_requiresValidEmailAndMinSixCharPassword() {
        viewModel.email = "invalid"
        viewModel.password = "123"
        XCTAssertFalse(viewModel.isValid)
        
        viewModel.email = "runner@fittrack.com"
        viewModel.password = "12345" // 5 chars
        XCTAssertFalse(viewModel.isValid)
        
        viewModel.password = "123456" // 6 chars
        XCTAssertTrue(viewModel.isValid)
    }
    
    func test_authenticate_signUpSuccess_updatesAuthenticatedState() async {
        viewModel.email = "alex@example.com"
        viewModel.password = "securePassword123"
        viewModel.isSignUp = true
        
        let success = await viewModel.authenticate()
        
        XCTAssertTrue(success)
        XCTAssertTrue(viewModel.isAuthenticated)
        XCTAssertEqual(viewModel.currentUserEmail, "alex@example.com")
        XCTAssertNil(viewModel.errorMessage)
    }
    
    func test_signOut_clearsSession() async {
        viewModel.email = "alex@example.com"
        viewModel.password = "securePassword123"
        _ = await viewModel.authenticate()
        
        await viewModel.signOut()
        
        XCTAssertFalse(viewModel.isAuthenticated)
        XCTAssertNil(viewModel.currentUserEmail)
    }
    
    func test_remoteWorkoutDTO_serializesWithPostgreSqlSnakeCaseKeys() throws {
        let domainWorkout = Workout(
            title: "Morning 5K",
            activityType: .running,
            startDate: Date(),
            duration: 1500,
            distance: 5000,
            caloriesBurned: 350,
            source: .manualEntry
        )
        let userId = UUID()
        let remoteDTO = RemoteWorkout(from: domainWorkout, userId: userId)
        
        let encoder = JSONEncoder()
        encoder.dateEncodingStrategy = .iso8601
        let data = try encoder.encode(remoteDTO)
        let jsonString = String(data: data, encoding: .utf8) ?? ""
        
        // Assert PostgreSQL snake_case keys are present
        XCTAssertTrue(jsonString.contains("user_id"))
        XCTAssertTrue(jsonString.contains("activity_type"))
        XCTAssertTrue(jsonString.contains("calories_burned"))
        XCTAssertTrue(jsonString.contains("is_deleted"))
        
        // Assert roundtrip back to domain
        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .iso8601
        let decodedRemote = try decoder.decode(RemoteWorkout.self, from: data)
        let roundtripDomain = decodedRemote.toDomain()
        
        XCTAssertEqual(roundtripDomain.id, domainWorkout.id)
        XCTAssertEqual(roundtripDomain.title, "Morning 5K")
        XCTAssertEqual(roundtripDomain.activityType, .running)
        XCTAssertEqual(roundtripDomain.source, .manualEntry)
    }
}
