import Foundation
import Network
import Combine

public protocol NetworkMonitorProtocol: Sendable {
    var isConnected: Bool { get }
    var isConstrained: Bool { get }
    func startMonitoring(onStatusChange: @escaping @Sendable (Bool) -> Void)
    func stopMonitoring()
}

public final class NetworkMonitor: NetworkMonitorProtocol, @unchecked Sendable {
    
    public static let shared = NetworkMonitor()
    
    private let monitor: NWPathMonitor
    private let queue = DispatchQueue(label: "com.fittrack.networkmonitor", qos: .utility)
    
    public private(set) var isConnected: Bool = true
    public private(set) var isConstrained: Bool = false
    private var onStatusChange: (@Sendable (Bool) -> Void)?
    
    public init(monitor: NWPathMonitor = NWPathMonitor()) {
        self.monitor = monitor
        self.isConnected = true
    }
    
    public func startMonitoring(onStatusChange: @escaping @Sendable (Bool) -> Void) {
        self.onStatusChange = onStatusChange
        
        monitor.pathUpdateHandler = { [weak self] path in
            guard let self = self else { return }
            let connected = path.status == .satisfied
            let constrained = path.isConstrained
            
            let statusChanged = (connected != self.isConnected)
            self.isConnected = connected
            self.isConstrained = constrained
            
            if statusChanged {
                self.onStatusChange?(connected)
            }
        }
        
        monitor.start(queue: queue)
    }
    
    public func stopMonitoring() {
        monitor.cancel()
        onStatusChange = nil
    }
}
