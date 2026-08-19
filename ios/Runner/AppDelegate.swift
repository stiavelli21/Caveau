import Flutter
import UIKit

@main
@objc class AppDelegate: FlutterAppDelegate {
  private let channelName = "caveau/screen_security"
  private var screenSecurityChannel: FlutterMethodChannel?

  override func application(
    _ application: UIApplication,
    didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?
  ) -> Bool {
    GeneratedPluginRegistrant.register(with: self)

    if let controller = window?.rootViewController as? FlutterViewController {
      screenSecurityChannel = FlutterMethodChannel(name: channelName, binaryMessenger: controller.binaryMessenger)

      screenSecurityChannel?.setMethodCallHandler { [weak self] (call: FlutterMethodCall, result: @escaping FlutterResult) in
        if call.method == "isScreenCaptureActive" {
          if #available(iOS 11.0, *) {
            result(UIScreen.main.isCaptured)
          } else {
            result(false)
          }
        } else if call.method == "setSecureFlag" {
          result(true)
        } else {
          result(FlutterMethodNotImplemented)
        }
      }
    }

    if #available(iOS 11.0, *) {
      NotificationCenter.default.addObserver(
        self,
        selector: #selector(screenCaptureChanged),
        name: UIScreen.capturedDidChangeNotification,
        object: nil
      )
    }

    return super.application(application, didFinishLaunchingWithOptions: launchOptions)
  }

  @objc private func screenCaptureChanged() {
    if #available(iOS 11.0, *) {
      let isCaptured = UIScreen.main.isCaptured
      screenSecurityChannel?.invokeMethod("onScreenCaptureChanged", arguments: ["isCaptured": isCaptured])
    }
  }
}
