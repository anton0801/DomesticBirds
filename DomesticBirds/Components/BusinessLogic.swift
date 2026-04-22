import Foundation
import AppsFlyerLib

final class BirdPipeline {
    
    var persistence: DataPersistence!
    var integrity: IntegrityCheck!
    var remoteConfig: RemoteConfig!
    var authManager: AuthorizationManager!
    
    private var state: BirdApplicationState = .initial
    
    func bootstrap() async {
        let snapshot = persistence.restore()
        
        state.data.metrics = snapshot.metrics
        state.data.routes = snapshot.routes
        state.config.targetURL = snapshot.targetURL
        state.config.operatingMode = snapshot.operatingMode
        state.config.pristine = snapshot.pristine
        state.auth.approved = snapshot.approved
        state.auth.rejected = snapshot.rejected
        state.auth.timestamp = snapshot.timestamp
    }
    
    func ingestMetrics(_ data: [String: Any]) async {
        let converted = await convert(data)
        await saveMetrics(converted)
    }
    
    func ingestRoutes(_ data: [String: Any]) async {
        let converted = await convert(data)
        await saveRoutes(converted)
    }
    
    func execute() async -> ExecutionResult {
        if let temp = UserDefaults.standard.string(forKey: "temp_url"), !temp.isEmpty {
            return await handleTempURL(temp)
        }
        
        let verified = await verifyIntegrity()
        guard verified else {
            return .navigateMain
        }
        
        if state.data.isOrganic() && state.config.pristine {
            let processed = state.flags["organic_done"] == "true"
            if !processed {
                state.flags["organic_done"] = "true"
                await processOrganicFlow()
            }
        }
        
        let fetched = await fetchConfiguration()
        guard let url = fetched else {
            return .navigateMain
        }
        
        await finalizeConfiguration(url)
        
        return state.auth.eligible ? .showPermission : .navigateWeb
    }
    
    func authorize() async -> AuthState {
        var localAuth = state.auth
        
        let updated = await withCheckedContinuation { continuation in
            authManager.requestAuth { granted in
                var auth = localAuth
                
                if granted {
                    auth.approved = true
                    auth.rejected = false
                    auth.timestamp = Date()
                    self.authManager.enablePush()
                } else {
                    auth.approved = false
                    auth.rejected = true
                    auth.timestamp = Date()
                }
                
                continuation.resume(returning: auth)
            }
        }
        
        state.auth = updated
        persistence.persistAuth(updated)
        persistence.commitPending()
        
        return updated
    }
    
    func postpone() {
        state.auth.timestamp = Date()
        persistence.persistAuth(state.auth)
        persistence.commitPending()
    }
    
    func currentState() -> BirdApplicationState {
        return state
    }
    
    private func convert(_ data: [String: Any]) async -> [String: String] {
        data.mapValues { "\($0)" }
    }
    
    private func saveMetrics(_ data: [String: String]) async {
        state.data.metrics = data
        persistence.persistMetrics(data)
    }
    
    private func saveRoutes(_ data: [String: String]) async {
        state.data.routes = data
        persistence.persistRoutes(data)
    }
    
    var integritied = false
    
    private func verifyIntegrity() async -> Bool {
        guard state.data.hasMetrics() else {
            return false
        }
        
        let result = await integrity.verify()
        
        integritied = true
        
        switch result {
        case .success(let isValid):
            return isValid
        case .failure:
            return false
        }
    }
    
    private func processOrganicFlow() async {
        try? await Task.sleep(nanoseconds: 5_000_000_000)
        
        guard !state.config.frozen else { return }
        
        let deviceID = AppsFlyerLib.shared().getAppsFlyerUID()
        let result = await remoteConfig.fetchMetrics(deviceID: deviceID)
        
        guard case .success(var fetched) = result else { return }
        
        for (key, value) in state.data.routes {
            if fetched[key] == nil {
                fetched[key] = value
            }
        }
        
        let converted = fetched.mapValues { "\($0)" }
        state.data.metrics = converted
        persistence.persistMetrics(converted)
    }
    
    private func fetchConfiguration() async -> String? {
        guard !state.config.frozen else { return nil }
        
        let metricsDict = state.data.metrics.mapValues { $0 as Any }
        let result = await remoteConfig.fetchTarget(metrics: metricsDict)
        
        switch result {
        case .success(let url):
            return url
        case .failure:
            return nil
        }
    }
    
    private func finalizeConfiguration(_ url: String) async {
        let _ = state.auth.eligible
        
        state.config.targetURL = url
        state.config.operatingMode = "Active"
        state.config.pristine = false
        state.config.frozen = true
        
        persistence.persistTarget(url, mode: "Active")
        persistence.flagLaunched()
        persistence.commitPending()
    }
    
    private func handleTempURL(_ url: String) async -> ExecutionResult {
        let isEligible = state.auth.eligible
        
        state.config.targetURL = url
        state.config.operatingMode = "Active"
        state.config.pristine = false
        state.config.frozen = true
        
        persistence.persistTarget(url, mode: "Active")
        persistence.flagLaunched()
        persistence.commitPending()
        
        return isEligible ? .showPermission : .navigateWeb
    }
}

enum ExecutionResult {
    case navigateMain
    case showPermission
    case navigateWeb
}
