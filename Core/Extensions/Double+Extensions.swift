import Foundation

extension Double {
    /// Formats meters into either kilometers (km) or miles (mi)
    public func formattedDistance(inImperial: Bool) -> String {
        if inImperial {
            let miles = self / 1609.344
            return String(format: "%.2f mi", miles)
        } else {
            let km = self / 1000.0
            return String(format: "%.2f km", km)
        }
    }
    
    /// Formats calories with thousands separators
    public var formattedCalories: String {
        let formatter = NumberFormatter()
        formatter.numberStyle = .decimal
        formatter.maximumFractionDigits = 0
        return "\(formatter.string(from: NSNumber(value: self)) ?? "0") kcal"
    }
    
    /// Formats steps count
    public var formattedSteps: String {
        let formatter = NumberFormatter()
        formatter.numberStyle = .decimal
        formatter.maximumFractionDigits = 0
        return formatter.string(from: NSNumber(value: self)) ?? "0"
    }
}
