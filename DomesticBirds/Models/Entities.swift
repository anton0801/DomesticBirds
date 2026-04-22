import Foundation

struct DataState {
    var metrics: [String: String]
    var routes: [String: String]
    
    static var empty: DataState {
        DataState(metrics: [:], routes: [:])
    }
    
    func hasMetrics() -> Bool {
        !metrics.isEmpty
    }
    
    func isOrganic() -> Bool {
        metrics["af_status"] == "Organic"
    }
}

struct ConfigState {
    var targetURL: String?
    var operatingMode: String?
    var pristine: Bool
    var frozen: Bool
    
    static var initial: ConfigState {
        ConfigState(
            targetURL: nil,
            operatingMode: nil,
            pristine: true,
            frozen: false
        )
    }
}

struct AuthState {
    var approved: Bool
    var rejected: Bool
    var timestamp: Date?
    
    static var initial: AuthState {
        AuthState(
            approved: false,
            rejected: false,
            timestamp: nil
        )
    }
    
    var eligible: Bool {
        guard !approved && !rejected else { return false }
        
        if let date = timestamp {
            let daysPassed = Date().timeIntervalSince(date) / 86400
            return daysPassed >= 3
        }
        
        return true
    }
}

// MARK: - Composite State

struct BirdApplicationState {
    var data: DataState
    var config: ConfigState
    var auth: AuthState
    var flags: [String: String]
    
    static var initial: BirdApplicationState {
        BirdApplicationState(
            data: .empty,
            config: .initial,
            auth: .initial,
            flags: [:]
        )
    }
}

// MARK: - Restored Snapshot

struct RestoredSnapshot {
    let metrics: [String: String]
    let routes: [String: String]
    let targetURL: String?
    let operatingMode: String?
    let pristine: Bool
    let approved: Bool
    let rejected: Bool
    let timestamp: Date?
}
