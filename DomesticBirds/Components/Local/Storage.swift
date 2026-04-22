import Foundation

final class BatchedStorage: DataPersistence {
    
    private let suite: UserDefaults
    private let fallback: UserDefaults
    private var pendingWrites: [String: Any] = [:]
    
    init() {
        self.suite = UserDefaults(suiteName: "group.domesticbirds.app")!
        self.fallback = UserDefaults.standard
    }
    
    private struct Keys {
        static let metrics = "db_metrics"
        static let routes = "db_routes"
        static let target = "db_target"
        static let mode = "db_mode"
        static let launch = "db_launch"
        static let authApproved = "db_auth_ok"
        static let authRejected = "db_auth_no"
        static let authTime = "db_auth_ts"
    }

    func persistMetrics(_ data: [String: String]) {
        if let packed = pack(data) {
            pendingWrites[Keys.metrics] = packed
        }
    }
    
    func persistRoutes(_ data: [String: String]) {
        if let packed = pack(data) {
            let encoded = customEncode(packed)
            pendingWrites[Keys.routes] = encoded
        }
    }
    
    func persistTarget(_ url: String, mode: String) {
        pendingWrites[Keys.target] = url
        pendingWrites[Keys.mode] = mode
    }
    
    func persistAuth(_ auth: AuthState) {
        pendingWrites[Keys.authApproved] = auth.approved
        pendingWrites[Keys.authRejected] = auth.rejected
        if let date = auth.timestamp {
            let ms = date.timeIntervalSince1970 * 1000
            pendingWrites[Keys.authTime] = ms
        }
    }
    
    func flagLaunched() {
        pendingWrites[Keys.launch] = true
    }
    
    func commitPending() {
        pendingWrites.forEach { key, value in
            suite.set(value, forKey: key)
            
            if key == Keys.target {
                fallback.set(value, forKey: key)
            }
        }
        pendingWrites.removeAll()
    }
    
    func restore() -> RestoredSnapshot {
        let metricsPacked = suite.string(forKey: Keys.metrics) ?? ""
        let metrics = unpack(metricsPacked) ?? [:]
        
        let routesEncoded = suite.string(forKey: Keys.routes) ?? ""
        let routesPacked = customDecode(routesEncoded) ?? ""
        let routes = unpack(routesPacked) ?? [:]
        
        let target = suite.string(forKey: Keys.target)
        let mode = suite.string(forKey: Keys.mode)
        let launched = suite.bool(forKey: Keys.launch)
        
        let approved = suite.bool(forKey: Keys.authApproved)
        let rejected = suite.bool(forKey: Keys.authRejected)
        let timeMs = suite.double(forKey: Keys.authTime)
        let timestamp = timeMs > 0 ? Date(timeIntervalSince1970: timeMs / 1000) : nil
        
        return RestoredSnapshot(
            metrics: metrics,
            routes: routes,
            targetURL: target,
            operatingMode: mode,
            pristine: !launched,
            approved: approved,
            rejected: rejected,
            timestamp: timestamp
        )
    }
    
    private func pack(_ dict: [String: String]) -> String? {
        let anyDict = dict.mapValues { $0 as Any }
        guard let data = try? JSONSerialization.data(withJSONObject: anyDict),
              let text = String(data: data, encoding: .utf8) else {
            return nil
        }
        return text
    }
    
    private func unpack(_ text: String) -> [String: String]? {
        guard let data = text.data(using: .utf8),
              let anyDict = try? JSONSerialization.jsonObject(with: data) as? [String: Any] else {
            return nil
        }
        return anyDict.mapValues { "\($0)" }
    }
    
    private func customEncode(_ input: String) -> String {
        let base64 = Data(input.utf8).base64EncodedString()
        return base64
            .replacingOccurrences(of: "=", with: "^")
            .replacingOccurrences(of: "+", with: "&")
    }
    
    private func customDecode(_ encoded: String) -> String? {
        let base64 = encoded
            .replacingOccurrences(of: "^", with: "=")
            .replacingOccurrences(of: "&", with: "+")
        
        guard let data = Data(base64Encoded: base64),
              let decoded = String(data: data, encoding: .utf8) else {
            return nil
        }
        return decoded
    }
}
