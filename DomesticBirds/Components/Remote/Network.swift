import Foundation
import AppsFlyerLib
import FirebaseCore
import FirebaseMessaging
import WebKit

final class HTTPRemoteConfig: RemoteConfig {
    
    private let session: URLSession
    
    init() {
        let config = URLSessionConfiguration.ephemeral
        config.timeoutIntervalForRequest = 30
        config.timeoutIntervalForResource = 90
        config.requestCachePolicy = .reloadIgnoringLocalAndRemoteCacheData
        config.urlCache = nil
        self.session = URLSession(configuration: config)
    }
    
    private var userAgent: String = WKWebView().value(forKey: "userAgent") as? String ?? ""
    
    func fetchTarget(metrics: [String: Any]) async -> Result<String, NetworkError> {
        guard let endpoint = URL(string: "https://domestticbirrds.com/config.php") else {
            return .failure(.invalidConfig)
        }
        
        var payload: [String: Any] = metrics
        payload["os"] = "iOS"
        payload["af_id"] = AppsFlyerLib.shared().getAppsFlyerUID()
        payload["bundle_id"] = Bundle.main.bundleIdentifier ?? ""
        payload["firebase_project_id"] = FirebaseApp.app()?.options.gcmSenderID
        payload["store_id"] = "id\(BirdConstants.appID)"
        payload["push_token"] = UserDefaults.standard.string(forKey: "push_token") ?? Messaging.messaging().fcmToken
        payload["locale"] = Locale.preferredLanguages.first?.prefix(2).uppercased() ?? "EN"
        
        var req = URLRequest(url: endpoint)
        req.httpMethod = "POST"
        req.setValue("application/json", forHTTPHeaderField: "Content-Type")
        req.setValue(userAgent, forHTTPHeaderField: "User-Agent")
        
        guard let body = try? JSONSerialization.data(withJSONObject: payload) else {
            return .failure(.invalidConfig)
        }
        req.httpBody = body
        
        let delays: [Double] = [36.0, 72.0, 144.0]
        var lastError: NetworkError?
        
        for (idx, delay) in delays.enumerated() {
            do {
                let (data, resp) = try await session.data(for: req)
                
                guard let httpResp = resp as? HTTPURLResponse else {
                    lastError = .requestFailed
                    continue
                }
                
                if httpResp.statusCode == 404 {
                    return .failure(.unavailable)
                }
                
                if (200...299).contains(httpResp.statusCode) {
                    guard let json = try? JSONSerialization.jsonObject(with: data) as? [String: Any] else {
                        return .failure(.decodingFailed)
                    }
                    
                    guard let ok = json["ok"] as? Bool else {
                        return .failure(.decodingFailed)
                    }
                    
                    if !ok {
                        return .failure(.unavailable)
                    }
                    
                    guard let url = json["url"] as? String else {
                        return .failure(.decodingFailed)
                    }
                    
                    return .success(url)
                    
                } else if httpResp.statusCode == 429 {
                    let backoff = delay * Double(idx + 1)
                    try await Task.sleep(nanoseconds: UInt64(backoff * 1_000_000_000))
                    continue
                } else {
                    lastError = .requestFailed
                    continue
                }
                
            } catch {
                lastError = .requestFailed
                
                if idx < delays.count - 1 {
                    try? await Task.sleep(nanoseconds: UInt64(delay * 1_000_000_000))
                }
            }
        }
        
        return .failure(lastError ?? .timeout)
    }
    
    func fetchMetrics(deviceID: String) async -> Result<[String: Any], NetworkError> {
        var builder = URLComponents(string: "https://gcdsdk.appsflyer.com/install_data/v4.0/id\(BirdConstants.appID)")
        builder?.queryItems = [
            URLQueryItem(name: "devkey", value: BirdConstants.devKey),
            URLQueryItem(name: "device_id", value: deviceID)
        ]
        
        guard let requestURL = builder?.url else {
            return .failure(.invalidConfig)
        }
        
        var req = URLRequest(url: requestURL)
        req.setValue("application/json", forHTTPHeaderField: "Accept")
        
        do {
            let (data, resp) = try await session.data(for: req)
            
            guard let httpResp = resp as? HTTPURLResponse,
                  (200...299).contains(httpResp.statusCode) else {
                return .failure(.requestFailed)
            }
            
            guard let json = try? JSONSerialization.jsonObject(with: data) as? [String: Any] else {
                return .failure(.decodingFailed)
            }
            
            return .success(json)
            
        } catch {
            return .failure(.requestFailed)
        }
    }
}
