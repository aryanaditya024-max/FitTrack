import Foundation

/// Represents the synchronization state of a local entity with Supabase cloud.
public enum SyncStatus: Int16, Codable, CaseIterable, Sendable {
    case synced = 0
    case pendingSync = 1
    case syncFailed = 2
    
    public var title: String {
        switch self {
        case .synced:
            return "Synced"
        case .pendingSync:
            return "Pending Sync"
        case .syncFailed:
            return "Sync Failed"
        }
    }
    
    public var iconName: String {
        switch self {
        case .synced:
            return "checkmark.icloud"
        case .pendingSync:
            return "arrow.triangle.2.circlepath.icloud"
        case .syncFailed:
            return "exclamationmark.icloud"
        }
    }
}
