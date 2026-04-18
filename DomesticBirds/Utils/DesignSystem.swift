import SwiftUI

// MARK: - Color Palette
extension Color {
    // Primary Palette
    static let dbGreen       = Color(hex: "#3A7D44")   // Deep farm green
    static let dbGreenLight  = Color(hex: "#52A865")   // Leaf green
    static let dbGreenPale   = Color(hex: "#D4EDDA")   // Soft green tint
    static let dbAmber       = Color(hex: "#E8A020")   // Warm amber/wheat
    static let dbAmberLight  = Color(hex: "#F5C842")   // Sunny yellow
    static let dbBrown       = Color(hex: "#7B4F2E")   // Earth brown
    static let dbCream       = Color(hex: "#FDF6EC")   // Warm cream
    static let dbTerra       = Color(hex: "#C1440E")   // Terracotta accent
    // Neutrals
    static let dbSurface     = Color(hex: "#FAFAF7")   // Off-white surface
    static let dbCard        = Color(hex: "#FFFFFF")
    static let dbBorder      = Color(hex: "#E8E4DC")
    static let dbText        = Color(hex: "#1C1C1A")
    static let dbTextSec     = Color(hex: "#6B6860")
    static let dbTextTert    = Color(hex: "#A09E98")
    // Dark mode variants
    static let dbDarkBg      = Color(hex: "#121410")
    static let dbDarkSurface = Color(hex: "#1C1E19")
    static let dbDarkCard    = Color(hex: "#252820")
    static let dbDarkBorder  = Color(hex: "#2E3028")
}

extension Color {
    init(hex: String) {
        let hex = hex.trimmingCharacters(in: CharacterSet.alphanumerics.inverted)
        var int: UInt64 = 0
        Scanner(string: hex).scanHexInt64(&int)
        let a, r, g, b: UInt64
        switch hex.count {
        case 3:
            (a, r, g, b) = (255, (int >> 8) * 17, (int >> 4 & 0xF) * 17, (int & 0xF) * 17)
        case 6:
            (a, r, g, b) = (255, int >> 16, int >> 8 & 0xFF, int & 0xFF)
        case 8:
            (a, r, g, b) = (int >> 24, int >> 16 & 0xFF, int >> 8 & 0xFF, int & 0xFF)
        default:
            (a, r, g, b) = (1, 1, 1, 0)
        }
        self.init(
            .sRGB,
            red: Double(r) / 255,
            green: Double(g) / 255,
            blue: Double(b) / 255,
            opacity: Double(a) / 255
        )
    }
}

// MARK: - Typography
struct DBFont {
    static func title(_ size: CGFloat = 28) -> Font { .system(size: size, weight: .bold, design: .rounded) }
    static func title2(_ size: CGFloat = 22) -> Font { .system(size: size, weight: .bold, design: .rounded) }
    static func title3(_ size: CGFloat = 18) -> Font { .system(size: size, weight: .bold, design: .rounded) }
    static func headline(_ size: CGFloat = 18) -> Font { .system(size: size, weight: .semibold, design: .rounded) }
    static func subheadline(_ size: CGFloat = 15) -> Font { .system(size: size, weight: .medium, design: .rounded) }
    static func body(_ size: CGFloat = 16) -> Font { .system(size: size, weight: .regular, design: .rounded) }
    static func caption(_ size: CGFloat = 13) -> Font { .system(size: size, weight: .medium, design: .rounded) }
    static func label(_ size: CGFloat = 12) -> Font { .system(size: size, weight: .semibold, design: .rounded) }
}

// MARK: - Gradients
extension LinearGradient {
    static var dbGreenGradient: LinearGradient {
        LinearGradient(colors: [.dbGreen, .dbGreenLight], startPoint: .topLeading, endPoint: .bottomTrailing)
    }
    static var dbAmberGradient: LinearGradient {
        LinearGradient(colors: [.dbAmber, .dbAmberLight], startPoint: .topLeading, endPoint: .bottomTrailing)
    }
    static var dbHeroGradient: LinearGradient {
        LinearGradient(colors: [Color(hex: "#2D5A35"), Color(hex: "#3A7D44"), Color(hex: "#52A865")],
                       startPoint: .topLeading, endPoint: .bottomTrailing)
    }
    static var dbEarthGradient: LinearGradient {
        LinearGradient(colors: [Color(hex: "#7B4F2E"), Color(hex: "#A0633A")],
                       startPoint: .topLeading, endPoint: .bottomTrailing)
    }
}

// MARK: - DBColor wrapper
struct DBColor {
    let swiftUIColor: Color
}

// MARK: - DBColors
struct DBColors {
    static let dbGreen      = DBColor(swiftUIColor: .dbGreen)
    static let dbGreenLight = DBColor(swiftUIColor: .dbGreenLight)
    static let dbGreenPale  = DBColor(swiftUIColor: .dbGreenPale)
    static let dbAmber      = DBColor(swiftUIColor: .dbAmber)
    static let dbAmberLight = DBColor(swiftUIColor: .dbAmberLight)
    static let dbBrown      = DBColor(swiftUIColor: .dbBrown)
    static let dbCream      = DBColor(swiftUIColor: .dbCream)
    static let dbTerra      = DBColor(swiftUIColor: .dbTerra)
    static let dbSurface    = DBColor(swiftUIColor: .dbSurface)
    static let dbCard       = DBColor(swiftUIColor: .dbCard)
    static let dbBorder     = DBColor(swiftUIColor: .dbBorder)
    static let dbText       = DBColor(swiftUIColor: .dbText)
    static let dbTextSec    = DBColor(swiftUIColor: .dbTextSec)
    static let dbTextTert   = DBColor(swiftUIColor: .dbTextTert)
}

// MARK: - Adaptive Colors (light/dark)
struct AdaptiveColor {
    // Legacy API — used in views that pass @Environment(\.colorScheme)
    static func surface(_ scheme: ColorScheme) -> Color {
        scheme == .dark ? .dbDarkSurface : .dbSurface
    }
    static func card(_ scheme: ColorScheme) -> Color {
        scheme == .dark ? .dbDarkCard : .dbCard
    }
    static func border(_ scheme: ColorScheme) -> Color {
        scheme == .dark ? .dbDarkBorder : .dbBorder
    }
    static func text(_ scheme: ColorScheme) -> Color {
        scheme == .dark ? Color.white : .dbText
    }
    static func textSecondary(_ scheme: ColorScheme) -> Color {
        scheme == .dark ? Color(hex: "#9EA39A") : .dbTextSec
    }
    static func background(_ scheme: ColorScheme) -> Color {
        scheme == .dark ? .dbDarkBg : .dbCream
    }

    // Modern API — auto-adapts via UIColor dynamic provider
    static var background: DBColor {
        DBColor(swiftUIColor: Color(UIColor { t in
            t.userInterfaceStyle == .dark
                ? UIColor(red: 0.071, green: 0.078, blue: 0.063, alpha: 1) // dbDarkBg #121410
                : UIColor(red: 0.992, green: 0.965, blue: 0.925, alpha: 1) // dbCream  #FDF6EC
        }))
    }
    static var card: DBColor {
        DBColor(swiftUIColor: Color(UIColor { t in
            t.userInterfaceStyle == .dark
                ? UIColor(red: 0.145, green: 0.157, blue: 0.125, alpha: 1) // dbDarkCard #252820
                : UIColor(red: 1, green: 1, blue: 1, alpha: 1)             // dbCard     #FFFFFF
        }))
    }
    static var surface: DBColor {
        DBColor(swiftUIColor: Color(UIColor { t in
            t.userInterfaceStyle == .dark
                ? UIColor(red: 0.110, green: 0.118, blue: 0.098, alpha: 1) // dbDarkSurface #1C1E19
                : UIColor(red: 0.980, green: 0.980, blue: 0.969, alpha: 1) // dbSurface    #FAFAF7
        }))
    }
    static var border: DBColor {
        DBColor(swiftUIColor: Color(UIColor { t in
            t.userInterfaceStyle == .dark
                ? UIColor(red: 0.180, green: 0.188, blue: 0.157, alpha: 1) // dbDarkBorder #2E3028
                : UIColor(red: 0.910, green: 0.894, blue: 0.863, alpha: 1) // dbBorder     #E8E4DC
        }))
    }
    static var primaryText: DBColor {
        DBColor(swiftUIColor: Color(UIColor { t in
            t.userInterfaceStyle == .dark
                ? UIColor(red: 1, green: 1, blue: 1, alpha: 1)             // white
                : UIColor(red: 0.110, green: 0.110, blue: 0.102, alpha: 1) // dbText #1C1C1A
        }))
    }
    static var secondaryText: DBColor {
        DBColor(swiftUIColor: Color(UIColor { t in
            t.userInterfaceStyle == .dark
                ? UIColor(red: 0.620, green: 0.639, blue: 0.604, alpha: 1) // #9EA39A
                : UIColor(red: 0.420, green: 0.408, blue: 0.376, alpha: 1) // dbTextSec #6B6860
        }))
    }
}
