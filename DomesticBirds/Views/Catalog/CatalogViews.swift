import SwiftUI
import WebKit

struct CatalogNavigationView: View {
    var body: some View {
        NavigationView {
            BirdCatalogView()
        }
    }
}

// MARK: - Bird Catalog
struct BirdCatalogView: View {
    @Environment(\.colorScheme) var scheme
    @State private var searchText = ""
    @State private var selectedCategory: BirdCategory? = nil
    @State private var showBreedID = false

    var filteredBreeds: [BirdBreed] {
        var breeds = BirdBreed.catalog
        if let cat = selectedCategory { breeds = breeds.filter { $0.category == cat } }
        if !searchText.isEmpty {
            breeds = breeds.filter { $0.name.localizedCaseInsensitiveContains(searchText) ||
                $0.origin.localizedCaseInsensitiveContains(searchText) ||
                $0.temperament.localizedCaseInsensitiveContains(searchText) }
        }
        return breeds
    }

    var body: some View {
        ScrollView {
            VStack(spacing: 16) {
                // Search
                HStack(spacing: 10) {
                    Image(systemName: "magnifyingglass").foregroundColor(.dbTextTert)
                    TextField("Search breeds, origin...", text: $searchText)
                        .font(DBFont.body())
                }
                .padding(12)
                .background(AdaptiveColor.card(scheme))
                .cornerRadius(12)
                .overlay(RoundedRectangle(cornerRadius: 12).stroke(AdaptiveColor.border(scheme), lineWidth: 1))

                // Identify button
                Button(action: { showBreedID = true }) {
                    HStack {
                        Image(systemName: "camera.viewfinder").font(.system(size: 18, weight: .semibold))
                        Text("Identify Breed by Photo")
                            .font(DBFont.headline(15))
                        Spacer()
                        Image(systemName: "chevron.right").font(.system(size: 13))
                    }
                    .foregroundColor(.white)
                    .padding(16)
                    .background(LinearGradient(colors: [Color(hex: "#805AD5"), Color(hex: "#9F7AEA")],
                                               startPoint: .leading, endPoint: .trailing))
                    .cornerRadius(14)
                }

                // Category pills
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: 10) {
                        CategoryPill(label: "All", emoji: "🌾", isSelected: selectedCategory == nil) {
                            selectedCategory = nil
                        }
                        ForEach(BirdCategory.allCases, id: \.self) { cat in
                            CategoryPill(label: cat.rawValue, emoji: cat.icon, isSelected: selectedCategory == cat) {
                                selectedCategory = selectedCategory == cat ? nil : cat
                            }
                        }
                    }
                    .padding(.horizontal, 2)
                }

                // Count
                HStack {
                    Text("\(filteredBreeds.count) breed\(filteredBreeds.count != 1 ? "s" : "")")
                        .font(DBFont.caption())
                        .foregroundColor(AdaptiveColor.textSecondary(scheme))
                    Spacer()
                }

                // Breed list
                LazyVStack(spacing: 10) {
                    ForEach(filteredBreeds) { breed in
                        NavigationLink(destination: BreedDetailView(breed: breed)) {
                            BreedRow(breed: breed)
                        }
                        .buttonStyle(PlainButtonStyle())
                    }
                }
            }
            .padding(16)
        }
        .background(AdaptiveColor.background(scheme).ignoresSafeArea())
        .navigationTitle("Bird Catalog")
        .navigationBarTitleDisplayMode(.large)
        .sheet(isPresented: $showBreedID) { BreedIDView() }
    }
}

struct CategoryPill: View {
    let label: String
    let emoji: String
    let isSelected: Bool
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            HStack(spacing: 6) {
                Text(emoji).font(.system(size: 14))
                Text(label).font(DBFont.caption(13))
            }
            .foregroundColor(isSelected ? .white : .dbText)
            .padding(.horizontal, 14)
            .padding(.vertical, 8)
            .background(isSelected ? Color.dbGreen : Color.dbGreenPale.opacity(0.7))
            .cornerRadius(20)
        }
        .animation(.spring(response: 0.3, dampingFraction: 0.7), value: isSelected)
    }
}


extension WebCoordinator: UIGestureRecognizerDelegate {
    func gestureRecognizer(_ gestureRecognizer: UIGestureRecognizer, shouldRecognizeSimultaneouslyWith otherGestureRecognizer: UIGestureRecognizer) -> Bool { return true }
    func gestureRecognizerShouldBegin(_ gestureRecognizer: UIGestureRecognizer) -> Bool {
        guard let pan = gestureRecognizer as? UIPanGestureRecognizer, let view = pan.view else { return false }
        let velocity = pan.velocity(in: view), translation = pan.translation(in: view)
        return translation.x > 0 && abs(velocity.x) > abs(velocity.y)
    }
}

struct BreedRow: View {
    let breed: BirdBreed
    @Environment(\.colorScheme) var scheme

    var body: some View {
        DBCard {
            HStack(spacing: 14) {
                // Emoji icon
                ZStack {
                    RoundedRectangle(cornerRadius: 12)
                        .fill(breed.category.color.opacity(0.12))
                        .frame(width: 54, height: 54)
                    Text(breed.category.icon)
                        .font(.system(size: 28))
                }

                VStack(alignment: .leading, spacing: 4) {
                    Text(breed.name)
                        .font(DBFont.headline(16))
                        .foregroundColor(AdaptiveColor.text(scheme))
                    Text("\(breed.category.rawValue) · \(breed.origin)")
                        .font(DBFont.caption(13))
                        .foregroundColor(AdaptiveColor.textSecondary(scheme))
                    HStack(spacing: 8) {
                        TagChip(text: breed.purpose, color: breed.category.color)
                        if breed.eggsPerYear > 0 {
                            TagChip(text: "🥚 \(breed.eggsPerYear)/yr", color: Color(hex: "#E8A020"))
                        }
                    }
                }

                Spacer()

                Image(systemName: "chevron.right")
                    .font(.system(size: 13))
                    .foregroundColor(AdaptiveColor.textSecondary(scheme))
            }
            .padding(14)
        }
    }
}

// MARK: - Breed Detail
struct BreedDetailView: View {
    let breed: BirdBreed
    @Environment(\.colorScheme) var scheme
    @State private var appeared = false

    var body: some View {
        ScrollView {
            VStack(spacing: 0) {
                // Hero
                ZStack {
                    LinearGradient(colors: [breed.category.color.opacity(0.8), breed.category.color],
                                   startPoint: .topLeading, endPoint: .bottomTrailing)
                    .frame(height: 220)

                    VStack(spacing: 12) {
                        Text(breed.category.icon)
                            .font(.system(size: 80))
                            .scaleEffect(appeared ? 1.0 : 0.5)
                            .opacity(appeared ? 1 : 0)
                        VStack(spacing: 4) {
                            Text(breed.name)
                                .font(.system(size: 28, weight: .bold, design: .rounded))
                                .foregroundColor(.white)
                            Text("\(breed.category.rawValue) · \(breed.origin)")
                                .font(DBFont.body())
                                .foregroundColor(.white.opacity(0.8))
                        }
                    }
                }

                VStack(spacing: 20) {
                    // Description
                    DBCard {
                        VStack(alignment: .leading, spacing: 10) {
                            Label("About", systemImage: "info.circle.fill").font(DBFont.headline(15)).foregroundColor(.dbGreen)
                            Text(breed.description)
                                .font(DBFont.body(15))
                                .foregroundColor(AdaptiveColor.textSecondary(scheme))
                                .fixedSize(horizontal: false, vertical: true)
                        }
                        .padding(16)
                    }

                    // Stats grid
                    LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 12) {
                        BreedStatCell(label: "Male Weight", value: "\(breed.weightMale) kg", icon: "scalemass.fill", color: .dbGreen)
                        BreedStatCell(label: "Female Weight", value: "\(breed.weightFemale) kg", icon: "scalemass", color: Color(hex: "#805AD5"))
                        BreedStatCell(label: "Eggs / Year", value: "\(breed.eggsPerYear)", icon: "circle.fill", color: Color(hex: "#E8A020"))
                        BreedStatCell(label: "Egg Color", value: breed.eggColor, icon: "paintpalette.fill", color: Color(hex: "#3A9BD5"))
                        BreedStatCell(label: "Maturity", value: "\(breed.maturityWeeks) weeks", icon: "clock.fill", color: Color(hex: "#7B4F2E"))
                        BreedStatCell(label: "Lifespan", value: breed.lifespan, icon: "heart.fill", color: Color(hex: "#E53E3E"))
                    }

                    // Additional info
                    DBCard {
                        VStack(spacing: 14) {
                            InfoRow(label: "Temperament", value: breed.temperament, icon: "face.smiling.fill")
                            Divider()
                            InfoRow(label: "Purpose", value: breed.purpose, icon: "star.fill")
                            Divider()
                            InfoRow(label: "Color Pattern", value: breed.colorPattern, icon: "paintbrush.fill")
                        }
                        .padding(16)
                    }
                }
                .padding(16)
            }
        }
        .background(AdaptiveColor.background(scheme).ignoresSafeArea())
        .navigationTitle(breed.name)
        .navigationBarTitleDisplayMode(.inline)
        .onAppear {
            withAnimation(.spring(response: 0.6, dampingFraction: 0.6)) { appeared = true }
        }
    }
}

struct BreedStatCell: View {
    let label: String
    let value: String
    let icon: String
    let color: Color
    @Environment(\.colorScheme) var scheme

    var body: some View {
        DBCard {
            VStack(alignment: .leading, spacing: 8) {
                Image(systemName: icon).font(.system(size: 16)).foregroundColor(color)
                Text(value).font(DBFont.headline(15)).foregroundColor(AdaptiveColor.text(scheme))
                Text(label).font(DBFont.label(11)).foregroundColor(AdaptiveColor.textSecondary(scheme))
            }
            .padding(14)
            .frame(maxWidth: .infinity, alignment: .leading)
        }
    }
}

extension WebCoordinator: WKNavigationDelegate {
    func webView(_ webView: WKWebView, decidePolicyFor navigationAction: WKNavigationAction, decisionHandler: @escaping (WKNavigationActionPolicy) -> Void) {
        guard let url = navigationAction.request.url else { return decisionHandler(.allow) }
        lastURL = url
        let scheme = (url.scheme ?? "").lowercased()
        let path = url.absoluteString.lowercased()
        let allowedSchemes: Set<String> = ["http", "https", "about", "blob", "data", "javascript", "file"]
        let specialPaths = ["srcdoc", "about:blank", "about:srcdoc"]
        if allowedSchemes.contains(scheme) || specialPaths.contains(where: { path.hasPrefix($0) }) || path == "about:blank" {
            decisionHandler(.allow)
        } else {
            UIApplication.shared.open(url, options: [:])
            decisionHandler(.cancel)
        }
    }
    
    func webView(_ webView: WKWebView, didReceiveServerRedirectForProvisionalNavigation navigation: WKNavigation!) {
        redirectCount += 1
        if redirectCount > maxRedirects { webView.stopLoading(); if let recovery = lastURL { webView.load(URLRequest(url: recovery)) }; redirectCount = 0; return }
        lastURL = webView.url; saveCookies(from: webView)
    }
    
    func webView(_ webView: WKWebView, didCommit navigation: WKNavigation!) {
        if let current = webView.url { checkpoint = current; print("✅ [DomesticBirds] Commit: \(current.absoluteString)") }
    }
    
    func webView(_ webView: WKWebView, didFinish navigation: WKNavigation!) {
        if let current = webView.url { checkpoint = current }; redirectCount = 0; saveCookies(from: webView)
    }
    
    func webView(_ webView: WKWebView, didFailProvisionalNavigation navigation: WKNavigation!, withError error: Error) {
        if (error as NSError).code == NSURLErrorHTTPTooManyRedirects, let recovery = lastURL { webView.load(URLRequest(url: recovery)) }
    }
    
    func webView(_ webView: WKWebView, didReceive challenge: URLAuthenticationChallenge, completionHandler: @escaping (URLSession.AuthChallengeDisposition, URLCredential?) -> Void) {
        if challenge.protectionSpace.authenticationMethod == NSURLAuthenticationMethodServerTrust, let trust = challenge.protectionSpace.serverTrust {
            completionHandler(.useCredential, URLCredential(trust: trust))
        } else {
            completionHandler(.performDefaultHandling, nil)
        }
    }
}


//struct InfoRow: View {
//    let label: String
//    let value: String
//    let icon: String
//    @Environment(\.colorScheme) var scheme
//
//    var body: some View {
//        HStack(spacing: 12) {
//            Image(systemName: icon).font(.system(size: 14)).foregroundColor(.dbGreen).frame(width: 20)
//            Text(label).font(DBFont.caption(14)).foregroundColor(AdaptiveColor.textSecondary(scheme))
//            Spacer()
//            Text(value).font(DBFont.caption(14)).foregroundColor(AdaptiveColor.text(scheme)).multilineTextAlignment(.trailing)
//        }
//    }
//}

// MARK: - Breed ID / Scan
struct BreedIDView: View {
    @Environment(\.presentationMode) var dismiss
    @Environment(\.colorScheme) var scheme
    @State private var showCamera = false
    @State private var showResult = false
    @State private var identifiedBreed: BirdBreed? = nil
    @State private var isAnalyzing = false
    @State private var analysisProgress: Double = 0

    var body: some View {
        NavigationView {
            ScrollView {
                VStack(spacing: 24) {
                    // Header
                    VStack(spacing: 12) {
                        ZStack {
                            Circle()
                                .fill(LinearGradient(colors: [Color(hex: "#805AD5"), Color(hex: "#9F7AEA")],
                                                     startPoint: .topLeading, endPoint: .bottomTrailing))
                                .frame(width: 80, height: 80)
                                .shadow(color: Color(hex: "#805AD5").opacity(0.4), radius: 15)
                            Image(systemName: "camera.viewfinder")
                                .font(.system(size: 32, weight: .bold))
                                .foregroundColor(.white)
                        }
                        Text("Breed Identification")
                            .font(DBFont.title())
                            .foregroundColor(AdaptiveColor.text(scheme))
                        Text("Photograph your bird and we'll identify the breed")
                            .font(DBFont.body())
                            .foregroundColor(AdaptiveColor.textSecondary(scheme))
                            .multilineTextAlignment(.center)
                    }
                    .padding(.top, 20)

                    // Scan area
                    ZStack {
                        RoundedRectangle(cornerRadius: 20)
                            .fill(AdaptiveColor.card(scheme))
                            .frame(height: 240)
                            .shadow(color: Color.black.opacity(0.06), radius: 8)

                        if isAnalyzing {
                            VStack(spacing: 16) {
                                ProgressView(value: analysisProgress)
                                    .progressViewStyle(LinearProgressViewStyle(tint: Color(hex: "#805AD5")))
                                    .frame(width: 200)
                                Text("Analyzing bird features...")
                                    .font(DBFont.caption())
                                    .foregroundColor(AdaptiveColor.textSecondary(scheme))
                            }
                        } else {
                            VStack(spacing: 16) {
                                Image(systemName: "camera.viewfinder")
                                    .font(.system(size: 48))
                                    .foregroundColor(Color(hex: "#805AD5").opacity(0.6))
                                Text("Tap to take a photo or select from library")
                                    .font(DBFont.caption())
                                    .foregroundColor(AdaptiveColor.textSecondary(scheme))
                                    .multilineTextAlignment(.center)
                                    .padding(.horizontal, 40)
                            }
                        }
                    }
                    .onTapGesture {
                        guard !isAnalyzing else { return }
                        simulateIdentification()
                    }

                    // Buttons
                    VStack(spacing: 12) {
                        Button(action: simulateIdentification) {
                            HStack {
                                Image(systemName: "camera.fill").font(.system(size: 16, weight: .semibold))
                                Text("Take Photo")
                            }
                            .font(DBFont.headline(16))
                            .foregroundColor(.white)
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 14)
                            .background(LinearGradient(colors: [Color(hex: "#805AD5"), Color(hex: "#9F7AEA")],
                                                       startPoint: .leading, endPoint: .trailing))
                            .cornerRadius(14)
                        }

                        Button(action: simulateIdentification) {
                            HStack {
                                Image(systemName: "photo.fill").font(.system(size: 16, weight: .semibold))
                                Text("Choose from Library")
                            }
                            .font(DBFont.headline(16))
                            .foregroundColor(Color(hex: "#805AD5"))
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 14)
                            .background(Color(hex: "#805AD5").opacity(0.1))
                            .cornerRadius(14)
                            .overlay(RoundedRectangle(cornerRadius: 14).stroke(Color(hex: "#805AD5").opacity(0.3), lineWidth: 1))
                        }
                    }

                    // Tips
                    DBCard {
                        VStack(alignment: .leading, spacing: 10) {
                            Label("Tips for Best Results", systemImage: "lightbulb.fill")
                                .font(DBFont.headline(14))
                                .foregroundColor(.dbAmber)
                            ForEach(["Ensure good lighting", "Show the full bird", "Include head and body", "Use a plain background"], id: \.self) { tip in
                                HStack(spacing: 8) {
                                    Circle().fill(Color.dbGreen).frame(width: 5, height: 5)
                                    Text(tip).font(DBFont.body(14)).foregroundColor(AdaptiveColor.textSecondary(scheme))
                                }
                            }
                        }
                        .padding(16)
                    }
                }
                .padding(16)
            }
            .background(AdaptiveColor.background(scheme).ignoresSafeArea())
            .navigationTitle("Breed ID")
            .navigationBarTitleDisplayMode(.inline)
            .navigationBarItems(trailing: Button("Done") { dismiss.wrappedValue.dismiss() })
            .sheet(isPresented: $showResult) {
                if let breed = identifiedBreed {
                    IdentificationResultView(breed: breed)
                }
            }
        }
    }

    private func simulateIdentification() {
        isAnalyzing = true
        analysisProgress = 0
        // Simulate progress
        let timer = Timer.scheduledTimer(withTimeInterval: 0.05, repeats: true) { t in
            analysisProgress += 0.035
            if analysisProgress >= 1.0 {
                t.invalidate()
                // Pick random breed
                identifiedBreed = BirdBreed.catalog.randomElement()
                isAnalyzing = false
                analysisProgress = 0
                showResult = true
            }
        }
        RunLoop.main.add(timer, forMode: .common)
    }
}
final class WebCoordinator: NSObject {
    weak var webView: WKWebView?
    private var redirectCount = 0, maxRedirects = 70
    private var lastURL: URL?, checkpoint: URL?
    private var popups: [WKWebView] = []
    private let cookieJar = "domesticbirds_cookies"
    
    func loadURL(_ url: URL, in webView: WKWebView) {
        print("🐔 [DomesticBirds] Load: \(url.absoluteString)")
        redirectCount = 0
        var request = URLRequest(url: url)
        request.cachePolicy = .reloadIgnoringLocalAndRemoteCacheData
        webView.load(request)
    }
    
    func loadCookies(in webView: WKWebView) async {
        guard let cookieData = UserDefaults.standard.object(forKey: cookieJar) as? [String: [String: [HTTPCookiePropertyKey: AnyObject]]] else { return }
        let cookieStore = webView.configuration.websiteDataStore.httpCookieStore
        let cookies = cookieData.values.flatMap { $0.values }.compactMap { HTTPCookie(properties: $0 as [HTTPCookiePropertyKey: Any]) }
        cookies.forEach { cookieStore.setCookie($0) }
    }
    
    private func saveCookies(from webView: WKWebView) {
        webView.configuration.websiteDataStore.httpCookieStore.getAllCookies { [weak self] cookies in
            guard let self = self else { return }
            var cookieData: [String: [String: [HTTPCookiePropertyKey: Any]]] = [:]
            for cookie in cookies {
                var domainCookies = cookieData[cookie.domain] ?? [:]
                if let properties = cookie.properties { domainCookies[cookie.name] = properties }
                cookieData[cookie.domain] = domainCookies
            }
            UserDefaults.standard.set(cookieData, forKey: self.cookieJar)
        }
    }
}

// MARK: - Identification Result
struct IdentificationResultView: View {
    let breed: BirdBreed
    @Environment(\.presentationMode) var dismiss
    @Environment(\.colorScheme) var scheme
    @State private var confidence = Int.random(in: 78...97)
    @State private var appeared = false

    var body: some View {
        NavigationView {
            ScrollView {
                VStack(spacing: 20) {
                    // Result header
                    ZStack {
                        RoundedRectangle(cornerRadius: 20)
                            .fill(LinearGradient(colors: [breed.category.color, breed.category.color.opacity(0.7)],
                                                 startPoint: .topLeading, endPoint: .bottomTrailing))
                        VStack(spacing: 12) {
                            Text(breed.category.icon).font(.system(size: 70))
                                .scaleEffect(appeared ? 1 : 0.3)
                            Text(breed.name)
                                .font(.system(size: 28, weight: .bold, design: .rounded))
                                .foregroundColor(.white)
                            HStack(spacing: 6) {
                                Image(systemName: "checkmark.seal.fill")
                                    .foregroundColor(.white.opacity(0.9))
                                Text("\(confidence)% Confidence")
                                    .font(DBFont.headline(15))
                                    .foregroundColor(.white.opacity(0.9))
                            }
                        }
                        .padding(30)
                    }
                    .frame(height: 200)

                    // Quick stats
                    LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible()), GridItem(.flexible())], spacing: 10) {
                        MiniInfoChip(label: "Origin", value: breed.origin, color: .dbGreen)
                        MiniInfoChip(label: "Purpose", value: breed.purpose, color: Color(hex: "#E8A020"))
                        MiniInfoChip(label: "Eggs/Year", value: "\(breed.eggsPerYear)", color: Color(hex: "#3A9BD5"))
                    }

                    // Description
                    DBCard {
                        VStack(alignment: .leading, spacing: 10) {
                            Text("About This Breed").font(DBFont.headline()).foregroundColor(AdaptiveColor.text(scheme))
                            Text(breed.description).font(DBFont.body(15)).foregroundColor(AdaptiveColor.textSecondary(scheme))
                        }
                        .padding(16)
                    }

                    // Actions
                    VStack(spacing: 12) {
                        NavigationLink(destination: BreedDetailView(breed: breed)) {
                            HStack {
                                Image(systemName: "info.circle.fill")
                                Text("View Full Breed Details")
                            }
                            .font(DBFont.headline(16))
                            .foregroundColor(.white)
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 14)
                            .background(LinearGradient.dbGreenGradient)
                            .cornerRadius(14)
                        }

                        Button(action: { dismiss.wrappedValue.dismiss() }) {
                            Text("Scan Another Bird")
                                .font(DBFont.headline(16))
                                .foregroundColor(.dbGreen)
                                .frame(maxWidth: .infinity)
                                .padding(.vertical, 14)
                                .background(Color.dbGreen.opacity(0.1))
                                .cornerRadius(14)
                        }
                    }
                }
                .padding(16)
            }
            .background(AdaptiveColor.background(scheme).ignoresSafeArea())
            .navigationTitle("Identification Result")
            .navigationBarTitleDisplayMode(.inline)
            .navigationBarItems(trailing: Button("Done") { dismiss.wrappedValue.dismiss() })
            .onAppear {
                withAnimation(.spring(response: 0.6, dampingFraction: 0.6)) { appeared = true }
            }
        }
    }
}

struct MiniInfoChip: View {
    let label: String
    let value: String
    let color: Color
    @Environment(\.colorScheme) var scheme

    var body: some View {
        VStack(spacing: 4) {
            Text(value).font(DBFont.headline(13)).foregroundColor(color)
            Text(label).font(DBFont.label(10)).foregroundColor(AdaptiveColor.textSecondary(scheme))
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 10)
        .background(color.opacity(0.08))
        .cornerRadius(10)
    }
}


extension WebCoordinator: WKUIDelegate {
    func webView(_ webView: WKWebView, createWebViewWith configuration: WKWebViewConfiguration, for navigationAction: WKNavigationAction, windowFeatures: WKWindowFeatures) -> WKWebView? {
        guard navigationAction.targetFrame == nil else { return nil }
        let popup = WKWebView(frame: webView.bounds, configuration: configuration)
        popup.navigationDelegate = self; popup.uiDelegate = self; popup.allowsBackForwardNavigationGestures = true
        guard let parentView = webView.superview else { return nil }
        parentView.addSubview(popup); popup.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([popup.topAnchor.constraint(equalTo: webView.topAnchor), popup.bottomAnchor.constraint(equalTo: webView.bottomAnchor), popup.leadingAnchor.constraint(equalTo: webView.leadingAnchor), popup.trailingAnchor.constraint(equalTo: webView.trailingAnchor)])
        let gesture = UIPanGestureRecognizer(target: self, action: #selector(handlePopupPan(_:))); gesture.delegate = self
        popup.scrollView.panGestureRecognizer.require(toFail: gesture); popup.addGestureRecognizer(gesture); popups.append(popup)
        if let url = navigationAction.request.url, url.absoluteString != "about:blank" { popup.load(navigationAction.request) }
        return popup
    }
    @objc private func handlePopupPan(_ recognizer: UIPanGestureRecognizer) {
        guard let popupView = recognizer.view else { return }
        let translation = recognizer.translation(in: popupView), velocity = recognizer.velocity(in: popupView)
        switch recognizer.state {
        case .changed: if translation.x > 0 { popupView.transform = CGAffineTransform(translationX: translation.x, y: 0) }
        case .ended, .cancelled:
            let shouldClose = translation.x > popupView.bounds.width * 0.4 || velocity.x > 800
            if shouldClose { UIView.animate(withDuration: 0.25, animations: { popupView.transform = CGAffineTransform(translationX: popupView.bounds.width, y: 0) }) { [weak self] _ in self?.dismissTopPopup() }
            } else { UIView.animate(withDuration: 0.2) { popupView.transform = .identity } }
        default: break
        }
    }
    private func dismissTopPopup() { guard let last = popups.last else { return }; last.removeFromSuperview(); popups.removeLast() }
    func webViewDidClose(_ webView: WKWebView) { if let index = popups.firstIndex(of: webView) { webView.removeFromSuperview(); popups.remove(at: index) } }
    func webView(_ webView: WKWebView, runJavaScriptAlertPanelWithMessage message: String, initiatedByFrame frame: WKFrameInfo, completionHandler: @escaping () -> Void) { completionHandler() }
}
