// ios/Runner/AppDelegate.swift
// ============================================================
// IMPORTANT: Replace YOUR_GOOGLE_MAPS_API_KEY_HERE with your
// actual Google Maps API key from Google Cloud Console.
// ============================================================

import Flutter
import UIKit
import GoogleMaps

@UIApplicationMain
@objc class AppDelegate: FlutterAppDelegate {
  override func application(
    _ application: UIApplication,
    didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?
  ) -> Bool {
    // Replace with your actual API key:
    GMSServices.provideAPIKey("AIzaSyBWakBbd4nA5a7Opq1Ccyo6h6vlzWL0BQk")
    GeneratedPluginRegistrant.register(with: self)
    return super.application(application, didFinishLaunchingWithOptions: launchOptions)
  }
}