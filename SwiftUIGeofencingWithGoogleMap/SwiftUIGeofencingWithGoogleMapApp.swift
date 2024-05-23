//
//  SwiftUIGeofencingWithGoogleMapApp.swift
//  SwiftUIGeofencingWithGoogleMap
//
//  Created by Kyubo Shim on 5/23/24.
//

import SwiftUI
import GoogleMaps
import GooglePlaces

@main
struct SwiftUIGeofencingWithGoogleMapApp: App {
    @UIApplicationDelegateAdaptor(AppDelegate.self) var appDelegate
    
    var body: some Scene {
        WindowGroup {
            ContentView()
        }
    }
}

class AppDelegate: NSObject, UIApplicationDelegate {
    func application(_ application: UIApplication,
                     didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?) -> Bool {
        if let apiKeys = readAPIKeys() {
            GMSServices.provideAPIKey(apiKeys.googleMapsApiKey)
            GMSPlacesClient.provideAPIKey(apiKeys.googlePlacesApiKey)
        } else {
            print("API 키를 불러오는데 실패했습니다.")
        }
        
        // 푸시 알림 권한 요청
        UNUserNotificationCenter.current().requestAuthorization(options: [.alert, .sound, .badge]) { granted, error in
            if granted {
                print("푸시 알림 권한 허용")
            } else if let error = error {
                print("푸시 알림 권한 요청 오류: \(error.localizedDescription)")
            } else {
                print("푸시 알림 권한 거부")
            }
        }
        
        return true
    }
    
    private func readAPIKeys() -> (googleMapsApiKey: String, googlePlacesApiKey: String)? {
        if let url = Bundle.main.url(forResource: "property", withExtension: "json"),
           let data = try? Data(contentsOf: url),
           let json = try? JSONSerialization.jsonObject(with: data, options: []) as? [String: String],
           let googleMapsApiKey = json["googleMapsApiKey"],
           let googlePlacesApiKey = json["googlePlacesApiKey"] {
            return (googleMapsApiKey, googlePlacesApiKey)
        }
        return nil
    }
}
