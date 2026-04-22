import Foundation

protocol StorageServiceProtocol {
    func save(tracking: [String: String])
    func save(navigation: [String: String])
    func save(endpoint: String)
    func save(mode: String)
    func save(permission: DomesticBirdsWriteModel.PermissionWriteModel)
    func markAsLaunched()
    func load() -> StorageModel
}

protocol ValidationServiceProtocol {
    func validate() async throws -> Bool
}

protocol NetworkServiceProtocol {
    func fetchAttribution(deviceID: String) async throws -> [String: Any]
    func fetchEndpoint(tracking: [String: Any]) async throws -> String
}

protocol NotificationServiceProtocol {
    func requestAuthorization(completion: @escaping (Bool) -> Void)
    func registerForRemoteNotifications()
}
