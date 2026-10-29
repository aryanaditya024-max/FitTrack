import SwiftUI

@main
@MainActor
public struct FitTrackApp: App {
    private let coreDataStack = CoreDataStack.shared
    @StateObject private var appState = AppState.shared
    
    public init() {}
    
    public var body: some Scene {
        WindowGroup {
            MainTabView()
                .environment(\.managedObjectContext, coreDataStack.viewContext)
                .environmentObject(appState)
        }
    }
}
