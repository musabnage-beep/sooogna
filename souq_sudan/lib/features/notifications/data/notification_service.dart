import 'dart:async';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

@pragma('vm:entry-point')
Future<void> firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  // Background handler - no UI work here
}

class NotificationService {
  static final NotificationService instance = NotificationService._();
  NotificationService._();

  final FirebaseMessaging _messaging = FirebaseMessaging.instance;
  BuildContext? _navigatorContext;

  void setNavigatorContext(BuildContext context) {
    _navigatorContext = context;
  }

  Future<void> initialize() async {
    // Request permission
    final settings = await _messaging.requestPermission(
      alert: true,
      badge: true,
      sound: true,
    );

    if (settings.authorizationStatus == AuthorizationStatus.authorized ||
        settings.authorizationStatus == AuthorizationStatus.provisional) {
      // Foreground message handler
      FirebaseMessaging.onMessage.listen(_handleForegroundMessage);

      // App opened from notification (background)
      FirebaseMessaging.onMessageOpenedApp.listen(_handleNotificationTap);

      // App opened from terminated state
      final initialMessage = await _messaging.getInitialMessage();
      if (initialMessage != null) {
        Future.delayed(const Duration(seconds: 2), () {
          _handleNotificationTap(initialMessage);
        });
      }
    }

    // Background handler
    FirebaseMessaging.onBackgroundMessage(firebaseMessagingBackgroundHandler);

    // Token refresh
    _messaging.onTokenRefresh.listen((token) {
      // Token refreshed - caller should save to Firestore
    });
  }

  Future<String?> getToken() async {
    try {
      return await _messaging.getToken();
    } catch (_) {
      return null;
    }
  }

  Future<void> saveTokenToFirestore(String userId, String token) async {
    try {
      await FirebaseFirestore.instance
          .collection('users')
          .doc(userId)
          .update({'fcmToken': token});
    } catch (_) {}
  }

  void _handleForegroundMessage(RemoteMessage message) {
    // In a production app, show a local notification banner here
    // For now, we rely on the app UI to show unread counts
  }

  void _handleNotificationTap(RemoteMessage message) {
    final ctx = _navigatorContext;
    if (ctx == null) return;

    final data = message.data;
    final type = data['type'] as String?;
    final targetId = data['targetId'] as String?;

    switch (type) {
      case 'chat':
        if (targetId != null) ctx.push('/chats/$targetId');
        break;
      case 'ad_status':
        if (targetId != null) ctx.push('/ads/$targetId');
        break;
      case 'review':
        ctx.push('/profile');
        break;
      default:
        break;
    }
  }
}
