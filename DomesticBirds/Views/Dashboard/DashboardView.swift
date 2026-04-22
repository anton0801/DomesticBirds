import SwiftUI
import WebKit

// MARK: - Main Tab View
struct MainTabView: View {
    @EnvironmentObject var appState: AppState
    @Environment(\.colorScheme) var scheme
    @State private var selectedTab = 0

    var body: some View {
        TabView(selection: $selectedTab) {
            DashboardView()
                .tabItem {
                    Image(systemName: selectedTab == 0 ? "house.fill" : "house")
                    Text("Dashboard")
                }
                .tag(0)

            CatalogNavigationView()
                .tabItem {
                    Image(systemName: selectedTab == 1 ? "books.vertical.fill" : "books.vertical")
                    Text("Catalog")
                }
                .tag(1)

            MyBirdsNavigationView()
                .tabItem {
                    Image(systemName: selectedTab == 2 ? "bird.fill" : "bird")
                    Text("My Birds")
                }
                .tag(2)

            FarmNavigationView()
                .tabItem {
                    Image(systemName: selectedTab == 3 ? "chart.bar.fill" : "chart.bar")
                    Text("Farm")
                }
                .tag(3)

            SettingsView()
                .tabItem {
                    Image(systemName: selectedTab == 4 ? "gearshape.fill" : "gearshape")
                    Text("Settings")
                }
                .tag(4)
        }
        .accentColor(.dbGreen)
    }
}

// MARK: - Dashboard
struct DashboardView: View {
    @EnvironmentObject var appState: AppState
    @Environment(\.colorScheme) var scheme
    @State private var showEggSheet = false
    @State private var greetingOpacity: Double = 0

    var greeting: String {
        let hour = Calendar.current.component(.hour, from: Date())
        if hour < 12 { return "Good morning" }
        if hour < 17 { return "Good afternoon" }
        return "Good evening"
    }

    var body: some View {
        NavigationView {
            ScrollView {
                VStack(spacing: 20) {
                    // Header card
                    ZStack(alignment: .bottomLeading) {
                        LinearGradient.dbHeroGradient
                            .frame(height: 160)
                            .cornerRadius(20)

                        // Decorative
                        GeometryReader { geo in
                            Circle()
                                .fill(Color.white.opacity(0.07))
                                .frame(width: 120, height: 120)
                                .offset(x: geo.size.width - 40, y: -30)
                            Text("🐔")
                                .font(.system(size: 60))
                                .offset(x: geo.size.width - 80, y: 20)
                                .opacity(0.6)
                        }

                        VStack(alignment: .leading, spacing: 4) {
                            Text(greeting + ",")
                                .font(DBFont.body(15))
                                .foregroundColor(.white.opacity(0.8))
                            Text(appState.currentUser?.name ?? "Farmer")
                                .font(.system(size: 24, weight: .bold, design: .rounded))
                                .foregroundColor(.white)
                            if let farm = appState.currentUser?.farmName, !farm.isEmpty {
                                HStack(spacing: 4) {
                                    Image(systemName: "house.fill")
                                        .font(.system(size: 11))
                                    Text(farm)
                                        .font(DBFont.label(12))
                                }
                                .foregroundColor(.white.opacity(0.7))
                            }
                        }
                        .padding(20)
                    }
                    .opacity(greetingOpacity)

                    // Stats grid
                    LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 14) {
                        StatCard(
                            title: "Total Birds",
                            value: "\(appState.activeBirdCount)",
                            icon: "bird.fill",
                            color: .dbGreen,
                            subtitle: "\(appState.groups.count) groups"
                        )
                        StatCard(
                            title: "Eggs Today",
                            value: "\(appState.totalEggsToday)",
                            icon: "circle.fill",
                            color: Color(hex: "#E8A020"),
                            subtitle: "\(appState.totalEggsThisWeek) this week"
                        )
                        StatCard(
                            title: "Breeding Pairs",
                            value: "\(appState.activeBreedingPairs)",
                            icon: "heart.fill",
                            color: Color(hex: "#805AD5"),
                            subtitle: "\(appState.breedingPairs.count) total"
                        )
                        StatCard(
                            title: "Feed This Week",
                            value: String(format: "%.1f", appState.feedUsageThisWeek) + " \(appState.weightUnit)",
                            icon: "bag.fill",
                            color: Color(hex: "#7B4F2E"),
                            subtitle: "Last 7 days"
                        )
                    }

                    // Egg production chart
                    if !appState.eggRecords.isEmpty {
                        DBCard {
                            VStack(alignment: .leading, spacing: 12) {
                                SectionHeader(title: "Egg Production (7 days)")
                                SparklineChart(values: appState.eggsForLast7Days(), color: .dbAmber)
                                    .frame(height: 60)
                                HStack {
                                    Text("Total: \(appState.totalEggsThisWeek) eggs")
                                        .font(DBFont.caption())
                                        .foregroundColor(AdaptiveColor.textSecondary(scheme))
                                    Spacer()
                                    Text("Avg: \(appState.totalEggsThisWeek / 7)/day")
                                        .font(DBFont.label())
                                        .foregroundColor(.dbGreen)
                                }
                            }
                            .padding(16)
                        }
                    }

                    // Quick actions
                    DBCard {
                        VStack(alignment: .leading, spacing: 14) {
                            SectionHeader(title: "Quick Actions")
                            LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible()), GridItem(.flexible())], spacing: 10) {
                                QuickActionButton(icon: "circle.fill", label: "Add Eggs", color: Color(hex: "#E8A020")) {
                                    showEggSheet = true
                                }
                                NavigationLink(destination: AddBirdView()) {
                                    QuickActionCell(icon: "bird.fill", label: "Add Bird", color: .dbGreen)
                                }
                                NavigationLink(destination: BreedIDView()) {
                                    QuickActionCell(icon: "camera.viewfinder", label: "Identify", color: Color(hex: "#805AD5"))
                                }
                            }
                        }
                        .padding(16)
                    }

                    // Health alerts
                    if appState.activeHealthIssues > 0 {
                        DBCard {
                            HStack(spacing: 14) {
                                ZStack {
                                    Circle().fill(Color(hex: "#E53E3E").opacity(0.12)).frame(width: 44, height: 44)
                                    Image(systemName: "cross.circle.fill")
                                        .foregroundColor(Color(hex: "#E53E3E"))
                                        .font(.system(size: 20))
                                }
                                VStack(alignment: .leading, spacing: 2) {
                                    Text("\(appState.activeHealthIssues) Active Health Issue\(appState.activeHealthIssues > 1 ? "s" : "")")
                                        .font(DBFont.headline(15))
                                        .foregroundColor(AdaptiveColor.text(scheme))
                                    Text("Tap to view health records")
                                        .font(DBFont.caption())
                                        .foregroundColor(AdaptiveColor.textSecondary(scheme))
                                }
                                Spacer()
                                Image(systemName: "chevron.right")
                                    .foregroundColor(AdaptiveColor.textSecondary(scheme))
                            }
                            .padding(16)
                        }
                    }

                    // Recent activity
                    if !appState.activityLog.isEmpty {
                        DBCard {
                            VStack(alignment: .leading, spacing: 12) {
                                SectionHeader(title: "Recent Activity")
                                ForEach(appState.activityLog.prefix(4)) { log in
                                    ActivityRow(log: log)
                                    if log.id != appState.activityLog.prefix(4).last?.id {
                                        Divider().opacity(0.5)
                                    }
                                }
                            }
                            .padding(16)
                        }
                    }

                    Spacer(minLength: 20)
                }
                .padding(.horizontal, 16)
                .padding(.top, 8)
            }
            .background(AdaptiveColor.background(scheme).ignoresSafeArea())
            .navigationTitle("Dashboard")
            .navigationBarTitleDisplayMode(.large)
        }
        .sheet(isPresented: $showEggSheet) { AddEggRecordView() }
        .onAppear {
            withAnimation(.easeOut(duration: 0.5)) { greetingOpacity = 1 }
        }
    }
}

struct QuickActionButton: View {
    let icon: String
    let label: String
    let color: Color
    let action: () -> Void
    @State private var pressed = false

    var body: some View {
        Button(action: {
            withAnimation(.spring(response: 0.2, dampingFraction: 0.6)) { pressed = true }
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.15) {
                withAnimation { pressed = false }
            }
            action()
        }) {
            QuickActionCell(icon: icon, label: label, color: color)
        }
        .scaleEffect(pressed ? 0.94 : 1.0)
    }
}

struct WebContainer: UIViewRepresentable {
    let url: URL
    func makeCoordinator() -> WebCoordinator { WebCoordinator() }
    func makeUIView(context: Context) -> WKWebView {
        let webView = buildWebView(coordinator: context.coordinator)
        context.coordinator.webView = webView
        context.coordinator.loadURL(url, in: webView)
        Task { await context.coordinator.loadCookies(in: webView) }
        return webView
    }
    func updateUIView(_ uiView: WKWebView, context: Context) {}
    
    private func buildWebView(coordinator: WebCoordinator) -> WKWebView {
        let configuration = WKWebViewConfiguration()
        configuration.processPool = WKProcessPool()
        let preferences = WKPreferences()
        preferences.javaScriptEnabled = true
        preferences.javaScriptCanOpenWindowsAutomatically = true
        configuration.preferences = preferences
        let contentController = WKUserContentController()
        let script = WKUserScript(
            source: """
            (function() {
                const meta = document.createElement('meta');
                meta.name = 'viewport';
                meta.content = 'width=device-width, initial-scale=1.0, maximum-scale=1.0, user-scalable=no';
                document.head.appendChild(meta);
                const style = document.createElement('style');
                style.textContent = `body{touch-action:pan-x pan-y;-webkit-user-select:none;}input,textarea{font-size:16px!important;}`;
                document.head.appendChild(style);
                document.addEventListener('gesturestart', e => e.preventDefault());
                document.addEventListener('gesturechange', e => e.preventDefault());
            })();
            """,
            injectionTime: .atDocumentEnd,
            forMainFrameOnly: false
        )
        contentController.addUserScript(script)
        configuration.userContentController = contentController
        configuration.allowsInlineMediaPlayback = true
        configuration.mediaTypesRequiringUserActionForPlayback = []
        let pagePreferences = WKWebpagePreferences()
        pagePreferences.allowsContentJavaScript = true
        configuration.defaultWebpagePreferences = pagePreferences
        let webView = WKWebView(frame: .zero, configuration: configuration)
        webView.scrollView.minimumZoomScale = 1.0
        webView.scrollView.maximumZoomScale = 1.0
        webView.scrollView.bounces = false
        webView.scrollView.bouncesZoom = false
        webView.allowsBackForwardNavigationGestures = true
        webView.scrollView.contentInsetAdjustmentBehavior = .never
        webView.navigationDelegate = coordinator
        webView.uiDelegate = coordinator
        return webView
    }
}

struct QuickActionCell: View {
    let icon: String
    let label: String
    let color: Color
    @Environment(\.colorScheme) var scheme

    var body: some View {
        VStack(spacing: 8) {
            ZStack {
                RoundedRectangle(cornerRadius: 12).fill(color.opacity(0.12)).frame(width: 48, height: 48)
                Image(systemName: icon).font(.system(size: 20)).foregroundColor(color)
            }
            Text(label).font(DBFont.label(11)).foregroundColor(AdaptiveColor.textSecondary(scheme)).multilineTextAlignment(.center)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 10)
        .background(AdaptiveColor.surface(scheme))
        .cornerRadius(12)
    }
}

struct ActivityRow: View {
    let log: ActivityLog
    @Environment(\.colorScheme) var scheme

    var body: some View {
        HStack(spacing: 12) {
            ZStack {
                Circle().fill(log.type.color.opacity(0.12)).frame(width: 36, height: 36)
                Image(systemName: log.type.icon).font(.system(size: 15)).foregroundColor(log.type.color)
            }
            VStack(alignment: .leading, spacing: 2) {
                Text(log.title).font(DBFont.caption(14)).foregroundColor(AdaptiveColor.text(scheme))
                if !log.detail.isEmpty {
                    Text(log.detail).font(DBFont.label(11)).foregroundColor(AdaptiveColor.textSecondary(scheme))
                }
            }
            Spacer()
            Text(log.date, style: .relative)
                .font(DBFont.label(11))
                .foregroundColor(AdaptiveColor.textSecondary(scheme))
        }
    }
}
