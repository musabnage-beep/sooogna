import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_app_check/firebase_app_check.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/date_symbol_data_local.dart';

import 'config/router.dart';
import 'core/l10n/app_locale.dart';
import 'core/theme/app_theme.dart';
import 'core/utils/helpers.dart';
import 'features/notifications/data/notification_service.dart';
import 'firebase_options.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );

  // App Check (abuse protection for Firestore/Storage/Functions). The web
  // reCAPTCHA v3 site key is injected at build time so no secret is committed:
  //   flutter build web --dart-define=RECAPTCHA_SITE_KEY=<key>
  // When unset (local dev), App Check is skipped so the app still runs; enable
  // enforcement in the Firebase console only after a build ships the key.
  const recaptchaSiteKey = String.fromEnvironment('RECAPTCHA_SITE_KEY');
  if (recaptchaSiteKey.isNotEmpty) {
    await FirebaseAppCheck.instance.activate(
      webProvider: ReCaptchaV3Provider(recaptchaSiteKey),
    );
  }

  // Locale + timeago
  await initializeDateFormatting('ar', null);
  Helpers.initTimeago();

  // FCM background handler needs a service worker on web; skip it there.
  if (!kIsWeb) {
    FirebaseMessaging.onBackgroundMessage(firebaseMessagingBackgroundHandler);
  }

  runApp(const ProviderScope(child: SouqSudanApp()));
}

class SouqSudanApp extends ConsumerStatefulWidget {
  const SouqSudanApp({super.key});

  @override
  ConsumerState<SouqSudanApp> createState() => _SouqSudanAppState();
}

class _SouqSudanAppState extends ConsumerState<SouqSudanApp> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      // Push notifications (FCM) are mobile-only here; on web we rely on the
      // in-app Firestore notification inbox instead.
      if (!kIsWeb) {
        await NotificationService.instance.initialize();

        // Save FCM token whenever we have a logged-in user.
        FirebaseAuth.instance.authStateChanges().listen((user) async {
          if (user != null) {
            final token = await NotificationService.instance.getToken();
            if (token != null) {
              await NotificationService.instance
                  .saveTokenToFirestore(user.uid, token);
            }
            FirebaseMessaging.instance.onTokenRefresh.listen((newToken) {
              NotificationService.instance
                  .saveTokenToFirestore(user.uid, newToken);
            });
          }
        });
      }

      // Track lastActiveAt
      FirebaseAuth.instance.authStateChanges().listen((user) {
        if (user != null) {
          FirebaseFirestore.instance
              .collection('users')
              .doc(user.uid)
              .update({'lastActiveAt': FieldValue.serverTimestamp()})
              .catchError((_) {});
        }
      });
    });
  }

  @override
  Widget build(BuildContext context) {
    final router = ref.watch(routerProvider);

    final locale = ref.watch(localeProvider);
    return MaterialApp.router(
      title: S.tr('app_name', locale.languageCode),
      debugShowCheckedModeBanner: false,
      theme: AppTheme.lightTheme,
      routerConfig: router,
      locale: locale,
      supportedLocales: const [Locale('ar'), Locale('en')],
      localizationsDelegates: const [
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      builder: (context, child) {
        NotificationService.instance.setNavigatorContext(context);
        return Directionality(
          textDirection: locale.languageCode == 'ar' ? TextDirection.rtl : TextDirection.ltr,
          child: child ?? const SizedBox.shrink(),
        );
      },
    );
  }
}
