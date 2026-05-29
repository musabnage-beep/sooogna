# Souq Sudan — Monorepo

سوق السودان — منصة إعلانات مبوبة للسوق السوداني.

```
sooogna/
├── souq_sudan/        Flutter app (Android · iOS · Web)
├── functions/         Firebase Cloud Functions (TypeScript, Node 20)
├── firebase.json      Top-level Firebase deploy config
├── .firebaserc        Firebase project alias
└── .github/workflows/ CI (analyze · test · functions build)
```

## Quick start

### Flutter app

```bash
cd souq_sudan
flutter pub get
flutterfire configure --project=<your-firebase-id>
flutter run
```

Full instructions: [`souq_sudan/docs/SETUP.md`](souq_sudan/docs/SETUP.md).

### Cloud Functions

```bash
cd functions
npm install
npm run build
firebase deploy --only functions
```

### Firestore + Storage rules + indexes

```bash
firebase deploy --only firestore:rules,firestore:indexes,storage
```

## Deployment checklist

Track every item before shipping to production.

### Firebase project
- [ ] Project created in [Firebase Console](https://console.firebase.google.com/).
- [ ] Update `.firebaserc` → replace `souq-sudan-prod` with your project ID.
- [ ] Authentication → Sign-in method → **Phone** enabled.
- [ ] Authentication → Settings → Authorized domains include production host.
- [ ] Billing on **Blaze** (real SMS requires it).
- [ ] Firestore created in `eur3` (or your preferred region).
- [ ] Storage bucket created in the same region.

### Android
- [ ] `flutterfire configure` ran → `souq_sudan/lib/firebase_options.dart` and
      `souq_sudan/android/app/google-services.json` generated.
- [ ] Debug SHA-1 + SHA-256 added in Firebase → Project settings → Android app.
- [ ] Release keystore generated (`keytool ...`) and SHAs added too.
- [ ] `souq_sudan/android/key.properties` filled in (kept out of git).
- [ ] `minSdkVersion = 23` in `souq_sudan/android/app/build.gradle.kts`.
- [ ] `flutter build appbundle --release` produces a working `.aab`.

### iOS
- [ ] `souq_sudan/ios/Runner/GoogleService-Info.plist` present.
- [ ] APNs `.p8` key uploaded in Firebase → Cloud Messaging.
- [ ] Xcode Runner target: Push Notifications + Background Modes
      (Remote notifications) capabilities enabled.
- [ ] `pod install` in `souq_sudan/ios/` succeeds.

### Cloud Functions
- [ ] `npm install && npm run build` succeeds inside `functions/`.
- [ ] `firebase deploy --only functions` succeeds.
- [ ] Functions visible: `onReviewWritten`, `onChatMessageCreated`,
      `onAdStatusChanged`, `onReportCreated`.

### Security
- [ ] `firebase deploy --only firestore:rules` succeeds.
- [ ] `firebase deploy --only firestore:indexes` queued (indexes build async).
- [ ] `firebase deploy --only storage` succeeds.

### App content
- [ ] `lib/core/constants/app_constants.dart` updated:
  - [ ] `supportWhatsAppNumber` → real number
  - [ ] `privacyPolicyUrl` → real URL
  - [ ] `termsOfServiceUrl` → real URL
- [ ] App icon + splash regenerated for production branding.
- [ ] Bundle / application IDs in
      `souq_sudan/android/app/build.gradle.kts` and Xcode match your store
      listings.

### First admin
- [ ] Sign in once through the app to create `users/{uid}`.
- [ ] In Firestore Console, set that user's `role` = `"admin"`,
      `isVerified` = `true`.

### Smoke test
- [ ] Login with phone OTP → land on `/register`.
- [ ] Create ad → admin approves → push arrives on owner device.
- [ ] Open chat → other side receives push.
- [ ] File a report → admin device receives push.

## Tech stack

- Flutter 3.16+, Dart 3.2+, Material 3, Cairo font, RTL Arabic
- Riverpod 2.x, go_router 14
- Firebase: Auth (Phone), Firestore, Storage, FCM, Cloud Functions
- Cloud Functions 2nd gen, Node 20, TypeScript

## Repo conventions

- Clean Architecture per feature: `presentation/`, `domain/`, `data/`.
- Domain layer does **not** import Firebase.
- All error handling via sealed `Result<T>`.
- Arabic strings in code; no hardcoded English UI.

## Licence

Proprietary — © Souq Sudan.
