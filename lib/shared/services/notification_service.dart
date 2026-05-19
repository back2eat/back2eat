// 📱 CUSTOMER APP
// lib/shared/services/notification_service.dart

import 'dart:async';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:go_router/go_router.dart';

import '../../core/di/injection.dart';
import '../../core/network/api_client.dart';

class NotificationService {
  NotificationService._();
  static final NotificationService instance = NotificationService._();

  FirebaseMessaging get _messaging => FirebaseMessaging.instance;
  final _localNotifs = FlutterLocalNotificationsPlugin();

  static const _channelId   = 'back2eat_orders';
  static const _channelName = 'Back2Eat Order Updates';

  GlobalKey<NavigatorState>? navigatorKey;

  final _orderUpdateController = StreamController<String>.broadcast();
  Stream<String> get orderUpdateStream => _orderUpdateController.stream;

  bool _initialised = false;

  Future<void> init() async {
    if (_initialised) return;
    _initialised = true;
    try {
      final settings = await _messaging.requestPermission(
        alert: true, badge: true, sound: true, provisional: false,
      );
      await FirebaseMessaging.instance.setForegroundNotificationPresentationOptions(
        alert: true, badge: true, sound: true,
      );
      debugPrint('[FCM] Permission: ${settings.authorizationStatus}');

      const channel = AndroidNotificationChannel(
        _channelId, _channelName,
        description: 'Real-time order and booking updates',
        importance: Importance.max, playSound: true, enableVibration: true,
      );
      await _localNotifs
          .resolvePlatformSpecificImplementation<AndroidFlutterLocalNotificationsPlugin>()
          ?.createNotificationChannel(channel);
      await _localNotifs
          .resolvePlatformSpecificImplementation<AndroidFlutterLocalNotificationsPlugin>()
          ?.requestNotificationsPermission();

      const initSettings = InitializationSettings(
        android: AndroidInitializationSettings('@mipmap/ic_launcher'),
        iOS: DarwinInitializationSettings(
          requestAlertPermission: true,
          requestBadgePermission: true,
          requestSoundPermission: true,
        ),
      );
      await _localNotifs.initialize(initSettings,
          onDidReceiveNotificationResponse: _onLocalNotifTap);

      FirebaseMessaging.onMessage.listen(_onForegroundMessage);
      FirebaseMessaging.onMessageOpenedApp.listen(_onMessageOpenedApp);

      final initialMessage = await _messaging.getInitialMessage();
      if (initialMessage != null) {
        Future.delayed(const Duration(milliseconds: 1000), () {
          _routeFromMessage(initialMessage.data);
        });
      }

      _messaging.onTokenRefresh.listen(_registerToken);
      await registerTokenAfterLogin();
    } catch (e) {
      debugPrint('[FCM] init error: $e');
    }
  }

  Future<void> registerTokenAfterLogin() async {
    // iOS: wait for APNs token before getting FCM token
    if (defaultTargetPlatform == TargetPlatform.iOS) {
      String? apnsToken;
      for (int i = 0; i < 10; i++) {
        apnsToken = await FirebaseMessaging.instance.getAPNSToken();
        if (apnsToken != null) break;
        await Future.delayed(const Duration(seconds: 1));
      }
      debugPrint('[FCM] APNs Token: $apnsToken');
      if (apnsToken == null) {
        debugPrint('[FCM] APNs token is null — iOS push will not work');
        return;
      }
    }
    for (int attempt = 1; attempt <= 3; attempt++) {
      try {
        final token = await _messaging.getToken();
        if (token == null) { debugPrint('[FCM] FCM Token is null'); return; }
        await _registerToken(token);
        return;
      } catch (e) {
        debugPrint('[FCM] registerTokenAfterLogin attempt $attempt failed: $e');
        if (attempt < 3) await Future.delayed(Duration(seconds: attempt * 2));
      }
    }
  }

  Future<void> _registerToken(String token) async {
    try {
      await getIt<ApiClient>().patch('/auth/fcm-token', {'fcmToken': token});
      debugPrint('[FCM] Token registered: ${token.substring(0, 20)}...');
    } catch (e) {
      debugPrint('[FCM] Token registration error: $e');
    }
  }

  Future<void> handleBackgroundMessage(RemoteMessage message) async {
    await _showLocalNotification(message);
  }

  Future<void> _onForegroundMessage(RemoteMessage message) async {
    debugPrint('[FCM] Foreground: type=${message.data["type"]}');
    await _showLocalNotification(message);
    final orderId = message.data['orderId'] as String?;
    if (orderId != null && orderId.isNotEmpty) {
      _orderUpdateController.add(orderId);
    }
  }

  void _onMessageOpenedApp(RemoteMessage message) {
    debugPrint('[FCM] Opened from background: ${message.data}');
    _routeFromMessage(message.data);
  }

  void _onLocalNotifTap(NotificationResponse response) {
    final payload = response.payload;
    if (payload == null || payload.isEmpty) return;
    if (payload.startsWith('order:'))        _navigateToOrder(payload.substring(6));
    else if (payload.startsWith('booking:')) _navigateToBookings();
    else                                     _navigateToOrder(payload);
  }

  void _routeFromMessage(Map<String, dynamic> data) {
    final type    = data['type']    as String? ?? '';
    final orderId = data['orderId'] as String? ?? '';
    if (type == 'BOOKING_CONFIRMED' || type == 'BOOKING_CANCELLED') {
      _navigateToBookings();
      return;
    }
    if (orderId.isNotEmpty) _navigateToOrder(orderId);
  }

  Future<void> _showLocalNotification(RemoteMessage message) async {
    // Use FCM title/body directly — backend now sends restaurant name in title
    // so we don't override with local hardcoded strings
    final title = message.notification?.title
        ?? _fallbackTitle(message.data['type'] as String?);
    final body  = message.notification?.body ?? '';

    final orderId   = message.data['orderId']   as String?;
    final bookingId = message.data['bookingId'] as String?;

    String payload = '';
    if (orderId   != null && orderId.isNotEmpty)   payload = 'order:$orderId';
    else if (bookingId != null && bookingId.isNotEmpty) payload = 'booking:$bookingId';

    final notifId = (orderId ?? bookingId ?? message.messageId ?? '')
        .hashCode.abs() % 100000;

    await _localNotifs.show(
      notifId, title, body,
      NotificationDetails(
        android: AndroidNotificationDetails(
          _channelId, _channelName,
          channelDescription: 'Real-time order and booking updates',
          importance: Importance.max, priority: Priority.high,
          playSound: true, enableVibration: true,
          icon: '@mipmap/ic_launcher',
        ),
        iOS: const DarwinNotificationDetails(
          presentAlert: true, presentBadge: true, presentSound: true,
        ),
      ),
      payload: payload,
    );
  }

  // Fallback titles when FCM notification block is absent (data-only messages)
  String _fallbackTitle(String? type) {
    switch (type) {
      case 'ORDER_ACCEPTED':    return 'Order Accepted! 🎉';
      case 'ORDER_PREPARING':   return 'Being Prepared 👨‍🍳';
      case 'ORDER_READY':       return 'Order Ready! 🍽️';
      case 'ORDER_CANCELLED':   return 'Order Cancelled ❌';
      case 'BOOKING_CONFIRMED': return 'Booking Confirmed! 🪑';
      case 'BOOKING_CANCELLED': return 'Booking Cancelled';
      case 'PAYMENT_SUCCESS':   return 'Payment Successful ✅';
      default:                  return 'Back2Eat 🔔';
    }
  }

  void _navigateToOrder(String orderId) {
    final ctx = navigatorKey?.currentContext;
    if (ctx == null) { debugPrint('[FCM] navigatorKey context is null'); return; }
    GoRouter.of(ctx).push('/order-tracking', extra: orderId);
  }

  void _navigateToBookings() {
    final ctx = navigatorKey?.currentContext;
    if (ctx == null) return;
    GoRouter.of(ctx).go('/bookings');
  }
}