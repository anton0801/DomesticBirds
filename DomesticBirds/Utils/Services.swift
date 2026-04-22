import Foundation
import AppsFlyerLib
import FirebaseCore
import FirebaseMessaging
import WebKit
import UserNotifications
import Supabase

final class DomesticBirdsStorageService: StorageServiceProtocol {
    private let suite = UserDefaults(suiteName: "group.domesticbirds.app")!
    private let cache = UserDefaults.standard
    
    private enum Key {
        static let tracking = "db_tracking_data"
        static let navigation = "db_navigation_data"
        static let endpoint = "db_target_endpoint"
        static let mode = "db_active_mode"
        static let launched = "db_launch_flag"
        static let permGranted = "db_permission_granted"
        static let permDenied = "db_permission_denied"
        static let permDate = "db_permission_date"
    }
    
    func save(tracking: [String: String]) {
        if let json = encode(dictionary: tracking) {
            suite.set(json, forKey: Key.tracking)
        }
    }
    
    func save(navigation: [String: String]) {
        if let json = encode(dictionary: navigation) {
            let encoded = encodeBase64(json)
            suite.set(encoded, forKey: Key.navigation)
        }
    }
    
    func save(endpoint: String) {
        suite.set(endpoint, forKey: Key.endpoint)
        cache.set(endpoint, forKey: Key.endpoint)
    }
    
    func save(mode: String) {
        suite.set(mode, forKey: Key.mode)
    }
    
    func save(permission: DomesticBirdsWriteModel.PermissionWriteModel) {
        suite.set(permission.isGranted, forKey: Key.permGranted)
        suite.set(permission.isDenied, forKey: Key.permDenied)
        if let date = permission.lastAsked {
            suite.set(date.timeIntervalSince1970 * 1000, forKey: Key.permDate)
        }
    }
    
    func markAsLaunched() {
        suite.set(true, forKey: Key.launched)
    }
    
    func load() -> StorageModel {
        var tracking: [String: String] = [:]
        if let json = suite.string(forKey: Key.tracking),
           let dict = decode(json: json) {
            tracking = dict
        }
        
        var navigation: [String: String] = [:]
        if let encoded = suite.string(forKey: Key.navigation),
           let json = decodeBase64(encoded),
           let dict = decode(json: json) {
            navigation = dict
        }
        
        let endpoint = suite.string(forKey: Key.endpoint)
        let mode = suite.string(forKey: Key.mode)
        let isFirstLaunch = !suite.bool(forKey: Key.launched)
        
        let granted = suite.bool(forKey: Key.permGranted)
        let denied = suite.bool(forKey: Key.permDenied)
        let ts = suite.double(forKey: Key.permDate)
        let date = ts > 0 ? Date(timeIntervalSince1970: ts / 1000) : nil
        
        return StorageModel(
            tracking: tracking,
            navigation: navigation,
            endpoint: endpoint,
            mode: mode,
            isFirstLaunch: isFirstLaunch,
            permission: StorageModel.PermissionStorage(
                isGranted: granted,
                isDenied: denied,
                lastAsked: date
            )
        )
    }
    
    private func encode(dictionary: [String: String]) -> String? {
        guard let data = try? JSONSerialization.data(withJSONObject: dictionary.mapValues { $0 as Any }),
              let string = String(data: data, encoding: .utf8) else { return nil }
        return string
    }
    
    private func decode(json: String) -> [String: String]? {
        guard let data = json.data(using: .utf8),
              let dict = try? JSONSerialization.jsonObject(with: data) as? [String: Any] else { return nil }
        return dict.mapValues { "\($0)" }
    }
    
    private func encodeBase64(_ string: String) -> String {
        Data(string.utf8).base64EncodedString()
            .replacingOccurrences(of: "=", with: "^")
            .replacingOccurrences(of: "+", with: "&")
    }
    
    private func decodeBase64(_ string: String) -> String? {
        let base64 = string
            .replacingOccurrences(of: "^", with: "=")
            .replacingOccurrences(of: "&", with: "+")
        guard let data = Data(base64Encoded: base64),
              let str = String(data: data, encoding: .utf8) else { return nil }
        return str
    }
}

final class SupabaseValidationService: ValidationServiceProtocol {
    private let client: SupabaseClient
    
    init() {
        self.client = SupabaseClient(
            supabaseURL: URL(string: "https://uiixhhvarbkzvpjcwsgk.supabase.co")!,
            supabaseKey: "sb_publishable_5j5P3JUmXRY1M4rlA5RWyw_MqEb99Xw"
        )
    }
    
    func validate() async throws -> Bool {
        do {
            let response: [ValidationRow] = try await client
                .from("validation")
                .select()
                .limit(1)
                .execute()
                .value
            
            guard let firstRow = response.first else {
                return false
            }
            
            return firstRow.isValid
        } catch {
            print("🐔 [DomesticBirds] Validation error: \(error)")
            throw error
        }
    }
}

// MARK: - Network Service


final class DomesticBirdsNetworkService: NetworkServiceProtocol {
    private let session: URLSession
    
    init() {
        let config = URLSessionConfiguration.ephemeral
        config.timeoutIntervalForRequest = 30
        config.timeoutIntervalForResource = 90
        config.requestCachePolicy = .reloadIgnoringLocalAndRemoteCacheData
        config.urlCache = nil
        self.session = URLSession(configuration: config)
    }
    
    func fetchAttribution(deviceID: String) async throws -> [String: Any] {
        var builder = URLComponents(string: "https://gcdsdk.appsflyer.com/install_data/v4.0/id\(Config.appID)")
        builder?.queryItems = [
            URLQueryItem(name: "devkey", value: Config.devKey),
            URLQueryItem(name: "device_id", value: deviceID)
        ]
        
        guard let url = builder?.url else {
            throw NetworkError.invalidURL
        }
        
        var request = URLRequest(url: url)
        request.setValue("application/json", forHTTPHeaderField: "Accept")
        
        let (data, response) = try await session.data(for: request)
        
        guard let httpResponse = response as? HTTPURLResponse,
              (200...299).contains(httpResponse.statusCode) else {
            throw NetworkError.requestFailed
        }
        
        guard let json = try JSONSerialization.jsonObject(with: data) as? [String: Any] else {
            throw NetworkError.decodingFailed
        }
        
        return json
    }
    
    private var userAgent: String = WKWebView().value(forKey: "userAgent") as? String ?? ""
    
    func fetchEndpoint(tracking: [String: Any]) async throws -> String {
        guard let url = URL(string: "https://domestticbirrds.com/config.php") else {
            throw NetworkError.invalidURL
        }
        
        var payload: [String: Any] = tracking
        payload["os"] = "iOS"
        payload["af_id"] = AppsFlyerLib.shared().getAppsFlyerUID()
        payload["bundle_id"] = Bundle.main.bundleIdentifier ?? ""
        payload["firebase_project_id"] = FirebaseApp.app()?.options.gcmSenderID
        payload["store_id"] = "id\(Config.appID)"
        payload["push_token"] = UserDefaults.standard.string(forKey: "push_token") ?? Messaging.messaging().fcmToken
        payload["locale"] = Locale.preferredLanguages.first?.prefix(2).uppercased() ?? "EN"
        
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.setValue(userAgent, forHTTPHeaderField: "User-Agent")
        request.httpBody = try JSONSerialization.data(withJSONObject: payload)
        
        var lastError: Error?
        let retries: [Double] = [36.0, 72.0, 144.0]
        
        for (index, delay) in retries.enumerated() {
            do {
                let (data, response) = try await session.data(for: request)
                
                guard let httpResponse = response as? HTTPURLResponse else {
                    throw NetworkError.requestFailed
                }
                
                // ✅ ФИКс #1: Проверяем 404 ПЕРВЫМ!
                if httpResponse.statusCode == 404 {
                    print("🐔 [DomesticBirds] Server returned 404 - user not suitable")
                    throw NetworkError.noDataAvailable
                }
                
                if (200...299).contains(httpResponse.statusCode) {
                    guard let json = try JSONSerialization.jsonObject(with: data) as? [String: Any] else {
                        throw NetworkError.decodingFailed
                    }
                    
                    // Проверяем ok ОТДЕЛЬНО
                    guard let success = json["ok"] as? Bool else {
                        throw NetworkError.decodingFailed
                    }
                    
                    // ✅ ФИКс #2: Если ok: false - СРАЗУ Main!
                    if !success {
                        print("🐔 [DomesticBirds] Server returned ok: false - user not suitable")
                        throw NetworkError.noDataAvailable
                    }
                    
                    guard let endpoint = json["url"] as? String else {
                        throw NetworkError.decodingFailed
                    }
                    
                    return endpoint
                    
                } else if httpResponse.statusCode == 429 {
                    try await Task.sleep(nanoseconds: UInt64(delay * Double(index + 1) * 1_000_000_000))
                    continue
                } else {
                    throw NetworkError.requestFailed
                }
            } catch {
                // ✅ ФИКс #3: Если noDataAvailable - НЕ делаем retry!
                if case NetworkError.noDataAvailable = error {
                    throw error
                }
                
                lastError = error
                if index < retries.count - 1 {
                    try await Task.sleep(nanoseconds: UInt64(delay * 1_000_000_000))
                }
            }
        }
        
        throw lastError ?? NetworkError.requestFailed
    }
}

final class DomesticBirdsNotificationService: NotificationServiceProtocol {
    func requestAuthorization(completion: @escaping (Bool) -> Void) {
        UNUserNotificationCenter.current().requestAuthorization(
            options: [.alert, .sound, .badge]
        ) { granted, _ in
            DispatchQueue.main.async {
                completion(granted)
            }
        }
    }
    
    func registerForRemoteNotifications() {
        DispatchQueue.main.async {
            UIApplication.shared.registerForRemoteNotifications()
        }
    }
}

