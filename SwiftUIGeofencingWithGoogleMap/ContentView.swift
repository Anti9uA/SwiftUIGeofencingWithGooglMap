//
//  ContentView.swift
//  SwiftUIGeofencingWithGoogleMap
//
//  Created by Kyubo Shim on 5/23/24.
//

import SwiftUI
import GoogleMaps
import GooglePlaces

extension UserDefaults {
    var totalSafeTime: TimeInterval {
        get { return double(forKey: "totalSafeTime") }
        set { set(newValue, forKey: "totalSafeTime") }
    }
    
    var totalOutTime: TimeInterval {
        get { return double(forKey: "totalOutTime") }
        set { set(newValue, forKey: "totalOutTime") }
    }
    
    var previousStatusChangeTime: Date {
        get { return object(forKey: "previousStatusChangeTime") as? Date ?? Date() }
        set { set(newValue, forKey: "previousStatusChangeTime") }
    }
    
    var previousStatus: String? {
        get { return string(forKey: "previousStatus") }
        set { set(newValue, forKey: "previousStatus") }
    }
}


struct ContentView: View {
    @State private var address: String = ""
    @State private var addressCoordinates: CLLocationCoordinate2D?
    @State private var addressCoordinatesText: String = "입력된 주소의 좌표값이 여기에 표시됩니다."
    @State private var statusText: String = ""
    @State private var statusColor: Color = .black
    @State private var showPermissionDeniedMessage = false
    @StateObject private var locationManager = LocationManager()
    private let placesClient = GMSPlacesClient.shared()

    // UserDefaults를 사용하여 데이터를 저장 및 로드
    @State private var previousStatus: String? = UserDefaults.standard.previousStatus
    @State private var previousStatusChangeTime: Date = UserDefaults.standard.previousStatusChangeTime
    @State private var totalSafeTime: TimeInterval = UserDefaults.standard.totalSafeTime
    @State private var totalOutTime: TimeInterval = UserDefaults.standard.totalOutTime

    var body: some View {
        VStack {
            TextField("주소를 입력하세요", text: $address)
                .textFieldStyle(RoundedBorderTextFieldStyle())
                .padding()
            
            Button(action: {
                getCoordinates(forAddress: address)
            }) {
                Text("좌표 찾기")
                    .padding()
                    .background(Color.blue)
                    .foregroundColor(.white)
                    .cornerRadius(8)
            }
            
//            Text(addressCoordinatesText)
//                .padding()
            
            if showPermissionDeniedMessage {
                Text("위치 권한이 허용되지 않았습니다.")
                    .foregroundColor(.red)
                    .bold()
                    .padding()
            } else if let currentLocation = locationManager.currentLocation {
                MapView(coordinate: addressCoordinates ?? currentLocation.coordinate)
                    .frame(width: 150, height: 150)
                    .cornerRadius(8)
                    .padding()
                    .ignoresSafeArea(.keyboard)
            }
            
            Text(statusText)
                .padding()
                .background(statusColor)
                .foregroundColor(.white)
                .cornerRadius(8)
            
            VStack {
                Text("Safe 영역에 있던 시간: \(formatTimeInterval(totalSafeTime))")
                Text("Out 영역에 있던 시간: \(formatTimeInterval(totalOutTime))")
            }

        }
        .padding()
        .onAppear {
            locationManager.requestLocationAuthorization()
        }
        .onReceive(locationManager.$currentLocation) { location in
            checkProximity(currentLocation: location)
        }
        .onReceive(locationManager.$authorizationStatus) { status in
            if status == .denied || status == .restricted {
                showPermissionDeniedMessage = true
            } else {
                showPermissionDeniedMessage = false
            }
        }
        .ignoresSafeArea(.keyboard)
    }

    private func getCoordinates(forAddress address: String) {
        let filter = GMSAutocompleteFilter()
        filter.type = .noFilter

        placesClient.findAutocompletePredictions(fromQuery: address, filter: filter, sessionToken: nil) { (results, error) in
            if let error = error {
                self.addressCoordinatesText = "오류: \(error.localizedDescription)"
                return
            }

            guard let result = results?.first else {
                self.addressCoordinatesText = "좌표를 찾을 수 없습니다."
                return
            }

            self.placesClient.fetchPlace(fromPlaceID: result.placeID, placeFields: .coordinate, sessionToken: nil) { (place, error) in
                if let error = error {
                    self.addressCoordinatesText = "오류: \(error.localizedDescription)"
                    return
                }

                guard let location = place?.coordinate else {
                    self.addressCoordinatesText = "좌표를 찾을 수 없습니다."
                    return
                }

                self.addressCoordinates = location
                let latitude = location.latitude
                let longitude = location.longitude
                self.addressCoordinatesText = "입력된 주소의 위도: \(latitude), 경도: \(longitude)"
                print(latitude)
                print(longitude)

                // 주소 좌표를 가져온 후에 실시간 위치 추적 시작
                self.locationManager.startUpdatingLocation()
            }
        }
    }

    private func checkProximity(currentLocation: CLLocation?) {
        guard let addressCoord = addressCoordinates, let currentCoord = currentLocation?.coordinate else {
            self.statusText = ""
            self.statusColor = .black
            return
        }

        let addressLocation = CLLocation(latitude: addressCoord.latitude, longitude: addressCoord.longitude)
        let distance = addressLocation.distance(from: currentLocation!)

        let newStatus: String
        if distance <= 100 {
            newStatus = "Safe"
            self.statusColor = .green
        } else {
            newStatus = "Out"
            self.statusColor = .red
        }

        let currentTime = Date()
        if let previousStatus = previousStatus {
            let elapsedTime = currentTime.timeIntervalSince(previousStatusChangeTime)
            if previousStatus == "Safe" {
                totalSafeTime += elapsedTime
                UserDefaults.standard.totalSafeTime = totalSafeTime
            } else if previousStatus == "Out" {
                totalOutTime += elapsedTime
                UserDefaults.standard.totalOutTime = totalOutTime
            }
        }
        previousStatusChangeTime = currentTime
        UserDefaults.standard.previousStatusChangeTime = previousStatusChangeTime

        if previousStatus != newStatus {
            sendNotification(for: newStatus)
        }

        self.statusText = newStatus
        self.previousStatus = newStatus
        UserDefaults.standard.previousStatus = newStatus
    }

    private func sendNotification(for status: String) {
        let content = UNMutableNotificationContent()
        content.title = "료이키텐카이"
        if status == "Safe" {
            content.body = "영역에 들어왔습니다."
        } else {
            content.body = "영역을 벗어났습니다."
        }
        content.sound = .default

        let request = UNNotificationRequest(identifier: UUID().uuidString, content: content, trigger: nil)
        UNUserNotificationCenter.current().add(request) { error in
            if let error = error {
                print("푸시 알림 오류: \(error.localizedDescription)")
            }
        }
    }

    private func formatTimeInterval(_ interval: TimeInterval) -> String {
        let hours = Int(interval) / 3600
        let minutes = (Int(interval) % 3600) / 60
        let seconds = Int(interval) % 60
        return String(format: "%02d:%02d:%02d", hours, minutes, seconds)
    }
}

class LocationManager: NSObject, ObservableObject, CLLocationManagerDelegate {
    private let locationManager = CLLocationManager()
    @Published var currentLocation: CLLocation?
    @Published var authorizationStatus: CLAuthorizationStatus

    override init() {
        self.authorizationStatus = locationManager.authorizationStatus
        super.init()
        locationManager.delegate = self
        locationManager.allowsBackgroundLocationUpdates = true
        locationManager.pausesLocationUpdatesAutomatically = false
        locationManager.requestAlwaysAuthorization()
        locationManager.startUpdatingLocation()
    }

    func requestLocationAuthorization() {
        locationManager.requestAlwaysAuthorization()
    }

    func startUpdatingLocation() {
        locationManager.startUpdatingLocation()
    }

    func stopUpdatingLocation() {
        locationManager.stopUpdatingLocation()
    }

    func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        currentLocation = locations.first
    }

    func locationManager(_ manager: CLLocationManager, didFailWithError error: Error) {
        print("현재 위치를 가져오는데 실패했습니다: \(error.localizedDescription)")
        currentLocation = nil
    }

    func locationManager(_ manager: CLLocationManager, didChangeAuthorization status: CLAuthorizationStatus) {
        self.authorizationStatus = status
        if status == .authorizedAlways || status == .authorizedWhenInUse {
            locationManager.startUpdatingLocation()
        } else {
            locationManager.stopUpdatingLocation()
        }
    }
}


#Preview {
    ContentView()
}
