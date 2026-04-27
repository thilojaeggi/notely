import Firebase
import Flutter
import UIKit
import WidgetKit

@main
@objc class AppDelegate: FlutterAppDelegate {
  /// Pending deep link URL from a cold start (widget tap before Flutter is ready).
  private var pendingDeepLink: String?
  private lazy var deeplinkChannel: FlutterMethodChannel = {
    let controller = window?.rootViewController as! FlutterViewController
    return FlutterMethodChannel(
      name: "ch.notely.app/deeplink",
      binaryMessenger: controller.binaryMessenger)
  }()

  override func application(
    _ application: UIApplication,
    didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?
  ) -> Bool {
    let registrar = self.registrar(forPlugin: "AppIconPlugin")!
    let iconChannel = FlutterMethodChannel(
      name: "ch.notely.app/icon",
      binaryMessenger: registrar.messenger())
    var isChangingIcon = false

    iconChannel.setMethodCallHandler({
      (call: FlutterMethodCall, result: @escaping FlutterResult) -> Void in
      if call.method == "setAlternateIconName" {
        if isChangingIcon {
          print("⚠️ Icon change already in progress, ignoring request.")
          result(FlutterError(code: "BUSY", message: "Icon change in progress", details: nil))
          return
        }
        
        if UIApplication.shared.applicationState != .active {
          print("⚠️ App is not active, ignoring icon change request.")
          result(FlutterError(code: "NOT_ACTIVE", message: "App not active", details: nil))
          return
        }

        let iconName = call.arguments as? String
        print("Changing icon to: \(iconName ?? "DEFAULT")")
        
        isChangingIcon = true
        // Use a slight delay to ensure the system is ready
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
            UIApplication.shared.setAlternateIconName(iconName) { error in
              isChangingIcon = false
              if let error = error as NSError? {
                print("❌ Icon change error: \(error.localizedDescription) (code: \(error.code), domain: \(error.domain))")
                result(
                  FlutterError(code: "ICON_ERROR", message: error.localizedDescription, details: "\(error.code)"))
              } else {
                print("✅ Icon change success")
                result(nil)
              }
            }
        }
      } else if call.method == "getAlternateIconName" {
        result(UIApplication.shared.alternateIconName)
      } else {
        result(FlutterMethodNotImplemented)
      }
    })

    GeneratedPluginRegistrant.register(with: self)
    
    // Debug icon setup
    let supports = UIApplication.shared.supportsAlternateIcons
    let current = UIApplication.shared.alternateIconName ?? "DEFAULT(nil)"
    print("🔎 supportsAlternateIcons = \(supports)")
    print("🔎 current alternateIconName = \(current)")
    if let icons = Bundle.main.object(forInfoDictionaryKey: "CFBundleIcons") as? [String: Any] {
        print("🔎 CFBundleIcons = \(icons)")
        if let alt = icons["CFBundleAlternateIcons"] as? [String: Any] {
            print("✅ Alternate icon keys found: \(alt.keys.sorted())")
        } else {
            print("❌ No CFBundleAlternateIcons found in CFBundleIcons")
        }
    } else {
        print("❌ No CFBundleIcons found in Info.plist")
    }

    if #available(iOS 14.0, *) {
      WidgetCenter.shared.reloadAllTimelines()
      NotificationCenter.default.addObserver(
        forName: UIApplication.didBecomeActiveNotification,
        object: nil, queue: .main
      ) { _ in
        WidgetCenter.shared.reloadAllTimelines()
        // Dump shared UserDefaults so we can see what the widget reads
        if let defaults = UserDefaults(suiteName: "group.ch.thilojaeggi.notely") {
          defaults.synchronize()
          let flag = defaults.string(forKey: "is_premium") ?? "nil"
          let expiry = defaults.string(forKey: "premium_expiry") ?? "nil"
          let lessonData = defaults.string(forKey: "notely_lesson_data")
          let hasLessons = lessonData != nil && !lessonData!.isEmpty
          print("🔍 [AppDelegate] Shared UserDefaults: is_premium=\(flag), premium_expiry=\(expiry), hasLessonData=\(hasLessons)")
        }
      }
    }

    // Set up deep link method channel so Flutter can pull pending URLs
    deeplinkChannel.setMethodCallHandler { [weak self] (call, result) in
      if call.method == "getPendingDeepLink" {
        let link = self?.pendingDeepLink
        self?.pendingDeepLink = nil
        result(link)
      } else {
        result(FlutterMethodNotImplemented)
      }
    }

    // If launched from a widget URL, store it for Flutter to pick up
    if let url = launchOptions?[.url] as? URL,
       url.scheme == "notely" {
      pendingDeepLink = url.absoluteString
    }

    return super.application(application, didFinishLaunchingWithOptions: launchOptions)
  }

  override func application(
    _ app: UIApplication,
    open url: URL,
    options: [UIApplication.OpenURLOptionsKey: Any] = [:]
  ) -> Bool {
    if url.scheme == "notely" {

      // Store as pending in case Flutter isn't ready yet (cold start from widget)
      pendingDeepLink = url.absoluteString
      // Also try to push immediately (works when Dart handler is already set up)
      deeplinkChannel.invokeMethod("onDeepLink", arguments: url.absoluteString)
      return true
    }
    return super.application(app, open: url, options: options)
  }

}
