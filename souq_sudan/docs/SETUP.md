# Souq Sudan — Setup Guide

This document explains how to bootstrap the **Souq Sudan** (سوق السودان) Flutter
marketplace from a clean machine to a running Android build connected to a real
Firebase project.

---

## 1. Prerequisites

| Tool | Version |
|------|---------|
| Flutter SDK | `>=3.16.0` (Dart `>=3.2.0`) |
| Android Studio | Hedgehog (2023.1) or newer |
| Xcode (iOS only) | 15.x or newer |
| Node.js | `>=18` (for Firebase CLI) |
| Firebase CLI | `npm install -g firebase-tools` |
| FlutterFire CLI | `dart pub global activate flutterfire_cli` |
| A Google account with Firebase access | — |

Verify:

```bash
flutter --version
flutter doctor -v
firebase --version
flutterfire --version
```

`flutter doctor` must report no critical errors for the platforms you intend to
build (Android, iOS).

---

## 2. Clone & install

```bash
git clone <repo-url> souq_sudan
cd souq_sudan
flutter pub get
```

The project uses:

- `flutter_riverpod ^2.5.1`
- `go_router ^14.3.0`
- `firebase_core ^3.6.0`, `firebase_auth ^5.3.1`,
  `cloud_firestore ^5.4.4`, `firebase_storage ^12.3.4`,
  `firebase_messaging ^15.1.3`
- `google_fonts ^6.2.1` (Cairo)
- `image_picker ^1.1.2`
- `url_launcher ^6.3.1`
- `shared_preferences ^2.3.2`
- `intl ^0.20.2`, `timeago ^3.7.0`

If `pub get` fails on Windows due to long paths, enable Win32 long paths
(`git config --system core.longpaths true` and the Windows registry
`LongPathsEnabled=1`).

---

## 3. Create a Firebase project

1. Open <https://console.firebase.google.com/> and create a project named
   **Souq Sudan** (`souq-sudan-prod`). Disable Google Analytics if you don't
   need it.
2. Inside the project, enable the following products:
   - **Authentication** → Sign-in method → enable **Phone**.
   - **Firestore Database** → Create database → Start in
     **production mode** → region `eur3` (or `nam5` if you serve North Africa
     primarily).
   - **Storage** → Get started → production mode → same region.
   - **Cloud Messaging** → no action needed, available by default.
3. (Optional) Create a second Firebase project for staging
   (`souq-sudan-staging`) and repeat. Use FlutterFire flavors if you want both
   wired in the same checkout.

---

## 4. Configure Phone Authentication

1. **Authentication → Sign-in method → Phone → Enable**.
2. Add your **test phone numbers** (e.g. `+249 9 1234 5678` → code
   `123456`) under *Phone numbers for testing*. This avoids SMS quotas during
   development.
3. **Authentication → Settings → User actions → enable** *Email enumeration
   protection*.
4. **Authentication → Settings → Authorized domains**: keep `localhost` and add
   any production domain you may use for the admin web build.

### Android SHA fingerprints

Phone auth on Android requires SHA-1 **and** SHA-256 fingerprints in the
Firebase Android app.

```bash
# Debug
cd android
./gradlew signingReport
```

Locate `Variant: debug` and copy `SHA1` + `SHA-256`.

For release, generate a keystore and copy its fingerprints:

```bash
keytool -genkey -v -keystore ~/keys/souq-sudan-release.jks \
        -keyalg RSA -keysize 2048 -validity 10000 -alias souq-sudan

keytool -list -v -keystore ~/keys/souq-sudan-release.jks -alias souq-sudan
```

In the Firebase console: **Project settings → Your apps → Android app →
Add fingerprint** and paste each value.

---

## 5. Wire the Flutter app to Firebase

From the project root:

```bash
flutterfire configure \
    --project=souq-sudan-prod \
    --platforms=android,ios \
    --android-package-name=sd.souq.souq_sudan \
    --ios-bundle-id=sd.souq.souqSudan
```

This will:

- Register Android + iOS apps in the Firebase project.
- Download `google-services.json` to `android/app/`.
- Download `GoogleService-Info.plist` to `ios/Runner/`.
- Generate `lib/firebase_options.dart` (already imported in `lib/main.dart`).

Re-run this command whenever you add a platform or switch Firebase projects.

### Android tweaks

`android/build.gradle` — `classpath 'com.google.gms:google-services:4.4.2'`
should already be present.
`android/app/build.gradle` — `apply plugin: 'com.google.gms.google-services'`
should already be present.

`android/app/src/main/AndroidManifest.xml` must include:

```xml
<uses-permission android:name="android.permission.INTERNET"/>
<uses-permission android:name="android.permission.RECEIVE_SMS"/>
<uses-permission android:name="android.permission.READ_PHONE_STATE"/>
<uses-permission android:name="android.permission.POST_NOTIFICATIONS"/>
<uses-permission android:name="android.permission.CAMERA"/>
<uses-permission android:name="android.permission.READ_MEDIA_IMAGES"/>
```

Set the `minSdkVersion` to **23** in `android/app/build.gradle` (required by
`firebase_auth`).

### iOS tweaks

`ios/Runner/Info.plist` must include:

```xml
<key>NSCameraUsageDescription</key>
<string>السماح بالوصول إلى الكاميرا لرفع صور الإعلانات</string>
<key>NSPhotoLibraryUsageDescription</key>
<string>السماح بالوصول إلى الصور لرفع صور الإعلانات</string>
<key>NSMicrophoneUsageDescription</key>
<string>غير مستخدم</string>
<key>CFBundleAllowMixedLocalizations</key>
<true/>
<key>FirebaseAppDelegateProxyEnabled</key>
<false/>
```

In `ios/Podfile`, set `platform :ios, '13.0'`.

Then:

```bash
cd ios && pod install --repo-update
```

---

## 6. Deploy Firestore rules, indexes & Storage rules

The project ships hardened rules in the `firebase/` folder. Initialise the
project once:

```bash
firebase login
firebase use --add souq-sudan-prod   # alias it as "default" or "prod"
```

Create or merge a `firebase.json` at the repo root:

```json
{
  "firestore": {
    "rules": "firebase/firestore.rules",
    "indexes": "firebase/firestore.indexes.json"
  },
  "storage": {
    "rules": "firebase/storage.rules"
  }
}
```

Deploy:

```bash
firebase deploy --only firestore:rules
firebase deploy --only firestore:indexes
firebase deploy --only storage
```

Index builds are asynchronous; the console will show "Building" until they
finish (1–10 minutes for an empty database, longer for a populated one).

> Re-deploy `firestore:indexes` any time you add a new sort/filter combination
> in code. See `docs/DATABASE_SCHEMA.md` for which queries each index supports.

---

## 7. Seed the first admin user

Phone auth users are created with `role: "user"`. To promote the first admin:

1. Sign in with your phone number through the app — this creates the user
   document at `users/{uid}`.
2. Open Firestore in the console → `users/{uid}` → set:
   - `role` → `"admin"`
   - `isVerified` → `true`
3. Sign out and back in. The router's admin guard will now allow access to
   `/admin/*`.

After this, additional admins can be promoted from the in-app admin panel
(`/admin/users/{id}` → *تعيين كمسؤول*).

---

## 8. Cloud Messaging (FCM)

### Android

Nothing extra to configure — `google-services.json` covers it. The default
notification channel is created in `NotificationService.init()`.

### iOS

1. Apple Developer account → **Keys** → create an **APNs Authentication Key**.
2. Firebase Console → Project settings → **Cloud Messaging** → upload the
   `.p8` key, the **Key ID** and your **Team ID**.
3. In Xcode (`ios/Runner.xcworkspace`), enable **Push Notifications** and
   **Background Modes → Remote notifications** capabilities for the Runner
   target.

### Tokens

`main.dart` listens to `authStateChangesProvider` and on sign-in calls
`NotificationService.instance.saveTokenForUser(uid)` which writes the FCM
token to `users/{uid}.fcmTokens` (array union). Server-side senders (or your
admin panel "broadcast" feature) should fan-out to those tokens.

---

## 9. Assets & fonts

The project relies on Google Fonts (Cairo) — no fonts are bundled in `assets/`,
so no `pubspec.yaml` font block is required. If you later embed Cairo locally
for offline use, drop the TTFs in `assets/fonts/` and register them.

Image assets (placeholder banners, empty-state illustrations) go under
`assets/images/` and must be declared in `pubspec.yaml`:

```yaml
flutter:
  uses-material-design: true
  assets:
    - assets/images/
```

---

## 10. Run & build

### Run on a connected device

```bash
flutter run
```

### Release Android APK

```bash
flutter build apk --release
```

Output: `build/app/outputs/flutter-apk/app-release.apk`.

> **Windows note**: if your username contains a space the Gradle build fails
> with `Unable to establish loopback connection`. Set, before building:
>
> ```bash
> mkdir -p /c/t
> export JAVA_TOOL_OPTIONS='-Djdk.net.unixdomain.tmpdir=C:\\t -Djava.io.tmpdir=C:\\t'
> ```

### Release Android App Bundle

```bash
flutter build appbundle --release
```

### Release iOS

```bash
flutter build ipa --release
```

Then upload via Transporter or `xcrun altool`.

---

## 11. Verifying the install

Quick smoke test after a fresh install:

1. Launch app → splash redirects to `/login`.
2. Enter a test phone number → receive code → land on `/register`.
3. Fill profile (name, optional photo) → land on `/home`.
4. Create an ad → uploads images to `ad_images/{adId}/` → status `pending`.
5. Promote your user to admin (step 7) → `/admin/ads` → approve the ad.
6. Open the ad detail → start a chat → messages stream in real-time.
7. Toggle notifications off in `/settings` → toggle back on.

If all seven steps work end-to-end, the install is healthy.

---

## 12. Useful commands

```bash
# Static analysis
flutter analyze

# Tests
flutter test

# Format
dart format lib test

# Regenerate firebase_options.dart
flutterfire configure

# Deploy security rules only
firebase deploy --only firestore:rules,storage

# Tail Firestore emulator (optional local dev)
firebase emulators:start --only firestore,auth,storage
```

---

## 13. Troubleshooting

| Symptom | Cause / fix |
|---------|-------------|
| `MissingPluginException(No implementation found for method ... on channel plugins.flutter.io/firebase_*)` | Run `flutter clean && flutter pub get`; for iOS also `cd ios && pod install`. |
| Phone auth: `BILLING_NOT_ENABLED` | Upgrade Firebase project to Blaze (pay-as-you-go). Spark plan does not allow real SMS outside the test numbers. |
| `PERMISSION_DENIED` on Firestore | Rules not deployed, or user is banned (`users/{uid}.isBanned == true`). |
| `Index not found` errors in logs | Click the link Firebase prints, **or** add the index to `firebase/firestore.indexes.json` and redeploy. |
| FCM works on Android, silent on iOS | APNs key not uploaded, or *Push Notifications* capability missing. |
| Arabic text shows boxes | Cairo failed to load from Google Fonts — ensure the device has internet on first run, or bundle the font in `assets/`. |
