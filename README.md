# EldCare Caretaker App

A Flutter mobile application designed for caretakers to monitor elderly individuals using an IoT-enabled smart assistive stick in real time. The app connects with Firebase to receive sensor telemetry, track GPS location, manage medication schedules, and handle emergency alerts.

---

## Features

- **Live Sensor Telemetry**: Monitors real-time stick data from Firebase Realtime Database (distance, 3-axis accelerometer values, IR sensor readings, timestamp).
- **Fall & Obstacle Alerts**: Displays immediate alerts when the stick detects a fall (accelerometer threshold) or obstacle proximity (<20 cm), with direct links to view location on Google Maps.
- **GPS Location Tracking**: Shows current coordinates of the user on an embedded Google Map and supports launching external navigation.
- **Medicine Reminders**: Allows caretakers to schedule medicines with local push notifications and text-to-speech voice announcements.
- **Doctor Appointments**: Schedules appointments with notification reminders and persistent local storage.
- **Prescription Storage**: Uploads, organizes, and views prescription files (PDFs and images) locally on device.
- **Dark / Light Theme**: Built-in theme toggle on the dashboard.

---

## Tech Stack

- **Framework**: Flutter (Dart SDK `>=3.0.0 <4.0.0`)
- **Backend / Database**: Firebase Realtime Database
- **Maps**: `google_maps_flutter`, `url_launcher`
- **Notifications & Audio**: `flutter_local_notifications`, `timezone`, `flutter_tts`
- **Storage & Files**: `shared_preferences`, `file_picker`, `flutter_pdfview`, `path_provider`

---

## Project Structure

```
lib/
├── firebase_options.dart   # Generated Firebase platform configuration
├── main.dart               # App entry point and theme setup
├── models/
│   ├── appointment.dart    # Data model for doctor appointments
│   └── medicine.dart       # Data model for medicine schedules
├── screens/
│   ├── alerts.dart         # Fall and obstacle alert feed
│   ├── appointments.dart   # Doctor appointment scheduler
│   ├── dashboard.dart      # Main navigation grid
│   ├── iot_data.dart       # Real-time sensor readings
│   ├── location.dart       # Google Maps live tracking
│   ├── medicines.dart      # Medicine reminder manager
│   └── prescriptions.dart  # PDF/image prescription viewer
└── services/
    └── notification_service.dart # Local notification helper
```

---

## Getting Started

### Prerequisites

- Flutter SDK (3.0.0 or higher)
- Android Studio / VS Code with Flutter extension
- Android device or emulator with Google Play Services (for Google Maps)

### Installation

1. **Clone the repository:**
   ```bash
   git clone https://github.com/Siddeshgs/eldcare_caretaker_app.git
   cd eldcare_caretaker_app
   ```

2. **Install dependencies:**
   ```bash
   flutter pub get
   ```

3. **Configure Firebase:**
   - Place your `google-services.json` inside `android/app/`.
   - Update `lib/firebase_options.dart` if using a new Firebase project via FlutterFire CLI:
     ```bash
     flutterfire configure
     ```

4. **Configure Google Maps:**
   - Add your Google Maps API key in `android/app/src/main/AndroidManifest.xml`:
     ```xml
     <meta-data
         android:name="com.google.android.geo.API_KEY"
         android:value="YOUR_MAPS_API_KEY"/>
     ```

5. **Run the application:**
   ```bash
   flutter run
   ```
