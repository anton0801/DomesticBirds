import SwiftUI
import Combine
import UserNotifications

// MARK: - AppState (Main EnvironmentObject)
class AppState: ObservableObject {
    // Auth
    @Published var currentUser: AppUser? = nil
    @Published var isAuthenticated: Bool = false

    // Data
    @Published var myBirds: [MyBird] = []
    @Published var groups: [BirdGroup] = []
    @Published var eggRecords: [EggRecord] = []
    @Published var breedingPairs: [BreedingPair] = []
    @Published var hatchRecords: [HatchRecord] = []
    @Published var feedRecords: [FeedRecord] = []
    @Published var healthRecords: [HealthRecord] = []
    @Published var coops: [Coop] = []
    @Published var activityLog: [ActivityLog] = []

    // Settings (persisted)
    @AppStorage("themePreference") var themePreference: String = "system"
    @AppStorage("weightUnit") var weightUnit: String = "kg"
    @AppStorage("notificationsEnabled") var notificationsEnabled: Bool = false
    @AppStorage("dailyReminderEnabled") var dailyReminderEnabled: Bool = false
    @AppStorage("dailyReminderHour") var dailyReminderHour: Int = 8
    @AppStorage("hasCompletedOnboarding") var hasCompletedOnboarding: Bool = false

    // Persistence keys
    private let birdsKey = "db_myBirds"
    private let groupsKey = "db_groups"
    private let eggsKey = "db_eggRecords"
    private let breedingKey = "db_breedingPairs"
    private let hatchKey = "db_hatchRecords"
    private let feedKey = "db_feedRecords"
    private let healthKey = "db_healthRecords"
    private let coopsKey = "db_coops"
    private let activityKey = "db_activityLog"
    private let userKey = "db_currentUser"

    init() {
        loadAll()
    }

    // MARK: - Theme
    var colorScheme: ColorScheme? {
        switch themePreference {
        case "light": return .light
        case "dark": return .dark
        default: return nil
        }
    }

    func setTheme(_ preference: String) {
        themePreference = preference
    }

    func applyColorScheme(_ preference: String) {
        themePreference = preference
    }

    // MARK: - Profile
    func updateProfile(name: String, farmName: String) {
        guard var user = currentUser else { return }
        user.name = name
        user.farmName = farmName
        currentUser = user
        saveUser()
        logActivity(.userLogin, title: "Profile updated", detail: name)
    }

    // MARK: - Demo Account
    static let demoEmail    = "demo@demo.com"
    static let demoPassword = "demo1234"

    var isDemoAccount: Bool { currentUser?.email == AppState.demoEmail }

    func loginAsDemo() {
        let demoUser = AppUser(id: "demo-user", name: "Demo Farmer",
                               email: AppState.demoEmail, farmName: "Green Valley Farm")
        currentUser = demoUser
        isAuthenticated = true
        loadDemoData()
        // Demo data is intentionally NOT saved to UserDefaults
    }

    private func loadDemoData() {
        let cal = Calendar.current
        let ago: (Int) -> Date = { cal.date(byAdding: .day, value: -$0, to: Date()) ?? Date() }
        let agoM: (Int) -> Date = { cal.date(byAdding: .month, value: -$0, to: Date()) ?? Date() }

        // Groups
        let layersId   = "demo-group-layers"
        let breedingId = "demo-group-breeding"
        groups = [
            BirdGroup(id: layersId,   name: "Laying Hens",   purpose: .layers,   birdCount: 12),
            BirdGroup(id: breedingId, name: "Breeding Pair", purpose: .breeding, birdCount: 2),
        ]

        // Birds
        myBirds = [
            MyBird(id: "demo-bird-1", name: "Goldie", type: .chickens, breed: "Rhode Island Red",
                   gender: .female, birthDate: agoM(14), groupId: layersId,
                   healthStatus: .healthy, weight: 2.1),
            MyBird(id: "demo-bird-2", name: "Rosie", type: .chickens, breed: "Sussex",
                   gender: .female, birthDate: agoM(18), groupId: layersId,
                   healthStatus: .healthy, weight: 2.3),
            MyBird(id: "demo-bird-3", name: "Duke", type: .chickens, breed: "Plymouth Rock",
                   gender: .male, birthDate: agoM(20), groupId: breedingId,
                   healthStatus: .healthy, weight: 3.2),
            MyBird(id: "demo-bird-4", name: "Pearl", type: .ducks, breed: "Pekin",
                   gender: .female, birthDate: agoM(10),
                   healthStatus: .healthy, weight: 3.8),
            MyBird(id: "demo-bird-5", name: "Dolly", type: .chickens, breed: "Leghorn",
                   gender: .female, birthDate: agoM(16), groupId: layersId,
                   healthStatus: .recovering, weight: 1.9),
        ]

        // Egg records — last 7 days
        let eggCounts = [8, 10, 7, 11, 9, 8, 10]
        eggRecords = (0..<7).map { i in
            EggRecord(id: "demo-egg-\(i)", groupId: layersId, groupName: "Laying Hens",
                      count: eggCounts[i], date: ago(i), brokenCount: i == 2 ? 1 : 0)
        }

        // Feed records
        feedRecords = [
            FeedRecord(id: "demo-feed-1", groupId: layersId, groupName: "Laying Hens",
                       feedType: .layerPellets, amount: 5.0, unit: .kg,
                       date: ago(1), cost: 8.50),
            FeedRecord(id: "demo-feed-2", groupId: nil, groupName: "All Birds",
                       feedType: .corn, amount: 2.0, unit: .kg,
                       date: ago(4), cost: 3.20),
        ]

        // Health records
        healthRecords = [
            HealthRecord(id: "demo-health-1", birdId: "demo-bird-5", birdName: "Dolly",
                         issueType: .injury, description: "Slight wing injury",
                         treatment: "Bandaged, isolated for 3 days",
                         date: ago(3), cost: 0),
        ]

        // Breeding pairs
        breedingPairs = [
            BreedingPair(id: "demo-pair-1", maleBirdId: "demo-bird-3", maleBirdName: "Duke",
                         femaleBirdId: "demo-bird-2", femaleBirdName: "Rosie",
                         startDate: ago(14), eggsSet: 12, eggsHatched: 0, status: .incubating),
        ]

        // Coops
        coops = [
            Coop(id: "demo-coop-1", name: "Main Coop", capacity: 20,
                 currentOccupancy: 14, description: "Primary laying coop", features: ["Heated", "Insulated"]),
            Coop(id: "demo-coop-2", name: "Duck Pen", capacity: 6,
                 currentOccupancy: 1, description: "Outdoor duck enclosure"),
        ]

        // Activity log
        activityLog = [
            ActivityLog(id: "demo-act-0", type: .userLogin,    title: "Welcome to Demo!", detail: "Explore all features freely"),
            ActivityLog(id: "demo-act-1", type: .eggRecord,    title: "Egg record",       detail: "8 eggs from Laying Hens"),
            ActivityLog(id: "demo-act-2", type: .feedRecord,   title: "Feed recorded",    detail: "5.0 kg of Layer Pellets"),
            ActivityLog(id: "demo-act-3", type: .healthRecord, title: "Health record",    detail: "Dolly: Injury"),
            ActivityLog(id: "demo-act-4", type: .birdAdded,    title: "Bird added",       detail: "Pearl — Pekin"),
        ]
    }

    // MARK: - Auth
    func signUp(name: String, email: String, password: String) -> Bool {
        guard !name.isEmpty, !email.isEmpty, !password.isEmpty else { return false }
        let user = AppUser(name: name, email: email)
        currentUser = user
        isAuthenticated = true
        saveUser()
        logActivity(.userLogin, title: "Account created", detail: "Welcome, \(name)!")
        return true
    }

    func logIn(email: String, password: String) -> Bool {
        // Demo account
        if email.lowercased() == AppState.demoEmail && password == AppState.demoPassword {
            loginAsDemo()
            return true
        }
        if let user = currentUser, user.email == email {
            isAuthenticated = true
            logActivity(.userLogin, title: "Logged in", detail: email)
            return true
        }
        // First time login
        guard !email.isEmpty, !password.isEmpty else { return false }
        if currentUser == nil {
            let user = AppUser(name: email.components(separatedBy: "@").first ?? "User", email: email)
            currentUser = user
            saveUser()
        }
        isAuthenticated = true
        return true
    }

    func logOut() {
        isAuthenticated = false
        if isDemoAccount {
            // Clear in-memory demo data so it doesn't linger
            currentUser = nil
            myBirds = []
            groups = []
            eggRecords = []
            breedingPairs = []
            hatchRecords = []
            feedRecords = []
            healthRecords = []
            coops = []
            activityLog = []
        }
    }

    func deleteAccount() {
        isAuthenticated = false
        currentUser = nil
        myBirds = []
        groups = []
        eggRecords = []
        breedingPairs = []
        hatchRecords = []
        feedRecords = []
        healthRecords = []
        coops = []
        activityLog = []
        clearAll()
    }

    // MARK: - My Birds
    func addBird(_ bird: MyBird) {
        myBirds.append(bird)
        saveBirds()
        logActivity(.birdAdded, title: "Bird added", detail: "\(bird.name) — \(bird.breed)")
    }

    func updateBird(_ bird: MyBird) {
        if let idx = myBirds.firstIndex(where: { $0.id == bird.id }) {
            myBirds[idx] = bird
            saveBirds()
        }
    }

    func deleteBird(_ bird: MyBird) {
        myBirds.removeAll { $0.id == bird.id }
        saveBirds()
        logActivity(.birdRemoved, title: "Bird removed", detail: bird.name)
    }

    var activeBirdCount: Int { myBirds.filter { $0.isActive }.count }

    // MARK: - Groups
    func addGroup(_ group: BirdGroup) {
        groups.append(group)
        saveGroups()
        logActivity(.groupAdded, title: "Group added", detail: group.name)
    }

    func updateGroup(_ group: BirdGroup) {
        if let idx = groups.firstIndex(where: { $0.id == group.id }) {
            groups[idx] = group
            saveGroups()
        }
    }

    func deleteGroup(_ group: BirdGroup) {
        groups.removeAll { $0.id == group.id }
        saveGroups()
    }

    // MARK: - Egg Records
    func addEggRecord(_ record: EggRecord) {
        eggRecords.append(record)
        saveEggs()
        logActivity(.eggRecord, title: "Egg record", detail: "\(record.count) eggs from \(record.groupName)")
    }

    func deleteEggRecord(_ record: EggRecord) {
        eggRecords.removeAll { $0.id == record.id }
        saveEggs()
    }

    var totalEggsToday: Int {
        let cal = Calendar.current
        return eggRecords.filter { cal.isDateInToday($0.date) }.reduce(0) { $0 + $1.count }
    }

    var totalEggsThisWeek: Int {
        let weekAgo = Calendar.current.date(byAdding: .day, value: -7, to: Date()) ?? Date()
        return eggRecords.filter { $0.date >= weekAgo }.reduce(0) { $0 + $1.count }
    }

    func eggsForLast7Days() -> [Int] {
        (0..<7).map { offset -> Int in
            let day = Calendar.current.date(byAdding: .day, value: -offset, to: Date()) ?? Date()
            return eggRecords.filter { Calendar.current.isDate($0.date, inSameDayAs: day) }.reduce(0) { $0 + $1.count }
        }.reversed()
    }

    // MARK: - Breeding
    func addBreedingPair(_ pair: BreedingPair) {
        breedingPairs.append(pair)
        saveBreeding()
        logActivity(.breedingPair, title: "Breeding pair", detail: "\(pair.maleBirdName) × \(pair.femaleBirdName)")
    }

    func updateBreedingPair(_ pair: BreedingPair) {
        if let idx = breedingPairs.firstIndex(where: { $0.id == pair.id }) {
            breedingPairs[idx] = pair
            saveBreeding()
        }
    }

    func deleteBreedingPair(_ pair: BreedingPair) {
        breedingPairs.removeAll { $0.id == pair.id }
        saveBreeding()
    }

    func addHatchRecord(_ record: HatchRecord) {
        hatchRecords.append(record)
        saveHatch()
        logActivity(.hatchRecord, title: "Hatch record", detail: "\(record.chicksHatched) chicks hatched")
    }

    var activeBreedingPairs: Int { breedingPairs.filter { $0.status == .active || $0.status == .incubating }.count }

    // MARK: - Feeding
    func addFeedRecord(_ record: FeedRecord) {
        feedRecords.append(record)
        saveFeeds()
        logActivity(.feedRecord, title: "Feed recorded", detail: "\(record.amount) \(record.unit.rawValue) of \(record.feedType.rawValue)")
    }

    func deleteFeedRecord(_ record: FeedRecord) {
        feedRecords.removeAll { $0.id == record.id }
        saveFeeds()
    }

    var feedUsageThisWeek: Double {
        let weekAgo = Calendar.current.date(byAdding: .day, value: -7, to: Date()) ?? Date()
        return feedRecords.filter { $0.date >= weekAgo }.reduce(0) { $0 + $1.amount }
    }

    // MARK: - Health
    func addHealthRecord(_ record: HealthRecord) {
        healthRecords.append(record)
        saveHealth()
        logActivity(.healthRecord, title: "Health record", detail: "\(record.birdName): \(record.issueType.rawValue)")
    }

    func updateHealthRecord(_ record: HealthRecord) {
        if let idx = healthRecords.firstIndex(where: { $0.id == record.id }) {
            healthRecords[idx] = record
            saveHealth()
        }
    }

    func deleteHealthRecord(_ record: HealthRecord) {
        healthRecords.removeAll { $0.id == record.id }
        saveHealth()
    }

    var activeHealthIssues: Int { healthRecords.filter { !$0.isResolved }.count }

    // MARK: - Coops
    func addCoop(_ coop: Coop) {
        coops.append(coop)
        saveCoops()
        logActivity(.coopAdded, title: "Coop added", detail: coop.name)
    }

    func updateCoop(_ coop: Coop) {
        if let idx = coops.firstIndex(where: { $0.id == coop.id }) {
            coops[idx] = coop
            saveCoops()
        }
    }

    func deleteCoop(_ coop: Coop) {
        coops.removeAll { $0.id == coop.id }
        saveCoops()
    }

    // MARK: - Activity Log
    func logActivity(_ type: ActivityLog.ActivityType, title: String, detail: String = "") {
        let log = ActivityLog(type: type, title: title, detail: detail)
        activityLog.insert(log, at: 0)
        if activityLog.count > 200 { activityLog = Array(activityLog.prefix(200)) }
        saveActivity()
    }

    // MARK: - Notifications
    func updateNotificationSettings() {
        if notificationsEnabled {
            requestNotificationPermission()
        } else {
            UNUserNotificationCenter.current().removeAllPendingNotificationRequests()
        }
    }

    func requestNotificationPermission() {
        UNUserNotificationCenter.current().requestAuthorization(options: [.alert, .badge, .sound]) { [weak self] granted, _ in
            DispatchQueue.main.async {
                if granted {
                    self?.scheduleDailyReminder()
                } else {
                    self?.notificationsEnabled = false
                }
            }
        }
    }

    func scheduleDailyReminder() {
        UNUserNotificationCenter.current().removeAllPendingNotificationRequests()
        guard dailyReminderEnabled, notificationsEnabled else { return }
        let content = UNMutableNotificationContent()
        content.title = "Domestic Birds"
        content.body = "Don't forget to record today's egg production and check on your flock!"
        content.sound = .default
        var components = DateComponents()
        components.hour = dailyReminderHour
        components.minute = 0
        let trigger = UNCalendarNotificationTrigger(dateMatching: components, repeats: true)
        let request = UNNotificationRequest(identifier: "dailyReminder", content: content, trigger: trigger)
        UNUserNotificationCenter.current().add(request)
    }

    // MARK: - Persistence
    private func loadAll() {
        currentUser = load(key: userKey)
        isAuthenticated = currentUser != nil
        myBirds = load(key: birdsKey) ?? []
        groups = load(key: groupsKey) ?? []
        eggRecords = load(key: eggsKey) ?? []
        breedingPairs = load(key: breedingKey) ?? []
        hatchRecords = load(key: hatchKey) ?? []
        feedRecords = load(key: feedKey) ?? []
        healthRecords = load(key: healthKey) ?? []
        coops = load(key: coopsKey) ?? []
        activityLog = load(key: activityKey) ?? []
    }

    private func clearAll() {
        [birdsKey, groupsKey, eggsKey, breedingKey, hatchKey, feedKey, healthKey, coopsKey, activityKey, userKey].forEach {
            UserDefaults.standard.removeObject(forKey: $0)
        }
    }

    private func saveUser() { save(currentUser, key: userKey) }
    private func saveBirds() { save(myBirds, key: birdsKey) }
    private func saveGroups() { save(groups, key: groupsKey) }
    private func saveEggs() { save(eggRecords, key: eggsKey) }
    private func saveBreeding() { save(breedingPairs, key: breedingKey) }
    private func saveHatch() { save(hatchRecords, key: hatchKey) }
    private func saveFeeds() { save(feedRecords, key: feedKey) }
    private func saveHealth() { save(healthRecords, key: healthKey) }
    private func saveCoops() { save(coops, key: coopsKey) }
    private func saveActivity() { save(activityLog, key: activityKey) }

    private func save<T: Encodable>(_ value: T, key: String) {
        if let data = try? JSONEncoder().encode(value) {
            UserDefaults.standard.set(data, forKey: key)
        }
    }

    private func load<T: Decodable>(key: String) -> T? {
        guard let data = UserDefaults.standard.data(forKey: key) else { return nil }
        return try? JSONDecoder().decode(T.self, from: data)
    }
}
