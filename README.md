# 🕌 Prayer Habit Tracker

A modern, premium, and feature-rich Flutter application designed to reinforce positive habits in children through an elegant gamified ecosystem. Operating with a real-time **Firebase Firestore** backend, the app features distinct dashboards for children and guardians, dynamic point economies, automatic location-aware prayer validation, and real-world reward redemptions.

Developed with a stunning **Deep Teal & Gold** aesthetic, smooth animations, and solid architectural principles.

---

## 🌟 Key Features

### 1. 👥 Multi-Role Ecosystem & Linking
* **Guardian Dashboard**: Allows parents, schools, and mosques to manage linked children, monitor streaks, define points rules, and publish customizable rewards.
* **Child Dashboard**: A vibrant interface displaying live point balances, active daily streaks, and prayer progress.
* **Multi-Node Linking**: A flexible database design where a child can link to multiple guardians simultaneously (e.g., linked to parents for home rewards, and a school or mosque for community leaderboards).

### 2. ⚡ Dynamic Point Economy & Custom Rewards
* **Flexible Rule Engine**: Guardians have full granular control over points configurations. They can define custom point payouts for four prayer states:
  * 🟢 **On-time**
  * 🟡 **Late**
  * 🕌 **On-time + Jama'ah (Congregation)**
  * 👥 **Late + Jama'ah**
* **Reward Marketplace**: Guardians can design real-world rewards (e.g., "1 hour of gaming", "Ice cream treat") with emoji icons and custom point costs.
* **Multi-Guardian Reward Store**: Children see consolidated rewards from all of their linked guardians, with points automatically adjusted and handled seamlessly.

### 3. 🛰️ Location-Aware API Verification (*Waqt al-Fadila*)
* **Silent Verification**: When logging a prayer, the app obtains the user's high-precision GPS coordinates (falling back gracefully to Mecca coordinates if blocked).
* **Aladhan API Integration**: The app dynamically queries the Aladhan API in the background using the user's geographical coordinates to fetch exact, real-time prayer timings.
* **Smart Window Validation**: Rather than utilizing hardcoded time buffers, the system dynamically calculates the *Waqt al-Fadila* (the preferred on-time window) specifically for each prayer:
  * **Fajr**: From Fajr start until Sunrise.
  * **Dhuhr / Asr / Maghrib / Isha**: From prayer start until the subsequent prayer's start time.

### 4. 📊 Visual History & Leaderboards
* **Visual Calendar Log**: An interactive monthly calendar marking logged prayers with interactive, color-coded badges indicating status (On-Time, Late, Jama'ah).
* **Community Leaderboard**: A real-time, high-fidelity leaderboard sorting all children connected to a school or mosque, featuring gold/silver/bronze medals.

---

## 🛠️ Technology Stack

* **Frontend**: Flutter & Dart (Cupertino + Material UI Hybrid)
* **State Management**: Flutter Riverpod v3 (Dynamic Async Providers)
* **Routing & Navigation**: GoRouter (Declarative routing with auth state redirection)
* **Database & Cloud Services**: 
  * Firebase Authentication (Real-time secure credentials)
  * Cloud Firestore (Real-time NoSQL streaming)
* **Network & Geolocation**:
  * `http` (Aladhan Prayer Times API)
  * `geolocator` (Precise GPS coordinates)
  * `permission_handler` (Platform-agnostic permission flows)
* **Typography**: Outfit (Google Fonts)

---

## 📁 Architecture Overview

The project is structured following clean coding practices and strict separation of concerns:

```text
lib/
├── core/
│   ├── router/          # GoRouter configuration & Auth state streams
│   └── theme/           # Premium design tokens & theme configurations
├── models/
│   ├── reward_model.dart
│   └── user_model.dart  # Multi-role database models
├── providers/
│   ├── auth_provider.dart      # Real-time FirebaseAuth listener
│   └── database_provider.dart  # Stream & Future providers for Firestore operations
├── screens/
│   ├── auth/            # Sign In / Sign Up flows
│   ├── child/           # Log Prayer, Dashboard, Rewards Store, Calendar
│   ├── guardian/        # Rules Matrix, Reward Creator, Dashboard, Leaderboards
│   └── shared/          # Invite & Linking codes
└── services/
    ├── location_service.dart   # GPS coordinates aggregator
    └── prayer_api_service.dart # Waqt al-Fadila calculator & API fetcher
```

---

## 🗄️ Firestore Database Schema

The database uses a highly scalable relational hierarchy designed for swift NoSQL queries and minimal reads:

```
users/ (Collection)
  ├── {uid} (Document - Guardian or Child)
        ├── role: "guardian" | "child"
        ├── points: 250 (Child only)
        ├── streak: 5 (Child only)
        ├── guardians: ["guard_uid_1"] (Child only)
        │
        ├── rules/ (Subcollection - Guardian only)
        │     └── config (Document: onTime, late, jamaahOnTime, jamaahLate values)
        │
        ├── rewards/ (Subcollection - Guardian only)
        │     └── {rewardId} (Document: title, cost, iconEmoji, active status)
        │
        └── prayerLogs/ (Subcollection - Child only)
              └── {logId} (Document: prayerName, status, jamaah, timestamp, pointsEarned)
```

---

## 🚀 Getting Started & Running

### Easiest Way to Run (Chrome Browser - No heavy setup)
Running the web build allows you to test the app instantly without Xcode or Android Studio installed on your computer.

1. **Enable Web App in Firebase Console**:
   * Open your project in the [Firebase Console](https://console.firebase.google.com/).
   * Click **Add App** and select the Web (`</>`) icon.
   * Register your app to receive your Web credentials.

2. **Add Your Web App ID**:
   * Open `lib/main.dart` in your code editor.
   * On line 18, replace the `appId` placeholder with the real App ID you copied from your Firebase Console.

3. **Launch in Chrome**:
   ```bash
   # Navigate to the folder
   cd "mobile app final project"

   # Run directly in Chrome
   flutter run -d chrome
   ```

---

### Running on Mobile Emulators / Devices
If you prefer running on physical devices or local emulators:

#### Android
1. Place your downloaded `google-services.json` inside the `android/app/` folder.
2. Start an Android emulator or connect a device.
3. Run:
   ```bash
   flutter run -d android
   ```

#### iOS (macOS only)
1. Place your downloaded `GoogleService-Info.plist` inside `ios/Runner/`.
2. Open Xcode, drag and drop `GoogleService-Info.plist` into the `Runner` folder inside Xcode.
3. Run inside the `ios` directory to link pods:
   ```bash
   cd ios && pod install && cd ..
   ```
4. Run the app:
   ```bash
   flutter run -d ios
   ```
