import UIKit
import FirebaseCore
import FirebaseMessaging
import AppTrackingTransparency
import UserNotifications
import AppsFlyerLib

final class AppDelegate: UIResponder, UIApplicationDelegate {
    
    private let attributionManager = AttributionManager()
    private let pushManager = PushManager()
    private let sdkManager = SDKManager()
    
    func application(
        _ application: UIApplication,
        didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?
    ) -> Bool {
        
        attributionManager.onMetricsReceived = { [weak self] data in
            self?.relayMetrics(data)
        }
        
        attributionManager.onRoutesReceived = { [weak self] data in
            self?.relayRoutes(data)
        }
        
        setupFirebase()
        setupMessaging()
        sdkManager.configure(delegate: attributionManager)
        
        if let msgData = launchOptions?[.remoteNotification] as? [AnyHashable: Any] {
            pushManager.process(msgData)
        }
        
        observeLifecycle()
        
        return true
    }
    
    func application(
        _ application: UIApplication,
        didRegisterForRemoteNotificationsWithDeviceToken deviceToken: Data
    ) {
        Messaging.messaging().apnsToken = deviceToken
    }
    
    private func setupFirebase() {
        FirebaseApp.configure()
    }
    
    private func setupMessaging() {
        Messaging.messaging().delegate = self
        UNUserNotificationCenter.current().delegate = self
        UIApplication.shared.registerForRemoteNotifications()
    }
    
    private func observeLifecycle() {
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(onActivation),
            name: UIApplication.didBecomeActiveNotification,
            object: nil
        )
    }
    
    @objc private func onActivation() {
        sdkManager.start()
    }
    
    private func relayMetrics(_ data: [AnyHashable: Any]) {
        DispatchQueue.main.asyncAfter(deadline: .now() + 2.5) {
            NotificationCenter.default.post(
                name: .init("ConversionDataReceived"),
                object: nil,
                userInfo: ["conversionData": data]
            )
        }
    }
    
    private func relayRoutes(_ data: [AnyHashable: Any]) {
        NotificationCenter.default.post(
            name: .init("deeplink_values"),
            object: nil,
            userInfo: ["deeplinksData": data]
        )
    }
}

// MARK: - Messaging Delegate

extension AppDelegate: MessagingDelegate {
    func messaging(
        _ messaging: Messaging,
        didReceiveRegistrationToken fcmToken: String?
    ) {
        messaging.token { token, err in
            guard err == nil, let t = token else { return }
            
            UserDefaults.standard.set(t, forKey: "fcm_token")
            UserDefaults.standard.set(t, forKey: "push_token")
            UserDefaults(suiteName: "group.domesticbirds.app")?.set(t, forKey: "shared_fcm")
        }
    }
}

extension AppDelegate: UNUserNotificationCenterDelegate {
    func userNotificationCenter(
        _ center: UNUserNotificationCenter,
        willPresent notification: UNNotification,
        withCompletionHandler completionHandler: @escaping (UNNotificationPresentationOptions) -> Void
    ) {
        pushManager.process(notification.request.content.userInfo)
        completionHandler([.banner, .sound, .badge])
    }
    
    func userNotificationCenter(
        _ center: UNUserNotificationCenter,
        didReceive response: UNNotificationResponse,
        withCompletionHandler completionHandler: @escaping () -> Void
    ) {
        pushManager.process(response.notification.request.content.userInfo)
        completionHandler()
    }
    
    func application(
        _ application: UIApplication,
        didReceiveRemoteNotification userInfo: [AnyHashable: Any],
        fetchCompletionHandler completionHandler: @escaping (UIBackgroundFetchResult) -> Void
    ) {
        pushManager.process(userInfo)
        completionHandler(.newData)
    }
}

final class AttributionManager: NSObject {
    var onMetricsReceived: (([AnyHashable: Any]) -> Void)?
    var onRoutesReceived: (([AnyHashable: Any]) -> Void)?
    
    private var metricsBuffer: [AnyHashable: Any] = [:]
    private var routesBuffer: [AnyHashable: Any] = [:]
    private var mergeTimer: Timer?
    
    func receiveMetrics(_ data: [AnyHashable: Any]) {
        metricsBuffer = data
        scheduleMerge()
        
        if !routesBuffer.isEmpty {
            merge()
        }
    }
    
    func receiveRoutes(_ data: [AnyHashable: Any]) {
        guard !UserDefaults.standard.bool(forKey: "db_launch") else { return }
        
        routesBuffer = data
        onRoutesReceived?(data)
        mergeTimer?.invalidate()
        
        if !metricsBuffer.isEmpty {
            merge()
        }
    }
    
    private func scheduleMerge() {
        mergeTimer?.invalidate()
        mergeTimer = Timer.scheduledTimer(
            withTimeInterval: 2.5,
            repeats: false
        ) { [weak self] _ in
            self?.merge()
        }
    }
    
    private func merge() {
        var result = metricsBuffer
        
        for (k, v) in routesBuffer {
            let key = "deep_\(k)"
            if result[key] == nil {
                result[key] = v
            }
        }
        
        onMetricsReceived?(result)
    }
}

final class SDKManager: NSObject, AppsFlyerLibDelegate, DeepLinkDelegate {
    
    private weak var delegate: AttributionManager?
    
    func configure(delegate: AttributionManager) {
        self.delegate = delegate
        
        let sdk = AppsFlyerLib.shared()
        sdk.appsFlyerDevKey = BirdConstants.devKey
        sdk.appleAppID = BirdConstants.appID
        sdk.delegate = self
        sdk.deepLinkDelegate = self
        sdk.isDebug = false
    }
    
    func start() {
        if #available(iOS 14, *) {
            AppsFlyerLib.shared().waitForATTUserAuthorization(timeoutInterval: 60)
            
            ATTrackingManager.requestTrackingAuthorization { status in
                DispatchQueue.main.async {
                    AppsFlyerLib.shared().start()
                    UserDefaults.standard.set(status.rawValue, forKey: "att_status")
                }
            }
        } else {
            AppsFlyerLib.shared().start()
        }
    }
    
    // MARK: - AppsFlyer Delegate
    
    func onConversionDataSuccess(_ data: [AnyHashable: Any]) {
        delegate?.receiveMetrics(data)
    }
    
    func onConversionDataFail(_ error: Error) {
        let errorData: [AnyHashable: Any] = [
            "error": true,
            "error_desc": error.localizedDescription
        ]
        delegate?.receiveMetrics(errorData)
    }
    
    func didResolveDeepLink(_ result: DeepLinkResult) {
        guard case .found = result.status,
              let link = result.deepLink else { return }
        
        delegate?.receiveRoutes(link.clickEvent)
    }
}
