# LibericaMapping Frontend

> A Flutter mobile application for geo-mapping of *Coffea Liberica* farms in Batangas, Philippines.

![Flutter](https://img.shields.io/badge/Flutter-3.41.2-02569B?style=flat&logo=flutter&logoColor=white)
![Dart](https://img.shields.io/badge/Dart-3.0.0+-0175C2?style=flat&logo=dart&logoColor=white)
![Android](https://img.shields.io/badge/Android-SDK%2036-3DDC84?style=flat&logo=android&logoColor=white)
![iOS](https://img.shields.io/badge/iOS-15.0+-000000?style=flat&logo=apple&logoColor=white)
![License](https://img.shields.io/badge/License-MIT-green?style=flat)

---

## Features

* **Farm Geo-Mapping** — View all registered Liberica farms on an interactive Google Maps dashboard
* **Tree-Level Mapping** — Drill into individual farms to view tree positions on a detailed OpenStreetMap view
* **Plant Classification** — Capture a photo with the device camera and classify it as Liberica or Not Liberica using the MobileNetV2 backend
* **Auto GPS Tagging** — Automatically fills GPS coordinates from the device location after taking a photo
* **Classification History** — Browse all past predictions filtered by result (Liberica / Not Liberica) and plant part (Leaf / Bark / Cherry / Combined)
* **Liberica Sample Map** — View all Liberica-positive classification results as circle pins on Google Maps — samples at the same GPS location are grouped with a count badge
* **Prediction Detail** — Tap any history entry to view full result details: confidence score, Grad-CAM heatmap, per-model breakdown, and a mini map of the sample location
* **Farm Overview** — Summary statistics: total farms, Liberica trees, DNA-verified trees, and verification rate
* **Admin Panel** — Secured admin login to manage farm data, edit farm details, and toggle tree DNA verification status

---

## Directory Structure

```
liberica_map/
├── pubspec.yaml
├── android/
│   ├── app/
│   │   ├── build.gradle              # compileSdk 36, minSdk 21, Java 17
│   │   └── src/main/
│   │       └── AndroidManifest.xml   # CAMERA, LOCATION, INTERNET permissions
│   ├── build.gradle                  # Kotlin 2.2.20
│   └── settings.gradle.kts
├── ios/
│   └── Runner/
│       ├── AppDelegate.swift         # Google Maps API key registration
│       └── Info.plist                # NSCamera, NSLocation usage descriptions
├── assets/
│   └── images/
└── lib/
    ├── main.dart                              # App entry — 3 tabs: Map / Overview / Classify
    ├── models/
    │   ├── farm.dart                          # Farm model — MongoDB schema mapping
    │   ├── prediction.dart                    # Prediction model — /predict + MongoDB doc
    │   └── tree.dart                          # CoffeeTree model — tree-level data
    ├── screens/
    │   ├── main_dashboard.dart                # Google Maps farm view + admin button
    │   ├── tree_map_screen.dart               # flutter_map tree view with highlight & zoom
    │   ├── overview_screen.dart               # Farm statistics dashboard
    │   ├── plant_classification_screen.dart   # Camera + GPS + classify + history tabs
    │   ├── prediction_detail_screen.dart      # Full prediction result + mini map
    │   ├── liberica_map_screen.dart           # Google Maps — all Liberica sample pins
    │   ├── admin_login_screen.dart            # Admin login + Farm Breakdown list
    │   ├── manage_farm_screen.dart            # Farm editor + tree DNA verification table
    │   ├── add_farm_screen.dart               # Add new farm with duplicate detection
    │   ├── edit_farm_screen.dart              # Edit existing farm details
    │   └── farms_directory_screen.dart        # Searchable farm directory list
    ├── services/
    │   ├── api_config.dart                    # Backend URL constants and timeout config
    │   ├── farm_service.dart                  # GET / POST / PUT farms
    │   ├── prediction_service.dart            # POST /predict + GET all predictions
    │   └── tree_service.dart                  # GET trees by farm
    ├── widgets/
    │   ├── farm_marker.dart                   # Custom Google Maps farm marker
    │   ├── farm_search_bar.dart               # Farm search + dropdown selector
    │   └── stats_card.dart                    # Overview stats card + FarmListTile
    └── utils/
        ├── app_theme.dart                     # Colors, text styles, AppConstants
        ├── mock_data.dart                     # Mock farm data (temporary)
        ├── mock_tree_data.dart                # Mock tree data with Haversine nearest-match
        └── secrets.example.dart               # API key template — never commit secrets.dart
```

---

## Setup

### Prerequisites

* Flutter SDK 3.41.2+ (stable channel)
* Dart SDK 3.0.0+
* Android Studio or VS Code with Flutter extension
* Android SDK 36 / NDK 28.2+
* Google Maps API Key with **Maps SDK for Android** and **Maps SDK for iOS** enabled

### Installation

```bash
git clone https://github.com/daleevincent/LibericaMapping_Frontend
cd LibericaMapping_Frontend
flutter pub get
```

### Configure Google Maps API Key

**Android** — `android/app/src/main/AndroidManifest.xml`:

```xml
<meta-data
    android:name="com.google.android.geo.API_KEY"
    android:value="YOUR_GOOGLE_MAPS_API_KEY_HERE"/>
```

**iOS** — `ios/Runner/AppDelegate.swift`:

```swift
GMSServices.provideAPIKey("YOUR_GOOGLE_MAPS_API_KEY_HERE")
```

### Configure Backend URL

`lib/services/api_config.dart`:

```dart
static const String baseUrl =
    'https://your-backend-url.run.app';
```

### Run the App

```bash
# Check environment
flutter doctor

# Debug on connected device
flutter run

# Release APK (Android)
flutter build apk --release
# Output: build/app/outputs/flutter-apk/app-release.apk

# Release IPA (iOS — requires macOS + Xcode)
flutter build ipa --release
```

---

## Backend

This app connects to the **GeoMappingFlask Backend**.

> Repository: [LibericaMapping_Backend](https://github.com/daleevincent/LibericaMapping_Backend)

**Deployed URL:**

```
https://geomappingbackend-154949125613.asia-southeast1.run.app
```

### Endpoints Used

| Method | Endpoint           | Description                       |
| ------ | ------------------ | --------------------------------- |
| GET    | `/farms/`          | Fetch all farms                   |
| POST   | `/farms/`          | Create a new farm                 |
| PUT    | `/farms/:id`       | Update an existing farm           |
| POST   | `/predict`         | Classify plant image + save to DB |
| GET    | `/trees/`          | Fetch all trees                   |
| GET    | `/trees/?farmId=`  | Fetch trees by farm ID            |

---

## Screens Overview

### 1. Farm Map (Main Dashboard)
Google Maps full-screen view of all registered farms in Batangas. Tap a farm pin to view its details and navigate to the tree-level map.

### 2. Tree Map
`flutter_map` OpenStreetMap view showing individual tree positions within a selected farm. Highlights and zooms to a specific tree when navigated from classification results (exact match or nearest within 50 m).

### 3. Plant Classification

**Classify tab:**
- Step 1 — Take a photo (camera only, no gallery)
- Step 2 — Select plant part: Leaf / Bark / Cherry / Combined
- Step 3 — GPS coordinates (auto-filled from device, or manual entry)
- Result shows: prediction label, confidence bar, Grad-CAM heatmap, per-model breakdown, and a mini map pinned to the exact GPS coordinates
- **View on Tree Map** navigates to the matching farm if found within 50 m, or shows a no-farm warning inline on the mini map

**History tab:**
- Filter row 1 — Result: `All` / `🌿 Liberica` / `✗ Not Liberica`
- Filter row 2 — Plant part: `All Parts` / `Leaf` / `Bark` / `Cherry` / `Combined`
- Summary: Total | Liberica | Not Liberica + **View Map** button
- Tap any entry to open the full Prediction Detail screen

### 4. Liberica Sample Map
Google Maps full-screen view of all Liberica-positive classification results.
- Green circle markers at each sample GPS location
- Multiple samples at the same location display a count badge (e.g. `3`)
- Tap a marker → bottom sheet lists all samples at that location
- Tap any sample → opens full Prediction Detail screen

### 5. Overview
Farm statistics grid: Total Farms, Verification Rate, Liberica Trees, DNA Verified. Scrollable farm directory with per-farm DNA verification progress bars.

### 6. Admin Panel
Accessed via the lock icon on the main dashboard header.
- Login with admin credentials
- **Farm Breakdown** — read-only DNA verification stats per farm
- **Manage Farm** — edit farm fields and toggle per-tree DNA verification checkboxes

---

## Permissions

### Android — `AndroidManifest.xml`

| Permission                  | Purpose                             |
| --------------------------- | ----------------------------------- |
| `INTERNET`                  | API calls to backend and map tiles  |
| `CAMERA`                    | Take photos for plant classification|
| `ACCESS_FINE_LOCATION`      | Precise GPS for sample tagging      |
| `ACCESS_COARSE_LOCATION`    | Fallback GPS                        |
| `ACCESS_NETWORK_STATE`      | flutter_map tile downloads          |

### iOS — `Info.plist`

| Key                                          | Purpose                          |
| -------------------------------------------- | -------------------------------- |
| `NSCameraUsageDescription`                   | Take photos for classification   |
| `NSLocationWhenInUseUsageDescription`        | GPS tagging during classification|
| `NSLocationAlwaysAndWhenInUseUsageDescription` | Background GPS fallback        |

---

## Dependencies

| Package                  | Version   | Purpose                        |
| ------------------------ | --------- | ------------------------------ |
| `google_maps_flutter`    | ^2.6.0    | Farm-level Google Maps         |
| `flutter_map`            | ^6.1.0    | Tree-level OpenStreetMap       |
| `latlong2`               | ^0.9.0    | LatLng coordinate model        |
| `geolocator`             | ^13.0.2   | Device GPS location            |
| `image_picker`           | ^1.1.2    | Camera capture                 |
| `http`                   | ^1.2.0    | REST API calls                 |
| `provider`               | ^6.1.1    | State management               |

---

## Design System

| Token              | Hex       | Usage                          |
| ------------------ | --------- | ------------------------------ |
| Primary green      | `#1A6B3A` | Buttons, headers, markers      |
| Gold accent        | `#E8A020` | Highlights, selected states    |
| DNA Verified blue  | `#1565C0` | Verified tree badges           |
| Non-Verified green | `#2E7D32` | Standard tree markers          |
| Background         | `#F5F5F0` | Screen backgrounds             |

---

## Admin Credentials

```
Username : admin
Password : liberica2024
```

> ⚠️ Replace with real authentication before production deployment.

---

## Notes

* The `build/` folder is excluded from version control — see `.gitignore`
* `lib/utils/mock_tree_data.dart` and `lib/utils/mock_data.dart` are temporary stubs — remove when backend `/trees/` endpoint is fully operational
* `lib/utils/secrets.example.dart` is a template — **never commit `secrets.dart`**
* `FileProvider` for Android camera is handled internally by `image_picker` v1.1+ — no manual provider needed
