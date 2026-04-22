import Foundation

protocol DataPersistence {
    func persistMetrics(_ data: [String: String])
    func persistRoutes(_ data: [String: String])
    func persistTarget(_ url: String, mode: String)
    func persistAuth(_ auth: AuthState)
    func flagLaunched()
    func restore() -> RestoredSnapshot
    func commitPending()
}

protocol IntegrityCheck {
    func verify() async -> Result<Bool, ValidationError>
}

protocol RemoteConfig {
    func fetchTarget(metrics: [String: Any]) async -> Result<String, NetworkError>
    func fetchMetrics(deviceID: String) async -> Result<[String: Any], NetworkError>
}

protocol AuthorizationManager {
    func requestAuth(completion: @escaping (Bool) -> Void)
    func enablePush()
}

enum ValidationError: Error {
    case checkFailed
    case connectionIssue
    case timeout
}

enum NetworkError: Error {
    case invalidConfig
    case requestFailed
    case decodingFailed
    case unavailable
    case timeout
}
