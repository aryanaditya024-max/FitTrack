import Foundation
import CoreData

extension CDSyncQueueItem {

    @nonobjc public class func fetchRequest() -> NSFetchRequest<CDSyncQueueItem> {
        return NSFetchRequest<CDSyncQueueItem>(entityName: "CDSyncQueueItem")
    }

    @NSManaged public var createdAt: Date?
    @NSManaged public var entityId: UUID?
    @NSManaged public var entityType: String?
    @NSManaged public var errorMessage: String?
    @NSManaged public var id: UUID?
    @NSManaged public var lastAttempt: Date?
    @NSManaged public var operation: String?
    @NSManaged public var payload: Data?
    @NSManaged public var retryCount: Int16

}

extension CDSyncQueueItem : Identifiable {

}
