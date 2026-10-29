import XCTest
import CoreData
@testable import FitTrack

final class SyncQueueManagerTests: XCTestCase {
    
    var inMemoryStack: CoreDataStack!
    var syncQueue: SyncQueueManager!
    
    override func setUp() {
        super.setUp()
        inMemoryStack = CoreDataStack(inMemory: true)
        syncQueue = SyncQueueManager(coreDataStack: inMemoryStack)
    }
    
    override func tearDown() {
        syncQueue = nil
        inMemoryStack = nil
        super.tearDown()
    }
    
    func test_enqueueAndFetchPendingItems() async throws {
        let entityId = UUID()
        let dummyPayload = "{\"title\":\"Run\"}".data(using: .utf8)
        
        try await syncQueue.enqueue(
            entityType: "workout",
            entityId: entityId,
            operation: .create,
            payload: dummyPayload
        )
        
        let pending = try await syncQueue.fetchPendingItems(limit: 10)
        XCTAssertEqual(pending.count, 1)
        XCTAssertEqual(pending.first?.entityId, entityId)
        XCTAssertEqual(pending.first?.operation, .create)
        XCTAssertEqual(pending.first?.retryCount, 0)
    }
    
    func test_markFailed_incrementsRetryCountAndUpdatesTimestamp() async throws {
        let entityId = UUID()
        try await syncQueue.enqueue(
            entityType: "workout",
            entityId: entityId,
            operation: .update,
            payload: nil
        )
        
        let items = try await syncQueue.fetchPendingItems(limit: 1)
        guard let item = items.first else {
            XCTFail("Queue item not found")
            return
        }
        
        try await syncQueue.markFailed(itemId: item.id, error: "Network timeout 504")
        
        let updatedItems = try await syncQueue.fetchPendingItems(limit: 1)
        XCTAssertEqual(updatedItems.first?.retryCount, 1)
        XCTAssertEqual(updatedItems.first?.errorMessage, "Network timeout 504")
        XCTAssertNotNil(updatedItems.first?.lastAttempt)
    }
    
    func test_markCompleted_removesItemFromQueue() async throws {
        let entityId = UUID()
        try await syncQueue.enqueue(
            entityType: "goal",
            entityId: entityId,
            operation: .create,
            payload: nil
        )
        
        let items = try await syncQueue.fetchPendingItems(limit: 1)
        XCTAssertEqual(items.count, 1)
        
        if let id = items.first?.id {
            try await syncQueue.markCompleted(itemId: id)
        }
        
        let remaining = try await syncQueue.fetchPendingItems(limit: 1)
        XCTAssertEqual(remaining.count, 0)
    }
}
