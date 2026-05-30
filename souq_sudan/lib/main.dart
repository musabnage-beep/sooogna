import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/date_symbol_data_local.dart';

import 'config/router.dart';
import 'core/theme/app_theme.dart';
import 'core/utils/helpers.dart';
import 'features/notifications/data/notification_service.dart';
import 'firebase_options.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );

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

    return MaterialApp.router(
      title: 'سوق السودان',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.lightTheme,
      routerConfig: router,
      locale: const Locale('ar'),
      supportedLocales: const [Locale('ar'), Locale('en')],
      localizationsDelegates: const [
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      builder: (context, child) {
        NotificationService.instance.setNavigatorContext(context);
        return Directionality(
          textDirection: TextDirection.rtl,
          child: child ?? const SizedBox.shrink(),
        );
      },
    );
  }
}
