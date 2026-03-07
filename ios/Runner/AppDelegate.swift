import UIKit
import Flutter
import flutter_local_notifications
import GoogleMaps

@main
@objc class AppDelegate: FlutterAppDelegate {

  override func application(
    _ application: UIApplication,
    didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?
  ) -> Bool {

    // 1. MUST BE FIRST: Google Maps setup BEFORE plugin registration
    if let path = Bundle.main.path(forResource: "GoogleService-Info", ofType: "plist"),
       let dict = NSDictionary(contentsOfFile: path) as? [String: Any],
       let apiKey = dict["API_KEY"] as? String,
       !apiKey.isEmpty {
        GMSServices.provideAPIKey(apiKey)
    }

    // 2. NOW register plugins
    GeneratedPluginRegistrant.register(with: self)

    // 3. Setup method channel safely using registrar
    if let registrar = self.registrar(forPlugin: "ApiKeyPlugin") {
      let apiChannel = FlutterMethodChannel(
        name: "com.vango.app/apikey",
        binaryMessenger: registrar.messenger()
      )

      apiChannel.setMethodCallHandler { (call, result) in
        if call.method == "getApiKey" {
          if let path = Bundle.main.path(forResource: "GoogleService-Info", ofType: "plist"),
             let dict = NSDictionary(contentsOfFile: path) as? [String: Any],
             let apiKey = dict["API_KEY"] as? String {
            result(apiKey)
          } else {
            result(FlutterError(
              code: "UNAVAILABLE",
              message: "API Key not found",
              details: nil
            ))
          }
        } else {
          result(FlutterMethodNotImplemented)
        }
      }
    }

    // 4. Notifications setup
    FlutterLocalNotificationsPlugin.setPluginRegistrantCallback { registry in
      GeneratedPluginRegistrant.register(with: registry)
    }

    if #available(iOS 10.0, *) {
      UNUserNotificationCenter.current().delegate = self
    }

    return super.application(application, didFinishLaunchingWithOptions: launchOptions)
  }
}