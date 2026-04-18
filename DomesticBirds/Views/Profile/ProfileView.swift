import SwiftUI

struct ProfileView: View {
    @EnvironmentObject var appState: AppState
    @Environment(\.presentationMode) var presentationMode

    @State private var name: String = ""
    @State private var farmName: String = ""
    @State private var email: String = ""
    @State private var showSaved = false
    @State private var nameError: String? = nil
    @State private var farmError: String? = nil
    @State private var hasChanges = false

    var body: some View {
        ZStack {
            AdaptiveColor.background.swiftUIColor.ignoresSafeArea()

            ScrollView {
                VStack(spacing: 24) {
                    // Avatar
                    avatarSection

                    // Form
                    formSection

                    // Stats summary
                    statsSection

                    Spacer(minLength: 40)
                }
                .padding(.horizontal, 16)
                .padding(.top, 16)
            }

            // Saved toast
            if showSaved {
                VStack {
                    Spacer()
                    HStack(spacing: 8) {
                        Image(systemName: "checkmark.circle.fill").foregroundColor(.white)
                        Text("Profile updated").foregroundColor(.white).font(DBFont.subheadline())
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
        .navigationTitle("Profile")
        .navigationBarTitleDisplayMode(.inline)
        .navigationBarBackButtonHidden(true)
        .toolbar {
            ToolbarItem(placement: .navigationBarLeading) {
                Button {
                    presentationMode.wrappedValue.dismiss()
                } label: {
                    Image(systemName: "chevron.left")
                        .foregroundColor(DBColors.dbGreen.swiftUIColor)
                        .font(.system(size: 16, weight: .semibold))
                }
            }
            ToolbarItem(placement: .navigationBarTrailing) {
                if hasChanges {
                    Button("Save") { saveProfile() }
                        .font(DBFont.subheadline().weight(.semibold))
                        .foregroundColor(DBColors.dbGreen.swiftUIColor)
                        .transition(.opacity)
                }
            }
        }
        .onAppear { loadProfile() }
    }

    // MARK: - Avatar
    private var avatarSection: some View {
        VStack(spacing: 12) {
            ZStack {
                Circle()
                    .fill(LinearGradient(
                        colors: [DBColors.dbGreen.swiftUIColor, DBColors.dbAmber.swiftUIColor],
                        startPoint: .topLeading, endPoint: .bottomTrailing))
                    .frame(width: 90, height: 90)
                    .shadow(color: DBColors.dbGreen.swiftUIColor.opacity(0.3), radius: 16)

                Text(name.prefix(1).uppercased())
                    .font(.system(size: 38, weight: .bold, design: .rounded))
                    .foregroundColor(.white)
            }
            .scaleEffect(1.0)
            .animation(.spring(response: 0.4, dampingFraction: 0.7), value: name)

            Text("Member since \(memberSince)")
                .font(DBFont.caption())
                .foregroundColor(AdaptiveColor.secondaryText.swiftUIColor)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 8)
    }

    private var memberSince: String {
        guard let user = appState.currentUser else { return "—" }
        let fmt = DateFormatter()
        fmt.dateFormat = "MMM yyyy"
        return fmt.string(from: user.createdAt)
    }

    // MARK: - Form
    private var formSection: some View {
        VStack(spacing: 0) {
            // Section header
            HStack {
                Text("PERSONAL INFO")
                    .font(DBFont.caption().weight(.semibold))
                    .foregroundColor(AdaptiveColor.secondaryText.swiftUIColor)
                    .kerning(0.8)
                Spacer()
            }
            .padding(.bottom, 8)
            .padding(.horizontal, 4)

            VStack(spacing: 0) {
                // Name
                ProfileField(
                    icon: "person.fill",
                    iconColor: DBColors.dbGreen.swiftUIColor,
                    label: "Full Name",
                    placeholder: "Your name",
                    text: $name,
                    error: nameError
                ) {
                    validate()
                    hasChanges = true
                }

                Divider().padding(.horizontal, 16)

                // Farm Name
                ProfileField(
                    icon: "house.fill",
                    iconColor: DBColors.dbBrown.swiftUIColor,
                    label: "Farm Name",
                    placeholder: "Your farm name",
                    text: $farmName,
                    error: farmError
                ) {
                    validate()
                    hasChanges = true
                }

                Divider().padding(.horizontal, 16)

                // Email (read-only)
                HStack(spacing: 12) {
                    ZStack {
                        RoundedRectangle(cornerRadius: 8)
                            .fill(DBColors.dbAmber.swiftUIColor.opacity(0.12))
                            .frame(width: 32, height: 32)
                        Image(systemName: "envelope.fill")
                            .foregroundColor(DBColors.dbAmber.swiftUIColor)
                            .font(.system(size: 14))
                    }
                    VStack(alignment: .leading, spacing: 2) {
                        Text("Email")
                            .font(DBFont.caption())
                            .foregroundColor(AdaptiveColor.secondaryText.swiftUIColor)
                        Text(email.isEmpty ? "—" : email)
                            .font(DBFont.subheadline())
                            .foregroundColor(AdaptiveColor.primaryText.swiftUIColor.opacity(0.7))
                    }
                    Spacer()
                    Text("Verified")
                        .font(DBFont.caption())
                        .foregroundColor(DBColors.dbGreen.swiftUIColor)
                        .padding(.horizontal, 8)
                        .padding(.vertical, 3)
                        .background(DBColors.dbGreen.swiftUIColor.opacity(0.12))
                        .cornerRadius(6)
                }
                .padding(16)
            }
            .background(AdaptiveColor.card.swiftUIColor)
            .cornerRadius(16)
            .shadow(color: Color.black.opacity(0.05), radius: 8, x: 0, y: 2)
        }
    }

    // MARK: - Stats
    private var statsSection: some View {
        VStack(spacing: 8) {
            HStack {
                Text("FARM OVERVIEW")
                    .font(DBFont.caption().weight(.semibold))
                    .foregroundColor(AdaptiveColor.secondaryText.swiftUIColor)
                    .kerning(0.8)
                Spacer()
            }
            .padding(.horizontal, 4)

            HStack(spacing: 12) {
                ProfileStatCard(value: "\(appState.myBirds.count)", label: "Birds", icon: "bird.fill", color: DBColors.dbGreen.swiftUIColor)
                ProfileStatCard(value: "\(appState.groups.count)", label: "Groups", icon: "square.grid.2x2.fill", color: DBColors.dbAmber.swiftUIColor)
                ProfileStatCard(value: "\(appState.coops.count)", label: "Coops", icon: "house.fill", color: DBColors.dbBrown.swiftUIColor)
            }

            HStack(spacing: 12) {
                let totalEggs = appState.eggRecords.map(\.count).reduce(0, +)
                ProfileStatCard(value: "\(totalEggs)", label: "Total Eggs", icon: "oval.fill", color: DBColors.dbTerra.swiftUIColor)
                ProfileStatCard(value: "\(appState.breedingPairs.count)", label: "Pairs", icon: "heart.fill", color: .pink)
                ProfileStatCard(value: "\(appState.healthRecords.filter { !$0.isResolved }.count)", label: "Active Issues", icon: "cross.fill", color: .red)
            }
        }
    }

    // MARK: - Logic
    private func loadProfile() {
        guard let user = appState.currentUser else { return }
        name = user.name
        farmName = user.farmName
        email = user.email
    }

    private func validate() {
        nameError = name.trimmingCharacters(in: .whitespaces).isEmpty ? "Name cannot be empty" : nil
        farmError = farmName.trimmingCharacters(in: .whitespaces).isEmpty ? "Farm name cannot be empty" : nil
    }

    private func saveProfile() {
        validate()
        guard nameError == nil, farmError == nil else { return }
        appState.updateProfile(name: name.trimmingCharacters(in: .whitespaces),
                               farmName: farmName.trimmingCharacters(in: .whitespaces))
        hasChanges = false
        withAnimation(.spring(response: 0.4, dampingFraction: 0.7)) { showSaved = true }
        DispatchQueue.main.asyncAfter(deadline: .now() + 2) {
            withAnimation { showSaved = false }
        }
        UIApplication.shared.sendAction(#selector(UIResponder.resignFirstResponder), to: nil, from: nil, for: nil)
    }
}

// MARK: - ProfileField
struct ProfileField: View {
    let icon: String
    let iconColor: Color
    let label: String
    let placeholder: String
    @Binding var text: String
    let error: String?
    let onChange: () -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            HStack(spacing: 12) {
                ZStack {
                    RoundedRectangle(cornerRadius: 8)
                        .fill(iconColor.opacity(0.12))
                        .frame(width: 32, height: 32)
                    Image(systemName: icon)
                        .foregroundColor(iconColor)
                        .font(.system(size: 14))
                }
                VStack(alignment: .leading, spacing: 2) {
                    Text(label)
                        .font(DBFont.caption())
                        .foregroundColor(AdaptiveColor.secondaryText.swiftUIColor)
                    TextField(placeholder, text: $text)
                        .font(DBFont.subheadline())
                        .foregroundColor(AdaptiveColor.primaryText.swiftUIColor)
                        .onChange(of: text) { _ in onChange() }
                }
            }
            .padding(16)

            if let err = error {
                Text(err)
                    .font(DBFont.caption())
                    .foregroundColor(.red)
                    .padding(.horizontal, 16)
                    .padding(.bottom, 8)
                    .transition(.opacity)
            }
        }
    }
}

// MARK: - ProfileStatCard
struct ProfileStatCard: View {
    let value: String
    let label: String
    let icon: String
    let color: Color

    var body: some View {
        VStack(spacing: 6) {
            Image(systemName: icon)
                .foregroundColor(color)
                .font(.system(size: 18))
            Text(value)
                .font(DBFont.title3())
                .foregroundColor(AdaptiveColor.primaryText.swiftUIColor)
            Text(label)
                .font(DBFont.caption())
                .foregroundColor(AdaptiveColor.secondaryText.swiftUIColor)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 14)
        .background(AdaptiveColor.card.swiftUIColor)
        .cornerRadius(14)
        .shadow(color: Color.black.opacity(0.05), radius: 6, x: 0, y: 2)
    }
}
