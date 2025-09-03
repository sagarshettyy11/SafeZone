import UIKit
import Flutter
import GoogleMaps   // <- add this

@main
@objc class AppDelegate: FlutterAppDelegate {
  override func application(
    _ application: UIApplication,
    didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?
  ) -> Bool {

    // Provide the API key BEFORE any map is created
    GMSServices.provideAPIKey("AIzaSyBHe96rWsHR5VUjZ-TjtelJerIXekm670E")

    GeneratedPluginRegistrant.register(with: self)
    return super.application(application, didFinishLaunchingWithOptions: launchOptions)
  }
}