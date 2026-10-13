import Flutter
import UIKit
import GoogleMaps

@main
@objc class AppDelegate: FlutterAppDelegate, FlutterImplicitEngineDelegate {
  override func application(
    _ application: UIApplication,
    didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?
  ) -> Bool {
    // Google Maps key of the meter-reading module (carried over from the
    // standalone Coordinates app). Make sure the key's bundle-id restriction
    // includes this app's bundle identifier, otherwise the map renders blank.
    GMSServices.provideAPIKey("AIzaSyD_qGyjt8ZVsXiJMuUTjoPBkp6Ew4EqyK4")
    return super.application(application, didFinishLaunchingWithOptions: launchOptions)
  }

  func didInitializeImplicitFlutterEngine(_ engineBridge: FlutterImplicitEngineBridge) {
    GeneratedPluginRegistrant.register(with: engineBridge.pluginRegistry)
  }
}
