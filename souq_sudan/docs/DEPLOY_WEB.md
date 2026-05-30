# نشر سوق السودان كصفحة ويب (Web فقط)

هذا الدليل ينشر التطبيق **كموقع ويب فقط** على Firebase Hosting — بدون أندرويد/iOS
وبدون Cloud Functions. مناسب للخطة المجانية (Spark).

> ملاحظة: تسجيل الدخول عبر الهاتف (Phone Auth) يحتاج SMS حقيقي وهو متاح فقط على
> خطة Blaze. على الخطة المجانية استخدم **أرقام اختبار** (Test phone numbers) من
> Firebase Console → Authentication → Sign-in method → Phone → Phone numbers for testing.

## 1. تجهيز مشروع Firebase

1. أنشئ مشروعًا في [Firebase Console](https://console.firebase.google.com/).
2. فعّل **Authentication → Sign-in method → Phone**.
3. أنشئ **Firestore Database** (وضع Production).
4. أنشئ **Storage bucket**.
5. في **Authentication → Settings → Authorized domains** أضف نطاق الاستضافة
   (`<project-id>.web.app` يُضاف تلقائيًا).

## 2. ربط المشروع محليًا

```bash
# في جذر الريبو
# حدّث .firebaserc بمعرّف مشروعك الفعلي
```

عدّل `.firebaserc`:

```json
{ "projects": { "default": "<your-firebase-project-id>" } }
```

## 3. توليد إعدادات Firebase للويب

```bash
cd souq_sudan
flutterfire configure --project=<your-firebase-project-id> --platforms=web
```

هذا ينشئ `lib/firebase_options.dart` بالقيم الحقيقية (يستبدل الـ stub المؤقت).

## 4. بناء الويب

> إذا فشل البناء برسالة "Building native assets failed" أو
> "objective_c require the dart assets feature"، فهذا بسبب مسار Flutter SDK
> الذي يحتوي مسافة. الحل مطبّق مسبقًا في `pubspec.yaml` عبر
> `dependency_overrides: path_provider_foundation: 2.4.1`. تأكد من تشغيل
> `flutter pub get` أولًا.

```bash
cd souq_sudan
flutter pub get
flutter config --no-enable-native-assets
flutter build web --release
```

الناتج في `souq_sudan/build/web`.

## 5. النشر على Firebase Hosting

```bash
# في جذر الريبو (حيث firebase.json)
firebase deploy --only hosting,firestore:rules,firestore:indexes,storage
```

`firebase.json` يشير `public` إلى `souq_sudan/build/web` مع rewrite لكل المسارات
إلى `index.html` (SPA) ورؤوس تخزين مؤقت مناسبة.

بعد النشر سيظهر رابط مثل: `https://<project-id>.web.app`.

## 6. أول مستخدم admin

1. سجّل دخولًا واحدًا عبر الموقع (برقم اختبار) لإنشاء `users/{uid}`.
2. في Firestore Console عدّل ذلك المستند: `role = "admin"`, `isVerified = true`.

## ما تم تعطيله للويب

- **FCM (الإشعارات)**: محروسة بـ `kIsWeb` في `main.dart`؛ لا تُسجَّل توكنات على
  الويب. لتفعيلها لاحقًا تحتاج Service Worker وإعداد VAPID key.
- **Cloud Functions**: غير منشورة (تحتاج Blaze). كل المنطق الأساسي يعمل من جهة
  العميل عبر قواعد Firestore.

## إعادة النشر بعد أي تعديل

```bash
cd souq_sudan && flutter build web --release && cd .. && firebase deploy --only hosting
```
