import SwiftUI
import Combine

@MainActor
public final class AppState: ObservableObject {
    
    public static let shared = AppState()
    
    @Published public var isOnline: Bool = true
    @Published public var isSyncing: Bool = false
    @Published public var lastSyncTime: Date? = nil
    @Published public var syncMessage: String? = nil
    
    private let networkMonitor: NetworkMonitorProtocol
    private let syncEngine: SyncEngineProtocol
    private let authService: SupabaseAuthServiceProtocol
    private var cancellables = Set<AnyCancellable>()
    
    public init(
        networkMonitor: NetworkMonitorProtocol = NetworkMonitor.shared,
        syncEngine: SyncEngineProtocol = SyncEngine.shared,
        authService: SupabaseAuthServiceProtocol = SupabaseAuthService.shared
    ) {
        self.networkMonitor = networkMonitor
        self.syncEngine = syncEngine
        self.authService = authService
        self.isOnline = networkMonitor.isConnected
        self.lastSyncTime = syncEngine.lastSyncDate
        
        setupNetworkObserver()
        setupLifecycleObservers()
    }
    
    public func syncNow() async {
        guard isOnline else {
            syncMessage = "Device is offline. Changes are saved locally."
            return
        }
        
        guard authService.isAuthenticated() else {
            // Local-first mode: zero error, functions offline gracefully
            return
        }
        
        isSyncing = true
        syncMessage = "Syncing with cloud..."
        
        do {
            let result = try await syncEngine.synchronize()
            self.lastSyncTime = syncEngine.lastSyncDate
            self.syncMessage = "Sync complete (\(result.pushedCount) pushed, \(result.pulledCount) pulled)"
            self.isSyncing = false
        } catch {
            self.syncMessage = "Sync failed: \(error.localizedDescription)"
            self.isSyncing = false
        }
    }
    
    private func setupNetworkObserver() {
        networkMonitor.startMonitoring { [weak self] connected in
            Task { @MainActor [weak self] in
                guard let self = self else { return }
                let previousState = self.isOnline
                self.isOnline = connected
                
                // When transitioning from offline to online, automatically trigger sync
                if !previousState && connected {
                    await self.syncNow()
                }
            }
        }
    }
    
    private func setupLifecycleObservers() {
        NotificationCenter.default.publisher(for: UIApplication.willEnterForegroundNotification)
            .sink { [weak self] _ in
                Task { @MainActor [weak self] in
                    await self?.syncNow()
                }
            }
            .store(in: &cancellables)
    }
}
