import SwiftUI
import UserNotifications

// MARK: - Settings View
struct SettingsView: View {
    @EnvironmentObject var appState: AppState
    @AppStorage("colorScheme") private var colorSchemeRaw: String = "system"
    @AppStorage("weightUnit") private var weightUnit: String = "kg"
    @AppStorage("notificationsEnabled") private var notificationsEnabled: Bool = false
    @AppStorage("dailyReminderHour") private var dailyReminderHour: Int = 8
    @AppStorage("dailyReminderMinute") private var dailyReminderMinute: Int = 0
    @AppStorage("hasCompletedOnboarding") private var hasCompletedOnboarding: Bool = true

    @State private var showLogOutAlert = false
    @State private var showDeleteAlert = false
    @State private var showDeleteConfirmField = false
    @State private var deleteConfirmText = ""
    @State private var showNotificationPermissionAlert = false
    @State private var reminderTime = Date()
    @State private var notificationStatus: UNAuthorizationStatus = .notDetermined
    @State private var showSavedToast = false

    var body: some View {
        NavigationView {
            ZStack {
                AdaptiveColor.background.swiftUIColor.ignoresSafeArea()

                ScrollView {
                    VStack(spacing: 20) {
                        // Demo mode banner
                        if appState.isDemoAccount {
                            demoBanner
                        }

                        // Profile card shortcut
                        profileCard

                        // Appearance
                        appearanceSection

                        // Units
                        unitsSection

                        // Notifications
                        notificationsSection

                        // Account
                        accountSection

                        // App info
                        appInfoSection

                        Spacer(minLength: 40)
                    }
                    .padding(.horizontal, 16)
                    .padding(.top, 12)
                }

                // Toast
                if showSavedToast {
                    VStack {
                        Spacer()
                        HStack(spacing: 8) {
                            Image(systemName: "checkmark.circle.fill")
                                .foregroundColor(.white)
                            Text("Settings saved")
                                .foregroundColor(.white)
                                .font(DBFont.subheadline())
                        }
                        .padding(.horizontal, 20)
                        .padding(.vertical, 12)
                        .background(DBColors.dbGreen.swiftUIColor)
                        .cornerRadius(24)
                        .shadow(radius: 8)
                        .padding(.bottom, 32)
                        .transition(.move(edge: .bottom).combined(with: .opacity))
                    }
                }
            }
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .principal) {
                    Text("Settings")
                        .font(DBFont.headline())
                        .foregroundColor(AdaptiveColor.primaryText.swiftUIColor)
                }
            }
        }
        .onAppear { loadNotificationStatus() }
        .alert("Log Out", isPresented: $showLogOutAlert) {
            Button("Log Out", role: .destructive) { appState.logOut() }
            Button("Cancel", role: .cancel) {}
        } message: {
            Text("Are you sure you want to log out?")
        }
        .alert("Delete Account", isPresented: $showDeleteAlert) {
            Button("Delete", role: .destructive) { performDeleteAccount() }
            Button("Cancel", role: .cancel) { deleteConfirmText = "" }
        } message: {
            Text("This will permanently delete your account and all farm data. Type DELETE to confirm.")
        }
        .alert("Notifications Disabled", isPresented: $showNotificationPermissionAlert) {
            Button("Open Settings") {
                if let url = URL(string: UIApplication.openSettingsURLString) {
                    UIApplication.shared.open(url)
                }
            }
            Button("Cancel", role: .cancel) {}
        } message: {
            Text("Please enable notifications in iOS Settings to use this feature.")
        }
    }

    // MARK: - Demo Banner
    private var demoBanner: some View {
        HStack(spacing: 12) {
            Image(systemName: "eye.fill")
                .foregroundColor(Color(hex: "#E8A020"))
                .font(.system(size: 18))
            VStack(alignment: .leading, spacing: 2) {
                Text("Demo Mode")
                    .font(DBFont.headline(14))
                    .foregroundColor(Color(hex: "#E8A020"))
                Text("Data is temporary and won't be saved")
                    .font(DBFont.caption())
                    .foregroundColor(AdaptiveColor.secondaryText.swiftUIColor)
            }
            Spacer()
        }
        .padding(14)
        .background(Color(hex: "#E8A020").opacity(0.1))
        .cornerRadius(14)
        .overlay(RoundedRectangle(cornerRadius: 14)
            .stroke(Color(hex: "#E8A020").opacity(0.3), lineWidth: 1))
    }

    // MARK: - Profile Card
    private var profileCard: some View {
        NavigationLink(destination: ProfileView().environmentObject(appState)) {
            HStack(spacing: 14) {
                ZStack {
                    Circle()
                        .fill(LinearGradient(
                            colors: [DBColors.dbGreen.swiftUIColor, DBColors.dbAmber.swiftUIColor],
                            startPoint: .topLeading, endPoint: .bottomTrailing))
                        .frame(width: 52, height: 52)
                    Text(appState.currentUser?.name.prefix(1).uppercased() ?? "?")
                        .font(DBFont.title2())
                        .foregroundColor(.white)
                }
                VStack(alignment: .leading, spacing: 2) {
                    Text(appState.currentUser?.name ?? "Farmer")
                        .font(DBFont.headline())
                        .foregroundColor(AdaptiveColor.primaryText.swiftUIColor)
                    Text(appState.currentUser?.farmName ?? "My Farm")
                        .font(DBFont.caption())
                        .foregroundColor(AdaptiveColor.secondaryText.swiftUIColor)
                }
                Spacer()
                Image(systemName: "chevron.right")
                    .foregroundColor(AdaptiveColor.secondaryText.swiftUIColor)
                    .font(.system(size: 14, weight: .semibold))
            }
            .padding(16)
            .background(AdaptiveColor.card.swiftUIColor)
            .cornerRadius(16)
            .shadow(color: Color.black.opacity(0.06), radius: 8, x: 0, y: 2)
        }
    }

    // MARK: - Appearance
    private var appearanceSection: some View {
        SettingsSection(title: "Appearance", icon: "paintbrush.fill", iconColor: DBColors.dbAmber.swiftUIColor) {
            VStack(spacing: 0) {
                Text("Theme")
                    .font(DBFont.subheadline())
                    .foregroundColor(AdaptiveColor.secondaryText.swiftUIColor)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .padding(.bottom, 10)

                HStack(spacing: 10) {
                    ForEach(["system", "light", "dark"], id: \.self) { scheme in
                        ThemeOptionButton(
                            label: scheme.capitalized,
                            icon: schemeIcon(scheme),
                            isSelected: colorSchemeRaw == scheme
                        ) {
                            withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
                                colorSchemeRaw = scheme
                                appState.applyColorScheme(scheme)
                            }
                            showToast()
                        }
                    }
                }
            }
            .padding(16)
        }
    }

    private func schemeIcon(_ scheme: String) -> String {
        switch scheme {
        case "light": return "sun.max.fill"
        case "dark": return "moon.fill"
        default: return "circle.lefthalf.filled"
        }
    }

    // MARK: - Units
    private var unitsSection: some View {
        SettingsSection(title: "Measurements", icon: "ruler.fill", iconColor: DBColors.dbBrown.swiftUIColor) {
            VStack(spacing: 0) {
                Text("Weight Unit")
                    .font(DBFont.subheadline())
                    .foregroundColor(AdaptiveColor.secondaryText.swiftUIColor)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .padding(.bottom, 10)

                HStack(spacing: 10) {
                    ForEach(["kg", "lbs", "g"], id: \.self) { unit in
                        UnitOptionButton(label: unit, isSelected: weightUnit == unit) {
                            withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
                                weightUnit = unit
                                appState.weightUnit = unit
                            }
                            showToast()
                        }
                    }
                    Spacer()
                }
            }
            .padding(16)
        }
    }

    // MARK: - Notifications
    private var notificationsSection: some View {
        SettingsSection(title: "Notifications", icon: "bell.fill", iconColor: DBColors.dbTerra.swiftUIColor) {
            VStack(spacing: 0) {
                // Master toggle
                HStack {
                    VStack(alignment: .leading, spacing: 2) {
                        Text("Daily Reminder")
                            .font(DBFont.subheadline())
                            .foregroundColor(AdaptiveColor.primaryText.swiftUIColor)
                        Text("Remind to log eggs & feeding")
                            .font(DBFont.caption())
                            .foregroundColor(AdaptiveColor.secondaryText.swiftUIColor)
                    }
                    Spacer()
                    Toggle("", isOn: Binding(
                        get: { notificationsEnabled },
                        set: { newValue in handleNotificationToggle(newValue) }
                    ))
                    .labelsHidden()
                    .tint(DBColors.dbGreen.swiftUIColor)
                }
                .padding(16)

                if notificationsEnabled {
                    Divider().padding(.horizontal, 16)

                    // Time picker
                    HStack {
                        Text("Reminder Time")
                            .font(DBFont.subheadline())
                            .foregroundColor(AdaptiveColor.primaryText.swiftUIColor)
                        Spacer()
                        DatePicker("", selection: $reminderTime, displayedComponents: .hourAndMinute)
                            .labelsHidden()
                            .onChange(of: reminderTime) { newTime in
                                let cal = Calendar.current
                                dailyReminderHour = cal.component(.hour, from: newTime)
                                dailyReminderMinute = cal.component(.minute, from: newTime)
                                scheduleNotification(hour: dailyReminderHour, minute: dailyReminderMinute)
                                showToast()
                            }
                    }
                    .padding(16)
                    .transition(.opacity.combined(with: .move(edge: .top)))
                }
            }
        }
    }

    // MARK: - Account
    private var accountSection: some View {
        SettingsSection(title: "Account", icon: "person.crop.circle.fill", iconColor: DBColors.dbGreen.swiftUIColor) {
            VStack(spacing: 0) {
                // Log Out
                Button {
                    showLogOutAlert = true
                } label: {
                    HStack {
                        Image(systemName: "rectangle.portrait.and.arrow.right")
                            .foregroundColor(DBColors.dbAmber.swiftUIColor)
                            .frame(width: 24)
                        Text("Log Out")
                            .font(DBFont.subheadline())
                            .foregroundColor(AdaptiveColor.primaryText.swiftUIColor)
                        Spacer()
                        Image(systemName: "chevron.right")
                            .font(.system(size: 12, weight: .semibold))
                            .foregroundColor(AdaptiveColor.secondaryText.swiftUIColor)
                    }
                    .padding(16)
                }

                Divider().padding(.horizontal, 16)

                // Delete Account
                Button {
                    showDeleteAlert = true
                } label: {
                    HStack {
                        Image(systemName: "trash.fill")
                            .foregroundColor(.red)
                            .frame(width: 24)
                        Text("Delete Account")
                            .font(DBFont.subheadline())
                            .foregroundColor(.red)
                        Spacer()
                        Image(systemName: "chevron.right")
                            .font(.system(size: 12, weight: .semibold))
                            .foregroundColor(AdaptiveColor.secondaryText.swiftUIColor)
                    }
                    .padding(16)
                }
            }
        }
    }

    // MARK: - App Info
    private var appInfoSection: some View {
        SettingsSection(title: "About", icon: "info.circle.fill", iconColor: AdaptiveColor.secondaryText.swiftUIColor) {
            VStack(spacing: 0) {
                InfoRow(label: "Version", value: "1.0.0")
                Divider().padding(.horizontal, 16)
                InfoRow(label: "Build", value: "2026.1")
                Divider().padding(.horizontal, 16)
                InfoRow(label: "Developer", value: "Wave Studio")
            }
        }
    }

    // MARK: - Logic
    private func loadNotificationStatus() {
        // Restore reminder time from saved hour/minute
        var components = Calendar.current.dateComponents([.year, .month, .day], from: Date())
        components.hour = dailyReminderHour
        components.minute = dailyReminderMinute
        reminderTime = Calendar.current.date(from: components) ?? Date()

        UNUserNotificationCenter.current().getNotificationSettings { settings in
            DispatchQueue.main.async {
                notificationStatus = settings.authorizationStatus
                if settings.authorizationStatus == .denied {
                    notificationsEnabled = false
                }
            }
        }
    }

    private func handleNotificationToggle(_ enabled: Bool) {
        if enabled {
            UNUserNotificationCenter.current().requestAuthorization(options: [.alert, .sound, .badge]) { granted, _ in
                DispatchQueue.main.async {
                    if granted {
                        notificationsEnabled = true
                        scheduleNotification(hour: dailyReminderHour, minute: dailyReminderMinute)
                        showToast()
                    } else {
                        notificationsEnabled = false
                        showNotificationPermissionAlert = true
                    }
                }
            }
        } else {
            notificationsEnabled = false
            UNUserNotificationCenter.current().removeAllPendingNotificationRequests()
            showToast()
        }
    }

    private func scheduleNotification(hour: Int, minute: Int) {
        UNUserNotificationCenter.current().removeAllPendingNotificationRequests()
        let content = UNMutableNotificationContent()
        content.title = "🐔 Domestic Birds"
        content.body = "Don't forget to log today's egg count and feeding!"
        content.sound = .default
        var dateComponents = DateComponents()
        dateComponents.hour = hour
        dateComponents.minute = minute
        let trigger = UNCalendarNotificationTrigger(dateMatching: dateComponents, repeats: true)
        let request = UNNotificationRequest(identifier: "db_daily_reminder", content: content, trigger: trigger)
        UNUserNotificationCenter.current().add(request)
    }

    private func performDeleteAccount() {
        UNUserNotificationCenter.current().removeAllPendingNotificationRequests()
        appState.deleteAccount()
    }

    private func showToast() {
        withAnimation(.spring(response: 0.4, dampingFraction: 0.7)) {
            showSavedToast = true
        }
        DispatchQueue.main.asyncAfter(deadline: .now() + 2) {
            withAnimation { showSavedToast = false }
        }
    }
}

// MARK: - Supporting Components
struct SettingsSection<Content: View>: View {
    let title: String
    let icon: String
    let iconColor: Color
    let content: Content

    init(title: String, icon: String, iconColor: Color, @ViewBuilder content: () -> Content) {
        self.title = title
        self.icon = icon
        self.iconColor = iconColor
        self.content = content()
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack(spacing: 6) {
                Image(systemName: icon)
                    .foregroundColor(iconColor)
                    .font(.system(size: 13, weight: .semibold))
                Text(title.uppercased())
                    .font(DBFont.caption().weight(.semibold))
                    .foregroundColor(AdaptiveColor.secondaryText.swiftUIColor)
                    .kerning(0.8)
            }
            .padding(.horizontal, 4)

            VStack(spacing: 0) {
                content
            }
            .background(AdaptiveColor.card.swiftUIColor)
            .cornerRadius(16)
            .shadow(color: Color.black.opacity(0.05), radius: 8, x: 0, y: 2)
        }
    }
}

struct ThemeOptionButton: View {
    let label: String
    let icon: String
    let isSelected: Bool
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            VStack(spacing: 6) {
                ZStack {
                    Circle()
                        .fill(isSelected ? DBColors.dbGreen.swiftUIColor : AdaptiveColor.background.swiftUIColor)
                        .frame(width: 44, height: 44)
                        .shadow(color: isSelected ? DBColors.dbGreen.swiftUIColor.opacity(0.3) : Color.clear, radius: 6)
                    Image(systemName: icon)
                        .foregroundColor(isSelected ? .white : AdaptiveColor.secondaryText.swiftUIColor)
                        .font(.system(size: 18))
                }
                Text(label)
                    .font(DBFont.caption())
                    .foregroundColor(isSelected ? DBColors.dbGreen.swiftUIColor : AdaptiveColor.secondaryText.swiftUIColor)
                    .fontWeight(isSelected ? .semibold : .regular)
            }
            .frame(maxWidth: .infinity)
        }
        .scaleEffect(isSelected ? 1.05 : 1.0)
        .animation(.spring(response: 0.3, dampingFraction: 0.7), value: isSelected)
    }
}

struct UnitOptionButton: View {
    let label: String
    let isSelected: Bool
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            Text(label)
                .font(DBFont.subheadline())
                .fontWeight(isSelected ? .semibold : .regular)
                .foregroundColor(isSelected ? .white : AdaptiveColor.primaryText.swiftUIColor)
                .padding(.horizontal, 20)
                .padding(.vertical, 10)
                .background(isSelected ? DBColors.dbAmber.swiftUIColor : AdaptiveColor.background.swiftUIColor)
                .cornerRadius(10)
                .shadow(color: isSelected ? DBColors.dbAmber.swiftUIColor.opacity(0.3) : Color.clear, radius: 6)
        }
        .scaleEffect(isSelected ? 1.05 : 1.0)
        .animation(.spring(response: 0.3, dampingFraction: 0.7), value: isSelected)
    }
}

struct InfoRow: View {
    let label: String
    let value: String
    let icon: String?
    
    init(label: String, value: String, icon: String? = nil) {
        self.label = label
        self.value = value
        self.icon = icon
    }

    var body: some View {
        HStack {
            if let icon = icon {
                Image(icon)
                    .resizable()
                    .frame(width: 24, height: 24)
            }
            Text(label)
                .font(DBFont.subheadline())
                .foregroundColor(AdaptiveColor.primaryText.swiftUIColor)
            Spacer()
            Text(value)
                .font(DBFont.subheadline())
                .foregroundColor(AdaptiveColor.secondaryText.swiftUIColor)
        }
        .padding(16)
    }
}
