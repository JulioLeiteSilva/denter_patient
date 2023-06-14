import UIKit
import Flutter
import GoogleMaps

@UIApplicationMain
@objc class AppDelegate: FlutterAppDelegate {
  override func application(
    _ application: UIApplication,
    didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?
  ) -> Bool {
    GeneratedPluginRegistrant.register(with: self)

    GMSServices
                .provideAPIKey("AIzaSyCrujrW5-5FGs4Fyfb_oBXss00x2wlCplA")

    return super.application(application, didFinishLaunchingWithOptions: launchOptions)
  }
}
