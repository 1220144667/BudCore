//
//  SharedUtils.swift
//  BudChatDB
//
//  Copyright © 2020-2022 BudChat. All reserved.
//

import Foundation
import Photos
import SwiftKeychainWrapper
import UIKit

public enum SharedUtils {
    public static let kNotificationBrandingSmallIconAvailable = "BrandingSmallIconAvailable"
    public static let kNotificationBrandingConfigAvailable = "BrandingConfigAvailable"

    public static let kChatMetaVersion = "tinodeMetaVersion"

    public static let kChatPrefLastLogin = "tinodeLastLogin"
    public static let kChatPrefReadReceipts = "tinodePrefSendReadReceipts"
    public static let kChatPrefTypingNotifications = "tinodePrefTypingNoficications"
    public static let kChatPrefAppLaunchedBefore = "tinodePrefAppLaunchedBefore"
    public static let kChatPrefAppLaunchedPrivacyAgree = "tinodePrefAppLaunchedPrivacyAgree"

    public static let kChatPrefTosUrl = "tinodePrefTosUrl"
    public static let kChatPrefServiceName = "tinodePrefServiceName"
    public static let kChatPrefPrivacyUrl = "tinodePrefPrivacyUrl"
    public static let kChatPrefAppId = "tinodePrefAppId"
    public static let kLoginAccount = "tinodeLoginAccount"
    public static let kChatPrefSmallIcon = "tinodePrefSmallIcon"
    public static let kChatPrefLargeIcon = "tinodePrefLargeIcon"

    public static let kBudchatContactsNew = "BudchatContactsNew"
    public static let kBudchatContactsNewCount = "BudchatContactsNewCount"

    public static let kMommentsNotice = "MommentsNotice"
    // App Tinode api key.
    public static let kApiKey = "AQAAAAABAADoRhZSEBNwFfKMM793mE8p"

    public static let kAppDefaults = UserDefaults(suiteName: BaseDb.kAppGroupId)!
    static let kAppKeychain = KeychainWrapper(serviceName: "co.tinode.tinodios", accessGroup: BaseDb.kAppGroupId)

    // Keys we store in keychain.
    static let kTokenKey = "co.tinode.token"
    static let kTokenExpiryKey = "co.tinode.token_expiry"
    // add user id key. daxiong 2024-02-01
    static let kUserId = "co.tinode.userId"

    // Application metadata version.
    // Bump it up whenever you change the application metadata and
    // want to force the user to re-login when the user installs
    // this new application version.
    static let kAppMetaVersion = 1

    // Default connection params.
    #if DEBUG
//    public static let kHostName = "192.168.8.88:6060" // localhost
        public static let kHostName = "124.221.76.28:6060" // localhost
//    public static let kHostName = "13.246.50.32:6060" // localhost
//    public static let kHostName = "18.135.117.190:5050" // localhost
//    public static let kHostName = "botim.n-chat.com.ng" // localhost
        public static let kUseTLS = false
    #else
//        public static let kHostName = "api.tinode.co" // production cluster
//        public static let kUseTLS = true

//    public static let kHostName = "124.221.76.28:6060" // localhost
//    public static let kHostName = "13.246.50.32:6060" // localhost
//    public static let kHostName = "18.135.117.190:5050" // localhost
        public static let kHostName = "botim.n-chat.com.ng" // localhost
        public static let kUseTLS = true

    #endif

    // Returns true if the app is being launched for the first time.
    public static var isFirstLaunch: Bool {
        get {
            return !SharedUtils.kAppDefaults.bool(forKey: SharedUtils.kChatPrefAppLaunchedBefore)
        }
        set {
            SharedUtils.kAppDefaults.set(!newValue, forKey: SharedUtils.kChatPrefAppLaunchedBefore)
        }
    }

    public static var isPrivacyAgree: Bool {
        get {
            return SharedUtils.kAppDefaults.bool(forKey: SharedUtils.kChatPrefAppLaunchedPrivacyAgree)
        }
        set {
            SharedUtils.kAppDefaults.set(newValue, forKey: SharedUtils.kChatPrefAppLaunchedPrivacyAgree)
        }
    }

    // App TOS url string.
    public static var tosUrl: String? {
        get {
            return SharedUtils.kAppDefaults.string(forKey: SharedUtils.kChatPrefTosUrl)
        }
        set {
            SharedUtils.kAppDefaults.set(newValue, forKey: SharedUtils.kChatPrefTosUrl)
        }
    }

    // Application service name.
    public static var serviceName: String? {
        get {
            return SharedUtils.kAppDefaults.string(forKey: SharedUtils.kChatPrefServiceName)
        }
        set {
            SharedUtils.kAppDefaults.set(newValue, forKey: SharedUtils.kChatPrefServiceName)
        }
    }

    // Application privacy policy url.
    public static var privacyUrl: String? {
        get {
            return SharedUtils.kAppDefaults.string(forKey: SharedUtils.kChatPrefPrivacyUrl)
        }
        set {
            SharedUtils.kAppDefaults.set(newValue, forKey: SharedUtils.kChatPrefPrivacyUrl)
        }
    }

    // App's registration id in Tinode console.
    public static var appId: String? {
        get {
            return SharedUtils.kAppDefaults.string(forKey: SharedUtils.kChatPrefAppId)
        }
        set {
            SharedUtils.kAppDefaults.set(newValue, forKey: SharedUtils.kChatPrefAppId)
        }
    }

    public static var phoneNumber: String? {
        get {
            return SharedUtils.kAppDefaults.string(forKey: SharedUtils.kLoginAccount)
        }
        set {
            SharedUtils.kAppDefaults.set(newValue, forKey: SharedUtils.kLoginAccount)
        }
    }

    // Apps' small icon.
    public static var smallIcon: UIImage? {
        get {
            if let data = SharedUtils.kAppDefaults.object(forKey: SharedUtils.kChatPrefSmallIcon) as? Data {
                return UIImage(data: data)
            }
            return nil
        }
        set {
            SharedUtils.kAppDefaults.set(newValue?.pngData(), forKey: SharedUtils.kChatPrefSmallIcon)
        }
    }

    // Apps' large icon.
    public static var largeIcon: UIImage? {
        get {
            if let data = SharedUtils.kAppDefaults.object(forKey: SharedUtils.kChatPrefLargeIcon) as? Data {
                return UIImage(data: data)
            }
            return nil
        }
        set {
            SharedUtils.kAppDefaults.set(newValue?.pngData(), forKey: SharedUtils.kChatPrefLargeIcon)
        }
    }

    // ContactsNew
    public static var contactsNew: String? {
        get {
            return SharedUtils.kAppDefaults.object(forKey: SharedUtils.kBudchatContactsNew) as? String
        }
        set {
            SharedUtils.kAppDefaults.set(newValue, forKey: SharedUtils.kBudchatContactsNew)
        }
    }

    // ContactsNewCount
    public static var contactsNewCount: String? {
        get {
            return SharedUtils.kAppDefaults.object(forKey: SharedUtils.kBudchatContactsNewCount) as? String
        }
        set {
            SharedUtils.kAppDefaults.set(newValue, forKey: SharedUtils.kBudchatContactsNewCount)
        }
    }

    // momentsCount
    public static var momentsNoticeCount: Int {
        get {
            return (SharedUtils.kAppDefaults.object(forKey: SharedUtils.kMommentsNotice) as? Int) ?? 0
        }
        set {
            SharedUtils.kAppDefaults.set(newValue, forKey: SharedUtils.kMommentsNotice)
        }
    }

    // Apps' large icon.
    public static func setVideoCover(cover: UIImageView, _ url: String?) {
        guard let path = url else { return }
        if let data = SharedUtils.kAppDefaults.object(forKey: path) as? Data {
            cover.image = UIImage(data: data)
            return
        }
        path.fetchVideoPreviewImage { image in
            SharedUtils.kAppDefaults.set(image.pngData(), forKey: path)
            cover.image = image
        }
    }

    public static func getSavedLoginUserName() -> String? {
        return SharedUtils.kAppDefaults.string(forKey: SharedUtils.kChatPrefLastLogin)
    }

    private static func appMetaVersionUpToDate() -> Bool {
        let v = SharedUtils.kAppDefaults.integer(forKey: SharedUtils.kChatMetaVersion)
        guard v == SharedUtils.kAppMetaVersion else {
            BaseDb.log.error("App meta version does not match. Saved [%d] vs current [%d]", v, SharedUtils.kAppMetaVersion)
            // Clear the app keychain.
            SharedUtils.kAppKeychain.removeAllKeys()
            SharedUtils.kAppDefaults.set(SharedUtils.kAppMetaVersion, forKey: SharedUtils.kChatMetaVersion)
            return false
        }
        return true
    }

    /**
     * 从缓存获取鉴权用户ID
     * daxiong 2024-02-01.
     *
     * @return 鉴权用户ID
     */
    public static func getAuthUserId() -> String? {
        guard SharedUtils.appMetaVersionUpToDate() else { return nil }
        return SharedUtils.kAppKeychain.string(forKey: SharedUtils.kUserId, withAccessibility: .afterFirstUnlock)
    }

    public static func getAuthToken() -> String? {
        guard SharedUtils.appMetaVersionUpToDate() else { return nil }
        return SharedUtils.kAppKeychain.string(
            forKey: SharedUtils.kTokenKey, withAccessibility: .afterFirstUnlock
        )
    }

    public static func getAuthTokenExpiryDate() -> Date? {
        guard let expString = SharedUtils.kAppKeychain.string(
            forKey: SharedUtils.kTokenExpiryKey, withAccessibility: .afterFirstUnlock
        ) else { return nil }
        return Formatter.rfc3339.date(from: expString)
    }

    public static func removeAuthToken() {
        SharedUtils.kAppDefaults.removeObject(forKey: SharedUtils.kChatPrefLastLogin)
        SharedUtils.kAppKeychain.removeAllKeys()
    }

    public static func saveAuthToken(for userName: String, token: String?, expires expiryDate: Date?) {
        SharedUtils.kAppDefaults.set(userName, forKey: SharedUtils.kChatPrefLastLogin)
        if let token = token, !token.isEmpty {
            if !SharedUtils.kAppKeychain.set(token, forKey: SharedUtils.kTokenKey, withAccessibility: .afterFirstUnlock) {
                BaseDb.log.error("Could not save auth token")
            }

            if !SharedUtils.kAppKeychain.set(token, forKey: SharedUtils.kTokenKey, withAccessibility: .afterFirstUnlock) {
                BaseDb.log.error("Could not save auth token")
            }

            if let expiryDate = expiryDate {
                SharedUtils.kAppKeychain.set(
                    Formatter.rfc3339.string(from: expiryDate),
                    forKey: SharedUtils.kTokenExpiryKey,
                    withAccessibility: .afterFirstUnlock
                )
            } else {
                SharedUtils.kAppKeychain.removeObject(forKey: SharedUtils.kTokenExpiryKey)
            }
        }
    }

    /**
     * 缓存用户鉴权Token及用户ID
     * daxiong 2024-02-01.
     *
     * @param userName 用户名
     * @param token 鉴权Token
     * @param userId 用户ID
     * @param expiryDate 过期时间
     */
    public static func saveAuthToken(for userName: String, token: String?, userId: String?, expires expiryDate: Date?) {
        SharedUtils.kAppDefaults.set(userName, forKey: SharedUtils.kChatPrefLastLogin)
        if let token = token, !token.isEmpty {
            if !SharedUtils.kAppKeychain.set(token, forKey: SharedUtils.kTokenKey, withAccessibility: .afterFirstUnlock) {
                BaseDb.log.error("Could not save auth token")
            }

            if let userId = userId, !userId.isEmpty {
                if !SharedUtils.kAppKeychain.set(userId, forKey: SharedUtils.kUserId, withAccessibility: .afterFirstUnlock) {
                    BaseDb.log.error("Could not save auth user id")
                }
            }

            if let expiryDate = expiryDate {
                SharedUtils.kAppKeychain.set(
                    Formatter.rfc3339.string(from: expiryDate),
                    forKey: SharedUtils.kTokenExpiryKey,
                    withAccessibility: .afterFirstUnlock
                )
            } else {
                SharedUtils.kAppKeychain.removeObject(forKey: SharedUtils.kTokenExpiryKey)
            }
        }
    }

    /// Creates a Tinode instance backed by the local starage.
    public static func createTinode() -> BudChat {
        let appVersion: String = Bundle.main.object(forInfoDictionaryKey: "CFBundleVersion") as! String
        let appName = "Tinodios/" + appVersion
        let dbh = BaseDb.sharedInstance
        // FIXME: Get and use current UI language from Bundle.main.preferredLocalizations.first
        let tinode = BudChat(for: appName,
                             authenticateWith: SharedUtils.kApiKey,
                             persistDataIn: dbh.sqlStore)
        // add log. daxiong 2024-02-01
        print("==multi-user database get tinode: \(dbh.getDbPath())")
        if let store = dbh.sqlStore {
            print("==multi-user database get tinode: store had set \(store.myId)")
        } else {
            print("==multi-user database get tinode:  store not set")
        }

        tinode.OsVersion = UIDevice.current.systemVersion
        return tinode
    }

    public static func registerUserDefaults() {
        /// Here you can give default values to your UserDefault keys
        SharedUtils.kAppDefaults.register(defaults: [
            SharedUtils.kChatPrefReadReceipts: true,
            SharedUtils.kChatPrefTypingNotifications: true,
        ])

        let (hostName, _, _) = ConnectionSettingsHelper.getConnectionSettings()
        if hostName == nil {
            // If hostname is nil, sync values to defaults
            ConnectionSettingsHelper.setHostName(Bundle.main.object(forInfoDictionaryKey: "HOST_NAME") as? String)
            ConnectionSettingsHelper.setUseTLS(Bundle.main.object(forInfoDictionaryKey: "USE_TLS") as? String)
        }
        if !SharedUtils.appMetaVersionUpToDate() {
            BaseDb.log.info("App started for the first time.")
        }
    }

    public static func connectAndLoginSync(using tinode: BudChat, inBackground bkg: Bool) -> Bool {
        guard let userName = SharedUtils.getSavedLoginUserName(), !userName.isEmpty else {
            BaseDb.log.error("Connect&Login Sync - missing user name")
            return false
        }
        guard let token = SharedUtils.getAuthToken(), !token.isEmpty else {
            BaseDb.log.error("Connect&Login Sync - missing auth token")
            return false
        }
        if let tokenExpires = SharedUtils.getAuthTokenExpiryDate(), tokenExpires < Date() {
            // Token has expired.
            // TODO: treat tokenExpires == nil as a reason to reject.
            BaseDb.log.error("Connect&Login Sync - auth token expired")
            return false
        }
        BaseDb.log.info("Connect&Login Sync - will attempt to login (user name: %@)", userName)
        var success = false
        do {
            tinode.setAutoLoginWithToken(token: token)
            // Tinode.connect() will automatically log in.
            let msg = try tinode.connectDefault(inBackground: bkg)?.getResult()
            if let ctrl = msg?.ctrl {
                // Assuming success by default.
                success = true
                switch ctrl.code {
                case 0 ..< 300:
                    guard let myUid = ctrl.getStringParam(for: "user") else { return false }
                    BaseDb.log.info("Connect&Login Sync - login successful for: %@", myUid)
                    if tinode.authToken != token {
                        // 缓存用户鉴权Token及用户ID. daxiong 2024-02-01
                        SharedUtils.saveAuthToken(for: userName, token: tinode.authToken, userId: myUid, expires: tinode.authTokenExpires)
                    }
                case 401:
                    BaseDb.log.info("Connect&Login Sync - attempt to subscribe to 'me' before login.")
                case 409:
                    BaseDb.log.info("Connect&Login Sync - already authenticated.")
                case 500 ..< 600:
                    BaseDb.log.error("Connect&Login Sync - server error on login: %d", ctrl.code)
                default:
                    success = false
                }
            }
        } catch let WebSocketError.network(err) {
            // No network connection.
            BaseDb.log.debug("Connect&Login Sync [network] - could not connect to Tinode: %@", err)
            success = true
        } catch {
            let err = error as NSError
            if err.code == NSURLErrorCannotConnectToHost {
                BaseDb.log.debug("Connect&Login Sync [network] - could not connect to Tinode: %@", err)
                success = true
            } else {
                BaseDb.log.error("Connect&Login Sync - failed to automatically login to Tinode: %@", error.localizedDescription)
            }
        }
        return success
    }

    // Synchronously fetches description for topic |topicName|
    // (and saves the description locally).
    @discardableResult
    public static func fetchDesc(using tinode: BudChat, for topicName: String) -> UIBackgroundFetchResult {
        guard tinode.isConnectionAuthenticated || SharedUtils.connectAndLoginSync(using: tinode, inBackground: true) else {
            return .failed
        }
        // If we have topic data, we are done.
        guard !tinode.isTopicTracked(topicName: topicName) else {
            return .noData
        }
        do {
            if let msg = try tinode.getMeta(topic: topicName, query: MsgGetMeta.desc()).getResult(),
               (msg.ctrl?.code ?? 500) < 300
            {
                return .newData
            }
        } catch {
            BaseDb.log.error("Failed to fetch topic description for [%@]: %@", topicName, error.localizedDescription)
        }
        return .failed
    }

    // Synchronously connects to topic |topicName| and fetches its messages
    // if the last received message was prior to |seq|.
    @discardableResult
    public static func fetchData(using tinode: BudChat, for topicName: String, seq: Int, keepConnection: Bool) -> UIBackgroundFetchResult {
        guard tinode.isConnectionAuthenticated || SharedUtils.connectAndLoginSync(using: tinode, inBackground: true) else {
            return .failed
        }
        var topic: DefaultComTopic
        var builder: DefaultComTopic.MetaGetBuilder
        if !tinode.isTopicTracked(topicName: topicName) {
            // New topic. Create it.
            guard let t = tinode.newTopic(for: topicName) as? DefaultComTopic else {
                return .failed
            }
            topic = t
            builder = topic.metaGetBuilder().withDesc().withSub()
        } else {
            // Existing topic.
            guard let t = tinode.getTopic(topicName: topicName) as? DefaultComTopic else { return .failed }
            topic = t
            builder = topic.metaGetBuilder()
        }

        guard !topic.attached else {
            // No need to fetch: topic is already subscribed and got data through normal channel.
            return .noData
        }
        if (topic.recv ?? 0) >= seq {
            return .noData
        }

        // 确保在用户通过鉴权后再获取数据，需要做等待处理. daxiong 2024-02-02
        for i in 1 ... 10 {
            print("sleep try：\(i)")
            if !tinode.isConnectionAuthenticated {
                DispatchQueue.main.asyncAfter(deadline: .now() + .seconds(1)) {
                    // no operate, wait 1 second
                }
            }
        }

        if let msg = try? topic.subscribe(set: nil, get: builder.withLaterData(limit: 10).withDel().build()).getResult(), (msg.ctrl?.code ?? 500) < 300 {
            if !keepConnection {
                // Data messages are sent asynchronously right after ctrl message.
                // Give them 1 second to arrive - so we reply back with {note recv}.
                DispatchQueue.main.asyncAfter(deadline: .now() + .seconds(1)) {
                    if topic.attached {
                        topic.leave()
                    }
                }
            }
            return .newData
        }
        return .failed
    }

    // Update cached seq id of the last read message.
    public static func updateRead(using bud: BudChat, for topicName: String, seq: Int) -> UIBackgroundFetchResult {
        // Don't need to handle 'read' notifications for an unknown topic.
        guard let topic = bud.getTopic(topicName: topicName) as? DefaultComTopic else { return .failed }

        if topic.read ?? -1 < seq {
            topic.read = seq
            if let store = BaseDb.sharedInstance.sqlStore {
                _ = store.setRead(topic: topic, read: seq)
            }
        }
        return .noData
    }

    // Downloads an image.
    private static func downloadIcon(fromPath path: String, relativeTo baseUrl: URL, completion: @escaping ((UIImage?) -> Void)) {
        print("Downloading icon: ", path, baseUrl)
        guard let url = URL(string: path, relativeTo: baseUrl) else {
            print("Invalid icon url: ", path, baseUrl.absoluteString)
            completion(nil)
            return
        }
        let task = URLSession.shared.dataTask(with: URLRequest(url: url)) { data, _, error in
            if let error = error {
                print(error.localizedDescription)
            }
            completion(data != nil ? UIImage(data: data!) : nil)
        }
        task.resume()
    }

    // Identifies device with Tinode server and fetches branding configuration code.
    public static func identifyAndConfigureBranding() {
        let device = UIDevice.current.userInterfaceIdiom == .phone ? "iphone" : UIDevice.current.userInterfaceIdiom == .pad ? "ipad" : ""
        let version = UIDevice.current.systemVersion
        let url = URL(string: "https://hosts.tinode.co/whoami?os=ios-\(version)&dev=\(device)")!
        print("Self-identifying with the server. Endpoint: ", url.absoluteString)
        let task = URLSession.shared.dataTask(with: URLRequest(url: url)) { data, _, error in
            guard let data = data, error == nil else {
                print("Branding config response error: " + (error?.localizedDescription ?? "Failed to self-identify"))
                return
            }
            let responseJSON = try? JSONSerialization.jsonObject(with: data, options: [])
            if let responseJSON = responseJSON as? [String: Any] {
                print("Branding identity config: ", responseJSON)

                if let code = responseJSON["code"] as? String {
                    SharedUtils.setUpBranding(withConfigurationCode: code)
                } else {
                    print("Branding config error: Missing configuration code in the response. Quitting.")
                }
            }
        }
        task.resume()
    }

    // Configures application branding and connection settings.
    public static func setUpBranding(withConfigurationCode configCode: String) {
        guard !configCode.isEmpty else {
            print("Branding configuration code may not be empty. Skipping branding config.")
            return
        }
        print("Configuring branding with code '\(configCode)'")
        // Dummy url.
        // TODO: url should be based on the device fp (e.g. UIDevice.current.identifierForVendor).
        let url = URL(string: "https://hosts.tinode.co/id/\(configCode)")!

        print("Configuring branding and app settings. Request url: ", url.absoluteString)
        let task = URLSession.shared.dataTask(with: URLRequest(url: url)) { data, _, error in
            guard let data = data, error == nil else {
                print(error?.localizedDescription ?? "No data")
                return
            }
            let responseJSON = try? JSONSerialization.jsonObject(with: data, options: [])
            if let responseJSON = responseJSON as? [String: Any] {
                print("Branding configuration: ", responseJSON)

                if let tosUrl = URL(string: responseJSON["tos_url"] as? String ?? "") {
                    SharedUtils.tosUrl = tosUrl.absoluteString
                }
                if let serviceName = responseJSON["service_name"] as? String {
                    SharedUtils.serviceName = serviceName
                }
                if let privacyUrl = URL(string: responseJSON["privacy_url"] as? String ?? "") {
                    SharedUtils.privacyUrl = privacyUrl.absoluteString
                }
                if let apiUrl = URL(string: responseJSON["api_url"] as? String ?? "") {
                    ConnectionSettingsHelper.setHostName(apiUrl.host!)
                    let useTls = ["https", "ws"].contains(apiUrl.scheme)
                    ConnectionSettingsHelper.setUseTLS(useTls ? "true" : "false")
                }
                if let id = responseJSON["id"] as? String {
                    SharedUtils.appId = id
                }

                // Send a notification so all interested parties may use branding config.
                NotificationCenter.default.post(name: Notification.Name(SharedUtils.kNotificationBrandingConfigAvailable), object: nil)
                // Icons.
                if let assetsBase = responseJSON["assets_base"] as? String, let base = URL(string: assetsBase) {
                    if let smallIcon = responseJSON["icon_small"] as? String {
                        downloadIcon(fromPath: smallIcon, relativeTo: base) { img in
                            guard let img = img else { return }
                            SharedUtils.smallIcon = img
                            // Send notifications so all interested parties may use the new icon.
                            NotificationCenter.default.post(name: Notification.Name(SharedUtils.kNotificationBrandingSmallIconAvailable), object: img)
                        }
                    }
                    if let largeIcon = responseJSON["icon_large"] as? String {
                        downloadIcon(fromPath: largeIcon, relativeTo: base) { img in
                            guard let img = img else { return }
                            SharedUtils.largeIcon = img
                        }
                    }
                }
            }
        }
        task.resume()
    }
}

public extension BudChat {
    static func getConnectionParams() -> (String, Bool) {
        let (hostName, useTLS, _) = ConnectionSettingsHelper.getConnectionSettings()
        return (hostName ?? SharedUtils.kHostName, useTLS ?? SharedUtils.kUseTLS)
    }

    static func setHostName(_ hostName: String?) {
        ConnectionSettingsHelper.setHostName(hostName)
    }

    class func setUseTLS(_ useTLS: String?) {
        ConnectionSettingsHelper.setUseTLS(useTLS)
    }

    @discardableResult
    func connectDefault(inBackground bkg: Bool) throws -> PromisedReply<ServerMessage>? {
        let (hostName, useTLS) = BudChat.getConnectionParams()
        BaseDb.log.debug("Connecting to %@, secure %@", hostName, useTLS ? "YES" : "NO")
        return try connect(to: hostName, useTLS: useTLS, inBackground: bkg)
    }
}

extension String {
    /// 获取视频的第一帧
    /// - Parameter url: 视频url
    /// - Returns: 视频首帧
    func fetchVideoPreviewImage(completion: @escaping (UIImage) -> Void) {
        guard let url = URL(string: self) else { return }
        DispatchQueue.global().async {
            let asset = AVURLAsset(url: url, options: nil)
            let imageGenerator = AVAssetImageGenerator(asset: asset)
            // 按正确方向对视频进行截图
            imageGenerator.appliesPreferredTrackTransform = true
            let time = CMTimeMakeWithSeconds(0.0, preferredTimescale: 10)
            do {
                let imageRef = try imageGenerator.copyCGImage(at: time, actualTime: nil)
                DispatchQueue.main.async {
                    let image = UIImage(cgImage: imageRef)
                    completion(image)
                }
            } catch {
                #if DEBUG
                    print(error)
                #endif
            }
        }
    }
}
