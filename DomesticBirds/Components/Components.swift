import SwiftUI

// MARK: - DB Primary Button
struct DBButton: View {
    let title: String
    let icon: String?
    let style: ButtonStyle
    let action: () -> Void

    enum ButtonStyle { case primary, secondary, destructive, ghost }

    init(_ title: String, icon: String? = nil, style: ButtonStyle = .primary, action: @escaping () -> Void) {
        self.title = title
        self.icon = icon
        self.style = style
        self.action = action
    }

    @State private var pressed = false

    var body: some View {
        Button(action: {
            withAnimation(.spring(response: 0.2, dampingFraction: 0.6)) { pressed = true }
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.15) {
                withAnimation(.spring(response: 0.2, dampingFraction: 0.6)) { pressed = false }
            }
            action()
        }) {
            HStack(spacing: 8) {
                if let icon = icon {
                    Image(systemName: icon)
                        .font(.system(size: 16, weight: .semibold))
                }
                Text(title)
                    .font(DBFont.headline(16))
            }
            .foregroundColor(foregroundColor)
            .frame(maxWidth: .infinity)
            .padding(.vertical, 15)
            .padding(.horizontal, 20)
            .background(background)
            .cornerRadius(14)
            .overlay(
                RoundedRectangle(cornerRadius: 14)
                    .stroke(borderColor, lineWidth: style == .secondary ? 1.5 : 0)
            )
            .scaleEffect(pressed ? 0.97 : 1.0)
            .shadow(color: shadowColor, radius: pressed ? 2 : 6, x: 0, y: pressed ? 1 : 3)
        }
    }

    @ViewBuilder var background: some View {
        switch style {
        case .primary: LinearGradient.dbGreenGradient
        case .secondary: Color.clear
        case .destructive: Color(hex: "#E53E3E").opacity(0.12)
        case .ghost: Color.clear
        }
    }

    var foregroundColor: Color {
        switch style {
        case .primary: return .white
        case .secondary: return .dbGreen
        case .destructive: return Color(hex: "#E53E3E")
        case .ghost: return .dbTextSec
        }
    }

    var borderColor: Color {
        style == .secondary ? .dbGreen.opacity(0.4) : .clear
    }

    var shadowColor: Color {
        style == .primary ? Color.dbGreen.opacity(0.3) : .clear
    }
}

// MARK: - DB Card
struct DBCard<Content: View>: View {
    @Environment(\.colorScheme) var scheme
    let content: Content

    init(@ViewBuilder content: () -> Content) {
        self.content = content()
    }

    var body: some View {
        content
            .background(AdaptiveColor.card(scheme))
            .cornerRadius(16)
            .shadow(color: Color.black.opacity(scheme == .dark ? 0.25 : 0.07), radius: 8, x: 0, y: 2)
    }
}

// MARK: - DB Text Field
struct DBTextField: View {
    let placeholder: String
    @Binding var text: String
    var icon: String? = nil
    var keyboardType: UIKeyboardType = .default
    var isSecure: Bool = false

    @Environment(\.colorScheme) var scheme
    @State private var focused = false

    var body: some View {
        HStack(spacing: 12) {
            if let icon = icon {
                Image(systemName: icon)
                    .foregroundColor(focused ? .dbGreen : .dbTextTert)
                    .font(.system(size: 17, weight: .medium))
                    .animation(.easeInOut(duration: 0.2), value: focused)
            }
            if isSecure {
                SecureField(placeholder, text: $text)
                    .font(DBFont.body())
            } else {
                TextField(placeholder, text: $text)
                    .font(DBFont.body())
                    .keyboardType(keyboardType)
            }
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 14)
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(AdaptiveColor.card(scheme))
                .shadow(color: Color.black.opacity(0.04), radius: 4, x: 0, y: 2)
        )
        .overlay(
            RoundedRectangle(cornerRadius: 12)
                .stroke(focused ? Color.dbGreen.opacity(0.6) : AdaptiveColor.border(scheme), lineWidth: 1.5)
        )
        .onTapGesture { focused = true }
    }
}

// MARK: - Stat Card
struct StatCard: View {
    let title: String
    let value: String
    let icon: String
    let color: Color
    var subtitle: String? = nil

    @Environment(\.colorScheme) var scheme
    @State private var appeared = false

    var body: some View {
        DBCard {
            VStack(alignment: .leading, spacing: 10) {
                HStack {
                    ZStack {
                        Circle()
                            .fill(color.opacity(0.15))
                            .frame(width: 40, height: 40)
                        Image(systemName: icon)
                            .font(.system(size: 18, weight: .semibold))
                            .foregroundColor(color)
                    }
                    Spacer()
                }
                Text(value)
                    .font(.system(size: 28, weight: .bold, design: .rounded))
                    .foregroundColor(AdaptiveColor.text(scheme))
                    .scaleEffect(appeared ? 1.0 : 0.8)
                    .opacity(appeared ? 1.0 : 0)

                VStack(alignment: .leading, spacing: 2) {
                    Text(title)
                        .font(DBFont.caption())
                        .foregroundColor(AdaptiveColor.textSecondary(scheme))
                    if let subtitle = subtitle {
                        Text(subtitle)
                            .font(DBFont.label(11))
                            .foregroundColor(color.opacity(0.8))
                    }
                }
            }
            .padding(16)
        }
        .onAppear {
            withAnimation(.spring(response: 0.5, dampingFraction: 0.7).delay(0.1)) {
                appeared = true
            }
        }
    }
}

// MARK: - Section Header
struct SectionHeader: View {
    let title: String
    var action: (() -> Void)? = nil
    var actionLabel: String = "See All"

    @Environment(\.colorScheme) var scheme

    var body: some View {
        HStack {
            Text(title)
                .font(DBFont.headline())
                .foregroundColor(AdaptiveColor.text(scheme))
            Spacer()
            if let action = action {
                Button(action: action) {
                    Text(actionLabel)
                        .font(DBFont.caption())
                        .foregroundColor(.dbGreen)
                }
            }
        }
    }
}

// MARK: - Tag Chip
struct TagChip: View {
    let text: String
    let color: Color

    var body: some View {
        Text(text)
            .font(DBFont.label(11))
            .foregroundColor(color)
            .padding(.horizontal, 10)
            .padding(.vertical, 5)
            .background(color.opacity(0.15))
            .cornerRadius(8)
    }
}

// MARK: - Empty State
struct EmptyStateView: View {
    let icon: String
    let title: String
    let message: String
    var action: (() -> Void)? = nil
    var actionLabel: String = "Add Now"

    @Environment(\.colorScheme) var scheme

    var body: some View {
        VStack(spacing: 20) {
            ZStack {
                Circle()
                    .fill(Color.dbGreen.opacity(0.1))
                    .frame(width: 80, height: 80)
                Text(icon)
                    .font(.system(size: 36))
            }
            VStack(spacing: 8) {
                Text(title)
                    .font(DBFont.headline())
                    .foregroundColor(AdaptiveColor.text(scheme))
                Text(message)
                    .font(DBFont.body())
                    .foregroundColor(AdaptiveColor.textSecondary(scheme))
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, 30)
            }
            if let action = action {
                DBButton(actionLabel, icon: "plus", action: action)
                    .frame(width: 160)
            }
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 40)
    }
}

// MARK: - Health Badge
struct HealthBadge: View {
    let status: BirdHealthStatus

    var body: some View {
        HStack(spacing: 4) {
            Circle()
                .fill(status.color)
                .frame(width: 7, height: 7)
            Text(status.rawValue)
                .font(DBFont.label(11))
                .foregroundColor(status.color)
        }
        .padding(.horizontal, 8)
        .padding(.vertical, 4)
        .background(status.color.opacity(0.12))
        .cornerRadius(6)
    }
}

// MARK: - Mini Chart (Sparkline)
struct SparklineChart: View {
    let values: [Int]
    let color: Color

    var body: some View {
        GeometryReader { geo in
            let maxVal = max(values.max() ?? 1, 1)
            let step = geo.size.width / CGFloat(max(values.count - 1, 1))
            Path { path in
                for (idx, val) in values.enumerated() {
                    let x = CGFloat(idx) * step
                    let y = geo.size.height - (CGFloat(val) / CGFloat(maxVal)) * geo.size.height
                    if idx == 0 {
                        path.move(to: CGPoint(x: x, y: y))
                    } else {
                        path.addLine(to: CGPoint(x: x, y: y))
                    }
                }
            }
            .stroke(color, style: StrokeStyle(lineWidth: 2, lineCap: .round, lineJoin: .round))

            // Area fill
            Path { path in
                for (idx, val) in values.enumerated() {
                    let x = CGFloat(idx) * step
                    let y = geo.size.height - (CGFloat(val) / CGFloat(maxVal)) * geo.size.height
                    if idx == 0 {
                        path.move(to: CGPoint(x: x, y: geo.size.height))
                        path.addLine(to: CGPoint(x: x, y: y))
                    } else {
                        path.addLine(to: CGPoint(x: x, y: y))
                    }
                }
                path.addLine(to: CGPoint(x: geo.size.width, y: geo.size.height))
                path.closeSubpath()
            }
            .fill(LinearGradient(colors: [color.opacity(0.3), color.opacity(0)], startPoint: .top, endPoint: .bottom))
        }
    }
}

// MARK: - Confirmation Dialog Wrapper
extension View {
    func dbConfirmDelete(isPresented: Binding<Bool>, itemName: String, action: @escaping () -> Void) -> some View {
        alert("Delete \(itemName)?", isPresented: isPresented) {
            Button("Delete", role: .destructive, action: action)
            Button("Cancel", role: .cancel) {}
        } message: {
            Text("This action cannot be undone.")
        }
    }
}
