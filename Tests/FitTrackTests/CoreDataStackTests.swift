import XCTest
import CoreData
@testable import FitTrack

final class CoreDataStackTests: XCTestCase {
    
    var inMemoryStack: CoreDataStack!
    
    override func setUp() {
        super.setUp()
        inMemoryStack = CoreDataStack(inMemory: true)
    }
    
    override func tearDown() {
        inMemoryStack = nil
        super.tearDown()
    }
    
    func test_inMemoryStack_initializationSucceeds() {
        XCTAssertNotNil(inMemoryStack.container)
        XCTAssertNotNil(inMemoryStack.viewContext)
        XCTAssertEqual(inMemoryStack.container.persistentStoreDescriptions.first?.type, NSInMemoryStoreType)
    }
    
    func test_performBackgroundTask_savesAndMergesToViewContext() async throws {
        let workoutId = UUID()
        
        try await inMemoryStack.performBackgroundTask { context in
            let entity = CDWorkout(context: context)
            entity.id = workoutId
            entity.title = "Test Run"
            entity.activityType = "running"
            entity.startDate = Date()
            entity.endDate = Date().addingTimeInterval(1800)
            entity.duration = 1800
            entity.distance = 5000
            entity.caloriesBurned = 350
            entity.source = "manual_entry"
            entity.createdAt = Date()
            entity.updatedAt = Date()
            entity.isDeleted = false
            entity.syncStatus = 1
            entity.version = 1
        }
        
        // Fetch on main context to verify automatic merge
        let request: NSFetchRequest<CDWorkout> = CDWorkout.fetchRequest()
        request.predicate = NSPredicate(format: "id == %@", workoutId as CVarArg)
        
        let fetched = try inMemoryStack.viewContext.fetch(request)
        XCTAssertEqual(fetched.count, 1)
        XCTAssertEqual(fetched.first?.title, "Test Run")
        XCTAssertEqual(fetched.first?.source, "manual_entry")
    }
}
