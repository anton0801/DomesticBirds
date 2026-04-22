import Foundation
import AppsFlyerLib

final class DomesticBirdsCQRSHandler {
    // Write Model - для Commands
    private var writeModel: DomesticBirdsWriteModel = .initial
    
    // Services
    private let storage: StorageServiceProtocol
    private let validation: ValidationServiceProtocol
    private let network: NetworkServiceProtocol
    private let notification: NotificationServiceProtocol
    
    init(
        storage: StorageServiceProtocol,
        validation: ValidationServiceProtocol,
        network: NetworkServiceProtocol,
        notification: NotificationServiceProtocol
    ) {
        self.storage = storage
        self.validation = validation
        self.network = network
        self.notification = notification
    }
    
    // MARK: - Commands (Write Operations)
    
    func execute(_ command: AppCommand) async throws {
        switch command {
        case .initialize:
            await executeInitialize()
            
        case .recordTracking(let data):
            executeRecordTracking(data)
            
        case .recordNavigation(let data):
            executeRecordNavigation(data)
            
        case .validateAndExecute:
            try await executeValidateAndExecute()
            
        case .grantPermission:
            await executeGrantPermission()
            
        case .declinePermission:
            executeDeclinePermission()
        }
    }
    
    // MARK: - Queries (Read Operations)
    
    func query(_ query: AppQuery) -> Any {
        // Convert WriteModel to ReadModel for queries
        let readModel = writeModel.toReadModel()
        
        switch query {
        case .getCurrentState:
            return readModel
            
        case .canRequestPermission:
            return readModel.permission.canRequest
            
        case .shouldNavigateToMain:
            return !readModel.hasTracking() || readModel.isLocked
            
        case .shouldNavigateToWeb:
            return readModel.endpoint != nil && readModel.isLocked
            
        case .shouldShowPermissionPrompt:
            return readModel.permission.canRequest && !readModel.isLocked
            
        case .isNetworkAvailable:
            return true // Placeholder
        }
    }
    
    // MARK: - Command Implementations
    
    private func executeInitialize() async {
        let stored = storage.load()
        writeModel.tracking = stored.tracking
        writeModel.navigation = stored.navigation
        writeModel.mode = stored.mode
        writeModel.isFirstLaunch = stored.isFirstLaunch
        writeModel.permission = DomesticBirdsWriteModel.PermissionWriteModel(
            isGranted: stored.permission.isGranted,
            isDenied: stored.permission.isDenied,
            lastAsked: stored.permission.lastAsked
        )
    }
    
    private func executeRecordTracking(_ data: [String: Any]) {
        let converted = data.mapValues { "\($0)" }
        writeModel.tracking = converted
        storage.save(tracking: converted)
    }
    
    private func executeRecordNavigation(_ data: [String: Any]) {
        let converted = data.mapValues { "\($0)" }
        writeModel.navigation = converted
        storage.save(navigation: converted)
    }
    
    private func executeValidateAndExecute() async throws {
        guard writeModel.hasTracking() else {
            throw CQRSError.validationFailed
        }
        
        // Validate
        let isValid = try await validation.validate()
        guard isValid else {
            throw CQRSError.validationFailed
        }
        
        // Execute business logic
        try await executeBusinessLogic()
    }
    
    private func executeBusinessLogic() async throws {
        guard !writeModel.isLocked, writeModel.hasTracking() else {
            throw CQRSError.notFound
        }
        
        if let temp = UserDefaults.standard.string(forKey: "temp_url"), !temp.isEmpty {
            writeModel.endpoint = temp
            writeModel.mode = "Active"
            writeModel.isFirstLaunch = false
            writeModel.isLocked = true
            
            storage.save(endpoint: temp)
            storage.save(mode: "Active")
            storage.markAsLaunched()
            
            return
        }
        
        // Organic flow
        let attributionProcessed = writeModel.metadata["attribution_processed"] == "true"
        if writeModel.isOrganic() && writeModel.isFirstLaunch && !attributionProcessed {
            writeModel.metadata["attribution_processed"] = "true"
            try await executeOrganicFlow()
        }
        
        let trackingDict = writeModel.tracking.mapValues { $0 as Any }
        let url = try await network.fetchEndpoint(tracking: trackingDict)
        
        writeModel.endpoint = url
        writeModel.mode = "Active"
        writeModel.isFirstLaunch = false
        writeModel.isLocked = true
        
        storage.save(endpoint: url)
        storage.save(mode: "Active")
        storage.markAsLaunched()
    }
    
    private func executeOrganicFlow() async throws {
        try? await Task.sleep(nanoseconds: 5_000_000_000)
        
        guard !writeModel.isLocked else { return }
        
        let deviceID = AppsFlyerLib.shared().getAppsFlyerUID()
        var fetched = try await network.fetchAttribution(deviceID: deviceID)
        
        for (key, value) in writeModel.navigation {
            if fetched[key] == nil {
                fetched[key] = value
            }
        }
        
        let converted = fetched.mapValues { "\($0)" }
        writeModel.tracking = converted
        storage.save(tracking: converted)
    }
    
    private func executeGrantPermission() async {
        var localPerm = writeModel.permission
        
        let updatedPermission = await withCheckedContinuation {
            (continuation: CheckedContinuation<DomesticBirdsWriteModel.PermissionWriteModel, Never>) in
            
            notification.requestAuthorization { granted in
                var perm = localPerm
                
                if granted {
                    perm.isGranted = true
                    perm.isDenied = false
                    perm.lastAsked = Date()
                    self.notification.registerForRemoteNotifications()
                } else {
                    perm.isGranted = false
                    perm.isDenied = true
                    perm.lastAsked = Date()
                }
                
                continuation.resume(returning: perm)
            }
        }
        
        writeModel.permission = updatedPermission
        storage.save(permission: updatedPermission)
    }
    
    private func executeDeclinePermission() {
        writeModel.permission.lastAsked = Date()
        storage.save(permission: writeModel.permission)
    }
}

extension DomesticBirdsWriteModel.PermissionWriteModel {
    var canRequest: Bool {
        guard !isGranted && !isDenied else { return false }
        if let date = lastAsked {
            return Date().timeIntervalSince(date) / 86400 >= 3
        }
        return true
    }
}
