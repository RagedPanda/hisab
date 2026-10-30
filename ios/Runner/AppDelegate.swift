import Flutter
import Security
import UIKit
import UniformTypeIdentifiers
import UserNotifications
// Lets reminder notification actions (Snooze) run Dart in a background isolate.
import flutter_local_notifications

@main
@objc class AppDelegate: FlutterAppDelegate, FlutterImplicitEngineDelegate {
  private var scheduledBackup: ScheduledBackupBridge?

  override func application(
    _ application: UIApplication,
    didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?
  ) -> Bool {
    // Reminder alerts show while Hisab is open, and their taps reach the plugin.
    UNUserNotificationCenter.current().delegate = self
    return super.application(application, didFinishLaunchingWithOptions: launchOptions)
  }

  func didInitializeImplicitFlutterEngine(_ engineBridge: FlutterImplicitEngineBridge) {
    FlutterLocalNotificationsPlugin.setPluginRegistrantCallback { registry in
      GeneratedPluginRegistrant.register(with: registry)
    }
    GeneratedPluginRegistrant.register(with: engineBridge.pluginRegistry)
    if let registrar = engineBridge.pluginRegistry.registrar(forPlugin: "ScheduledBackupBridge") {
      scheduledBackup = ScheduledBackupBridge(messenger: registrar.messenger())
    }
  }
}

/// Scheduled backup on iOS (lib/data/backup/scheduled_backup_channel.dart):
/// a folder picked in Files, kept as a security-scoped bookmark that Dart
/// stores as the folder handle, and the passphrase in the Keychain (this
/// device only). iOS has no background run: Dart backs up when Hisab opens.
final class ScheduledBackupBridge: NSObject, UIDocumentPickerDelegate {
  private let channel: FlutterMethodChannel
  private var pendingPick: FlutterResult?
  private let io = DispatchQueue(label: "com.ragedpanda.hisab.scheduled-backup")
  private let keychainService = "com.ragedpanda.hisab.scheduledBackup"
  private let keychainAccount = "passphrase"

  init(messenger: FlutterBinaryMessenger) {
    channel = FlutterMethodChannel(name: "com.ragedpanda.hisab/scheduled_backup", binaryMessenger: messenger)
    super.init()
    channel.setMethodCallHandler { [weak self] call, result in self?.handle(call, result: result) }
  }

  private func handle(_ call: FlutterMethodCall, result: @escaping FlutterResult) {
    let arguments = call.arguments as? [String: Any] ?? [:]
    switch call.method {
    case "pickFolder": pickFolder(result: result)
    case "writeFile":
      onFolder(arguments, result: result) { folder in
        guard let name = arguments["name"] as? String, let bytes = arguments["bytes"] as? FlutterStandardTypedData else { return nil }
        try bytes.data.write(to: folder.appendingPathComponent(name), options: .atomic)
        return nil
      }
    case "listFiles":
      onFolder(arguments, result: result) { folder in try FileManager.default.contentsOfDirectory(atPath: folder.path) }
    case "deleteFile":
      onFolder(arguments, result: result) { folder in
        guard let name = arguments["name"] as? String else { return nil }
        let file = folder.appendingPathComponent(name)
        if FileManager.default.fileExists(atPath: file.path) { try FileManager.default.removeItem(at: file) }
        return nil
      }
    case "readPassphrase": result(readPassphrase())
    case "writePassphrase":
      if let passphrase = arguments["passphrase"] as? String { savePassphrase(passphrase) }
      result(nil)
    case "deletePassphrase":
      SecItemDelete(keychainQuery() as CFDictionary)
      result(nil)
    case "setBackgroundSchedule", "backgroundRunFinished": result(nil)
    default: result(FlutterMethodNotImplemented)
    }
  }

  // MARK: Folder

  private func pickFolder(result: @escaping FlutterResult) {
    guard pendingPick == nil, let host = topViewController() else {
      result(FlutterError(code: "busy", message: "The folder picker can't open now", details: nil))
      return
    }
    pendingPick = result
    let picker = UIDocumentPickerViewController(forOpeningContentTypes: [.folder])
    picker.delegate = self
    picker.allowsMultipleSelection = false
    host.present(picker, animated: true)
  }

  func documentPicker(_ controller: UIDocumentPickerViewController, didPickDocumentsAt urls: [URL]) {
    guard let result = pendingPick else { return }
    pendingPick = nil
    guard let folder = urls.first else {
      result(nil)
      return
    }
    let accessing = folder.startAccessingSecurityScopedResource()
    defer { if accessing { folder.stopAccessingSecurityScopedResource() } }
    do {
      let bookmark = try folder.bookmarkData(options: [], includingResourceValuesForKeys: nil, relativeTo: nil)
      result(["uri": bookmark.base64EncodedString(), "name": folder.lastPathComponent])
    } catch {
      result(FlutterError(code: "folder", message: error.localizedDescription, details: nil))
    }
  }

  func documentPickerWasCancelled(_ controller: UIDocumentPickerViewController) {
    pendingPick?(nil)
    pendingPick = nil
  }

  /// Resolves the bookmark Dart holds and runs [work] inside the folder's
  /// security scope, off the main thread. Failures come back as "folder".
  private func onFolder(_ arguments: [String: Any], result: @escaping FlutterResult, work: @escaping (URL) throws -> Any?) {
    io.async {
      do {
        guard let handle = arguments["folder"] as? String, let bookmark = Data(base64Encoded: handle) else {
          throw NSError(domain: "Hisab", code: 1, userInfo: [NSLocalizedDescriptionKey: "No folder"])
        }
        var stale = false
        let folder = try URL(resolvingBookmarkData: bookmark, options: [], relativeTo: nil, bookmarkDataIsStale: &stale)
        let accessing = folder.startAccessingSecurityScopedResource()
        defer { if accessing { folder.stopAccessingSecurityScopedResource() } }
        let value = try work(folder)
        DispatchQueue.main.async { result(value) }
      } catch {
        DispatchQueue.main.async { result(FlutterError(code: "folder", message: error.localizedDescription, details: nil)) }
      }
    }
  }

  private func topViewController() -> UIViewController? {
    let window = UIApplication.shared.connectedScenes
      .compactMap { ($0 as? UIWindowScene)?.windows.first(where: { $0.isKeyWindow }) }
      .first
    var top = window?.rootViewController
    while let presented = top?.presentedViewController { top = presented }
    return top
  }

  // MARK: Keychain

  private func keychainQuery() -> [String: Any] {
    [kSecClass as String: kSecClassGenericPassword, kSecAttrService as String: keychainService, kSecAttrAccount as String: keychainAccount]
  }

  private func readPassphrase() -> String? {
    var query = keychainQuery()
    query[kSecReturnData as String] = true
    query[kSecMatchLimit as String] = kSecMatchLimitOne
    var item: CFTypeRef?
    guard SecItemCopyMatching(query as CFDictionary, &item) == errSecSuccess, let data = item as? Data else { return nil }
    return String(data: data, encoding: .utf8)
  }

  private func savePassphrase(_ passphrase: String) {
    SecItemDelete(keychainQuery() as CFDictionary)
    var item = keychainQuery()
    item[kSecValueData as String] = Data(passphrase.utf8)
    item[kSecAttrAccessible as String] = kSecAttrAccessibleAfterFirstUnlockThisDeviceOnly
    SecItemAdd(item as CFDictionary, nil)
  }
}
