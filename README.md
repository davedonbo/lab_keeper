# LabKeeper

**Cross-platform Flutter app for managing lab equipment borrowing, backed by Firebase.**

---

## 📖 Overview

LabKeeper lets students request, track, and return lab equipment via a polished mobile interface, while administrators review, approve, and audit those requests. Behind the scenes, Firebase Authentication secures access, Cloud Firestore stores all data, Cloud Functions power reactive notifications, and FCM delivers real-time push alerts. A proximity check—using device GPS and a short-lived presence feed—ensures handoffs occur only when borrower and approver are co-located.

---

## 🚀 Features

* **Student Flow**

  * Sign up / log in with email & password
  * Select equipment, quantities, and optional descriptions
  * Submit borrow requests and view status tabs (Pending, Approved, Returned, Overdue)
  * Enter “Beacon” mode to broadcast live GPS presence
  * Receive push notifications for approvals & returns (even when app is closed)
  * Tap notifications to deep-link into the appropriate request screen
  * Call any admin directly from the app bar

* **Administrator Flow**

  * Secure admin login
  * Tabbed dashboard (Pending, Approved, Returned, Overdue)
  * Proximity-verified approvals with barcode scanner & photo capture
  * Mark selected items as returned, with image review & immutable serials
  * Add, edit, and delete equipment inventory
  * Audit logs of all actions (who did what, when)
  * Send bulk overdue reminders via a callable Cloud Function
  * Call any student directly from request detail screens

* **Notifications & Offline**

  * Cloud Functions triggers for new requests, approvals, returns, and overdue reminders
  * Foreground & background notifications rendered via `flutter_local_notifications`
  * Deep-link handling on notification taps, even from cold start
  * Firestore offline persistence keeps the app usable without network

---

## 🏗 Architecture

```plaintext
Flutter Client
├─ UI (Screens & Widgets)
├─ Services (Auth, Borrow, Equipment, Audit, Presence, Notifications)
└─ Models (UserProfile, BorrowRequest, BorrowedItem, Equipment, AuditLog)

Firebase Backend
├─ Authentication (Email/Password, Roles)
├─ Firestore (users, borrow_requests, equipment, presence, audit_logs, tokens)
├─ Cloud Storage (item photos)
├─ Cloud Functions (onCreate/onUpdate triggers, sendOverdueNotifications callable)
└─ FCM (push notifications)
```

---

## 🛠 Tech Stack

* **Flutter & Dart**
* **Firebase**

  * Authentication
  * Firestore (with composite indexes)
  * Cloud Functions (Node.js 18)
  * Cloud Messaging
  * Cloud Storage
* **Plugins**

  * `cloud_firestore`, `firebase_auth`, `firebase_messaging`, `cloud_functions`, `firebase_storage`
  * `flutter_local_notifications`, `geolocator`, `mobile_scanner`, `image_picker`

---

## ⚙️ Setup & Installation

1. **Clone the repo**

   ```bash
   git clone https://github.com/<your-org>/labkeeper.git
   cd labkeeper
   ```

2. **Install dependencies**

   ```bash
   flutter pub get
   ```

3. **Firebase Configuration**

   * In the Firebase console, enable **Authentication**, **Firestore**, **Storage**, and **Cloud Functions**.
   * Create Firestore indexes for `borrow_requests` on `status` and `returnDate`.
   * Download and place `google-services.json` (Android) and `GoogleService-Info.plist` (iOS) under `android/app/` and `ios/Runner/` respectively.
   * Deploy Cloud Functions:

     ```bash
     cd functions
     npm install
     firebase deploy --only functions
     ```

4. **Android Setup**

   * Ensure min SDK ≥ 21 in `android/app/build.gradle`.
   * Add the required permissions in `AndroidManifest.xml` for Internet, camera, location, and notifications.

5. **iOS Setup**

   * Enable Push Notifications and Background Modes (Remote notifications) in Xcode.
   * Add required Info.plist entries for camera, photo library, and location usage.

---

## ▶️ Running the App

* **On Android**

  ```bash
  flutter run -d android
  ```
* **On iOS**

  ```bash
  flutter run -d ios
  ```

---

## 🔧 Testing Notifications

1. **Foreground**: Triggers via `FirebaseMessaging.onMessage` and displays a local notification.
2. **Background/Terminated**:

   * Send an FCM with both `notification` and `data` payload from Cloud Functions.
   * The background handler (`onBackgroundMessage`) will surface a local notification so it’s fully expanded.
3. **Tap Handling**:

   * All notifications carry `requestId` in `data`.
   * On tap, deep-link logic in your `navigatorKey` pushes the correct detail screen after splash or from any app state.

---

## 🤝 Contributing

1. Fork & clone.
2. Create a feature branch: `git checkout -b feature/YourFeature`.
3. Commit changes & push.
4. Open a pull request.

Please follow the existing code style, include tests where appropriate, and update this README or add docs for any new features.
