import SwiftUI

#if canImport(UIKit)
import UIKit
#endif

extension Color {
    public static let fitSteps = Color(red: 0.12, green: 0.73, blue: 0.85) // Bright Cyan
    public static let fitCalories = Color(red: 0.98, green: 0.33, blue: 0.22) // Energetic Orange-Red
    public static let fitDistance = Color(red: 0.35, green: 0.78, blue: 0.35) // Fresh Lime Green
    public static let fitAccent = Color(red: 0.24, green: 0.44, blue: 0.98) // Royal Blue
    
    #if canImport(UIKit)
    public static let fitBackground = Color(UIColor.systemBackground)
    public static let fitSecondaryBackground = Color(UIColor.secondarySystemBackground)
    public static let fitCardBackground = Color(UIColor.secondarySystemBackground)
    public static let fitSecondaryText = Color(UIColor.secondaryLabel)
    #else
    public static let fitBackground = Color.black
    public static let fitSecondaryBackground = Color.gray.opacity(0.15)
    public static let fitCardBackground = Color.gray.opacity(0.15)
    public static let fitSecondaryText = Color.secondary
    #endif
}
