import SwiftUI

public struct ActivityRingView: View {
    public let progress: Double // 0.0 to 1.0+
    public let ringColor: Color
    public let lineWidth: CGFloat
    public let iconName: String?
    
    public init(
        progress: Double,
        ringColor: Color,
        lineWidth: CGFloat = 12,
        iconName: String? = nil
    ) {
        self.progress = progress
        self.ringColor = ringColor
        self.lineWidth = lineWidth
        self.iconName = iconName
    }
    
    public var body: some View {
        ZStack {
            // Background Track
            Circle()
                .stroke(ringColor.opacity(0.2), lineWidth: lineWidth)
            
            // Progress Ring
            Circle()
                .trim(from: 0.0, to: CGFloat(min(progress, 1.0)))
                .stroke(
                    ringColor,
                    style: StrokeStyle(lineWidth: lineWidth, lineCap: .round)
                )
                .rotationEffect(Angle(degrees: -90))
                .animation(.easeInOut(duration: 0.8), value: progress)
            
            // Center Icon / Percentage
            if let icon = iconName {
                Image(systemName: icon)
                    .font(.system(size: 20, weight: .bold))
                    .foregroundColor(ringColor)
            } else {
                Text("\(Int(progress * 100))%")
                    .font(.system(size: 14, weight: .bold, design: .rounded))
                    .foregroundColor(.primary)
            }
        }
    }
}
