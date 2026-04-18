import SwiftUI

// MARK: - Welcome Screen
struct WelcomeView: View {
    @EnvironmentObject var appState: AppState
    @State private var showSignUp = false
    @State private var showLogIn = false
    @State private var appeared = false
    @State private var demoTapped = false

    var body: some View {
        ZStack {
            LinearGradient(
                colors: [Color(hex: "#1A3A20"), Color(hex: "#2D5A35"), Color(hex: "#4A8A55")],
                startPoint: .top, endPoint: .bottom
            )
            .ignoresSafeArea()

            // Decorative blobs
            GeometryReader { geo in
                Circle()
                    .fill(Color(hex: "#E8A020").opacity(0.12))
                    .frame(width: 200, height: 200)
                    .offset(x: geo.size.width - 60, y: 60)
                    .blur(radius: 30)

                Circle()
                    .fill(Color.white.opacity(0.05))
                    .frame(width: 300, height: 300)
                    .offset(x: -80, y: geo.size.height - 200)
                    .blur(radius: 40)
            }
            .ignoresSafeArea()

            VStack(spacing: 0) {
                Spacer()

                // Illustration area
                VStack(spacing: 16) {
                    ZStack {
                        Circle()
                            .fill(Color.white.opacity(0.08))
                            .frame(width: 140, height: 140)
                        Circle()
                            .fill(LinearGradient(colors: [Color(hex: "#E8A020"), Color(hex: "#F5C842")],
                                                 startPoint: .topLeading, endPoint: .bottomTrailing))
                            .frame(width: 108, height: 108)
                            .shadow(color: Color(hex: "#E8A020").opacity(0.4), radius: 20)
                        VStack(spacing: -4) {
                            Image(systemName: "bird.fill")
                                .font(.system(size: 36, weight: .bold))
                                .foregroundColor(.white)
                            Image(systemName: "leaf.fill")
                                .font(.system(size: 14, weight: .bold))
                                .foregroundColor(.white.opacity(0.7))
                                .rotationEffect(.degrees(-30))
                                .offset(x: 16, y: -4)
                        }
                    }
                    .scaleEffect(appeared ? 1.0 : 0.7)
                    .opacity(appeared ? 1.0 : 0)
                }

                Spacer().frame(height: 40)

                // Text
                VStack(spacing: 12) {
                    Text("Domestic Birds")
                        .font(.system(size: 36, weight: .bold, design: .rounded))
                        .foregroundColor(.white)

                    Text("Your complete poultry management\nand breed identification app")
                        .font(.system(size: 16, weight: .regular, design: .rounded))
                        .foregroundColor(.white.opacity(0.7))
                        .multilineTextAlignment(.center)
                }
                .opacity(appeared ? 1.0 : 0)
                .offset(y: appeared ? 0 : 20)

                Spacer()

                // Feature pills
                HStack(spacing: 12) {
                    ForEach(["🐔 Identify", "📊 Track", "🥚 Eggs"], id: \.self) { tag in
                        Text(tag)
                            .font(.system(size: 13, weight: .semibold, design: .rounded))
                            .foregroundColor(.white.opacity(0.9))
                            .padding(.horizontal, 14)
                            .padding(.vertical, 8)
                            .background(Color.white.opacity(0.12))
                            .cornerRadius(20)
                    }
                }
                .opacity(appeared ? 1.0 : 0)

                Spacer().frame(height: 40)

                // Buttons
                VStack(spacing: 14) {
                    Button(action: { showSignUp = true }) {
                        Text("Create Account")
                            .font(DBFont.headline(17))
                            .foregroundColor(Color(hex: "#1A3A20"))
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 16)
                            .background(Color.white)
                            .cornerRadius(16)
                            .shadow(color: Color.black.opacity(0.15), radius: 8, x: 0, y: 4)
                    }

                    Button(action: { showLogIn = true }) {
                        Text("Log In")
                            .font(DBFont.headline(17))
                            .foregroundColor(.white)
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 16)
                            .background(Color.white.opacity(0.15))
                            .cornerRadius(16)
                            .overlay(RoundedRectangle(cornerRadius: 16).stroke(Color.white.opacity(0.3), lineWidth: 1))
                    }

                    Button(action: {
                        withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) { demoTapped = true }
                        DispatchQueue.main.asyncAfter(deadline: .now() + 0.25) {
                            appState.loginAsDemo()
                        }
                    }) {
                        HStack(spacing: 8) {
                            Image(systemName: "eye.fill")
                                .font(.system(size: 14, weight: .semibold))
                            Text(demoTapped ? "Loading..." : "Try Demo")
                                .font(DBFont.headline(16))
                        }
                        .foregroundColor(Color(hex: "#E8A020"))
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 14)
                        .background(Color(hex: "#E8A020").opacity(0.15))
                        .cornerRadius(16)
                        .overlay(RoundedRectangle(cornerRadius: 16).stroke(Color(hex: "#E8A020").opacity(0.4), lineWidth: 1))
                    }
                    .disabled(demoTapped)
                }
                .padding(.horizontal, 28)
                .opacity(appeared ? 1.0 : 0)
                .offset(y: appeared ? 0 : 30)

                Spacer().frame(height: 48)
            }
        }
        .sheet(isPresented: $showSignUp) { SignUpView() }
        .sheet(isPresented: $showLogIn) { LogInView() }
        .onAppear {
            withAnimation(.spring(response: 0.7, dampingFraction: 0.7).delay(0.1)) {
                appeared = true
            }
        }
    }
}

// MARK: - Sign Up View
struct SignUpView: View {
    @EnvironmentObject var appState: AppState
    @Environment(\.presentationMode) var dismiss

    @State private var name = ""
    @State private var email = ""
    @State private var password = ""
    @State private var farmName = ""
    @State private var errorMessage = ""
    @State private var isLoading = false

    var body: some View {
        NavigationView {
            ScrollView {
                VStack(spacing: 28) {
                    // Header
                    VStack(spacing: 8) {
                        ZStack {
                            Circle().fill(Color.dbGreen.opacity(0.12)).frame(width: 70, height: 70)
                            Image(systemName: "person.badge.plus").font(.system(size: 28)).foregroundColor(.dbGreen)
                        }
                        Text("Create Account").font(DBFont.title()).foregroundColor(AdaptiveColor.primaryText.swiftUIColor)
                        Text("Start managing your flock today").font(DBFont.body()).foregroundColor(AdaptiveColor.secondaryText.swiftUIColor)
                    }
                    .padding(.top, 20)

                    // Fields
                    VStack(spacing: 14) {
                        DBTextField(placeholder: "Your Name", text: $name, icon: "person")
                        DBTextField(placeholder: "Farm Name (optional)", text: $farmName, icon: "house")
                        DBTextField(placeholder: "Email", text: $email, icon: "envelope", keyboardType: .emailAddress)
                        DBTextField(placeholder: "Password (min 6 chars)", text: $password, icon: "lock", isSecure: true)
                    }

                    if !errorMessage.isEmpty {
                        HStack {
                            Image(systemName: "exclamationmark.circle.fill")
                            Text(errorMessage).font(DBFont.caption())
                        }
                        .foregroundColor(Color(hex: "#E53E3E"))
                        .padding(12)
                        .background(Color(hex: "#E53E3E").opacity(0.1))
                        .cornerRadius(10)
                    }

                    DBButton("Create Account", icon: "checkmark.circle.fill") {
                        validateAndSignUp()
                    }

                    Button(action: { dismiss.wrappedValue.dismiss() }) {
                        Text("Already have an account? Log In")
                            .font(DBFont.caption())
                            .foregroundColor(.dbGreen)
                    }
                }
                .padding(24)
            }
            .background(AdaptiveColor.background.swiftUIColor.ignoresSafeArea())
            .navigationBarItems(leading: Button("Cancel") { dismiss.wrappedValue.dismiss() })
            .navigationBarTitleDisplayMode(.inline)
        }
    }

    private func validateAndSignUp() {
        errorMessage = ""
        guard !name.trimmingCharacters(in: .whitespaces).isEmpty else {
            errorMessage = "Please enter your name"; return
        }
        guard email.contains("@") && email.contains(".") else {
            errorMessage = "Please enter a valid email"; return
        }
        guard password.count >= 6 else {
            errorMessage = "Password must be at least 6 characters"; return
        }
        isLoading = true
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
            var user = AppUser(name: name, email: email)
            user.farmName = farmName
            let success = appState.signUp(name: name, email: email, password: password)
            if success {
                appState.currentUser?.farmName = farmName
                dismiss.wrappedValue.dismiss()
            } else {
                errorMessage = "Sign up failed. Please try again."
            }
            isLoading = false
        }
    }
}

// MARK: - Log In View
struct LogInView: View {
    @EnvironmentObject var appState: AppState
    @Environment(\.presentationMode) var dismiss

    @State private var email = ""
    @State private var password = ""
    @State private var errorMessage = ""

    var body: some View {
        NavigationView {
            ScrollView {
                VStack(spacing: 28) {
                    VStack(spacing: 8) {
                        ZStack {
                            Circle().fill(Color.dbGreen.opacity(0.12)).frame(width: 70, height: 70)
                            Image(systemName: "person.circle").font(.system(size: 28)).foregroundColor(.dbGreen)
                        }
                        Text("Welcome Back").font(DBFont.title()).foregroundColor(AdaptiveColor.primaryText.swiftUIColor)
                        Text("Log in to your farm account").font(DBFont.body()).foregroundColor(AdaptiveColor.secondaryText.swiftUIColor)
                    }
                    .padding(.top, 20)

                    VStack(spacing: 14) {
                        DBTextField(placeholder: "Email", text: $email, icon: "envelope", keyboardType: .emailAddress)
                        DBTextField(placeholder: "Password", text: $password, icon: "lock", isSecure: true)
                    }

                    if !errorMessage.isEmpty {
                        HStack {
                            Image(systemName: "exclamationmark.circle.fill")
                            Text(errorMessage).font(DBFont.caption())
                        }
                        .foregroundColor(Color(hex: "#E53E3E"))
                        .padding(12)
                        .background(Color(hex: "#E53E3E").opacity(0.1))
                        .cornerRadius(10)
                    }

                    DBButton("Log In", icon: "arrow.right.circle.fill") {
                        guard !email.isEmpty, !password.isEmpty else {
                            errorMessage = "Please fill in all fields"; return
                        }
                        let success = appState.logIn(email: email, password: password)
                        if !success { errorMessage = "Invalid credentials. Please try again." }
                        else { dismiss.wrappedValue.dismiss() }
                    }

                    // Demo account hint
                    Button(action: {
                        email = AppState.demoEmail
                        password = AppState.demoPassword
                    }) {
                        HStack(spacing: 6) {
                            Image(systemName: "eye.fill")
                                .font(.system(size: 12))
                            VStack(alignment: .leading, spacing: 1) {
                                Text("Use Demo Account")
                                    .font(DBFont.label(13))
                                Text("\(AppState.demoEmail)  ·  \(AppState.demoPassword)")
                                    .font(DBFont.label(11))
                                    .opacity(0.7)
                            }
                            Spacer()
                            Image(systemName: "arrow.up.left.square")
                                .font(.system(size: 12))
                        }
                        .foregroundColor(Color(hex: "#E8A020"))
                        .padding(12)
                        .background(Color(hex: "#E8A020").opacity(0.1))
                        .cornerRadius(12)
                        .overlay(RoundedRectangle(cornerRadius: 12)
                            .stroke(Color(hex: "#E8A020").opacity(0.3), lineWidth: 1))
                    }
                }
                .padding(24)
            }
            .background(AdaptiveColor.background.swiftUIColor.ignoresSafeArea())
            .navigationBarItems(leading: Button("Cancel") { dismiss.wrappedValue.dismiss() })
            .navigationBarTitleDisplayMode(.inline)
        }
    }
}
