import SwiftUI

public struct HealthKitPermissionBanner: View {
    public let isAuthorized: Bool
    public let onRequestPermission: () -> Void
    
    public init(isAuthorized: Bool, onRequestPermission: @escaping () -> Void) {
        self.isAuthorized = isAuthorized
        self.onRequestPermission = onRequestPermission
    }
    
    public var body: some View {
        if !isAuthorized {
            HStack(spacing: 12) {
                Image(systemName: "heart.text.square.fill")
                    .font(.system(size: 28))
                    .foregroundColor(.red)
                
                VStack(alignment: .leading, spacing: 2) {
                    Text("Enable HealthKit")
                        .font(.subheadline)
                        .fontWeight(.semibold)
                    
                    Text("Sync real-time steps, energy, and distance directly from Apple Health.")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
                
                Spacer()
                
                Button(action: onRequestPermission) {
                    Text("Connect")
                        .font(.caption)
                        .fontWeight(.bold)
                        .padding(.horizontal, 12)
                        .padding(.vertical, 6)
                        .background(Color.blue)
                        .foregroundColor(.white)
                        .cornerRadius(20)
                }
            }
            .padding()
            .background(Color.red.opacity(0.08))
            .cornerRadius(14)
            .overlay(
                RoundedRectangle(cornerRadius: 14)
                    .stroke(Color.red.opacity(0.2), lineWidth: 1)
            )
        }
    }
}
