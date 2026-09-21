import Flutter
import UIKit

@main
@objc class AppDelegate: FlutterAppDelegate, FlutterImplicitEngineDelegate {
  override func application(
    _ application: UIApplication,
    didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?
  ) -> Bool {
    return super.application(application, didFinishLaunchingWithOptions: launchOptions)
  }

  func didInitializeImplicitFlutterEngine(_ engineBridge: FlutterImplicitEngineBridge) {
    GeneratedPluginRegistrant.register(with: engineBridge.pluginRegistry)
    let registrar = engineBridge.pluginRegistry.registrar(forPlugin: "CloudSettings")!
    FlutterMethodChannel(name: "cloud_minesweeper/settings", binaryMessenger: registrar.messenger())
      .setMethodCallHandler { call, result in
        guard call.method == "openSettings" else {
          result(FlutterMethodNotImplemented)
          return
        }
        UIApplication.shared.open(URL(string: UIApplication.openSettingsURLString)!) { opened in
          result(opened ? nil : FlutterError(code: "unavailable", message: "Settings could not open", details: nil))
        }
      }
  }
}
