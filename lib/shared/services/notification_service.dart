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

  // ── LAZY getter — only accessed AFTER Firebase.initializeApp() ────────────
  FirebaseMessaging get _messaging => FirebaseMessaging.instance;

  final _localNotifs = FlutterLocalNotificationsPlugin();

  static const _channelId   = 'back2eat_orders';
  static const _channelName = 'Back2Eat Order Updates';

  /// Set by app_router after router is built — needed for tap navigation
  GlobalKey<NavigatorState>? navigatorKey;

  /// Stream that order-tracking page listens to for silent refreshes
  final _orderUpdateController = StreamController<String>.broadcast();
  Stream<String> get orderUpdateStream => _orderUpdateController.stream;

  bool _initialised = false;

  // ── Notification templates ─────────────────────────────────────────────────
  static const _typeConfig = {
    'ORDER_ACCEPTED':    ('Order Accepted! 🎉',       'Your order has been accepted by the restaurant.'),
    'ORDER_PREPARING':   ('Being Prepared 👨‍🍳',       'The kitchen is preparing your order now.'),
    'ORDER_READY':       ('Order Ready! 🍽️',           'Your order is ready. Please collect it!'),
    'ORDER_CANCELLED':   ('Order Cancelled ❌',        'Your order was cancelled.'),
    'ORDER_STATUS':      ('Order Update 🔔',           null),
    'BOOKING_CONFIRMED': ('Booking Confirmed! 🪑',     'Your table is confirmed. Please complete the ₹19 payment.'),
    'BOOKING_CANCELLED': ('Booking Cancelled',         'Your table booking was cancelled by the restaurant.'),
    'PAYMENT_SUCCESS':   ('Payment Successful ✅',     'Your payment was processed successfully.'),
    'LUCKY_DRAW_WIN':    ('🎉 You Won the Lucky Draw!', 'Your prize has been added to your wallet!'),
    'LUCKY_DRAW_TICKET': ('🎟️ Lucky Draw Ticket!',     'Your ticket is entered in the draw. Good luck!'),
  };

  // ── Init — called from main() AFTER Firebase.initializeApp() ─────────────
  Future<void> init() async {
    if (_initialised) return;
    _initialised = true;

    try {
      // 1. Request permission
      final settings = await _messaging.requestPermission(
        alert: true, badge: true, sound: true,
        provisional: false,
      );
      debugPrint('[FCM] Permission: ${settings.authorizationStatus}');

      // 2. Create Android notification channel
      const channel = AndroidNotificationChannel(
        _channelId, _channelName,
        description: 'Real-time order and booking updates',
        importance: Importance.max,
        playSound: true,
        enableVibration: true,
      );
      await _localNotifs
          .resolvePlatformSpecificImplementation<
          AndroidFlutterLocalNotificationsPlugin>()
          ?.createNotificationChannel(channel);

      // 3. Android 13+ runtime notification permission
      await _localNotifs
          .resolvePlatformSpecificImplementation<
          AndroidFlutterLocalNotificationsPlugin>()
          ?.requestNotificationsPermission();

      // 4. Init local notifications plugin
      const initSettings = InitializationSettings(
        android: AndroidInitializationSettings('@mipmap/ic_launcher'),
        iOS: DarwinInitializationSettings(
          requestAlertPermission: true,
          requestBadgePermission: true,
          requestSoundPermission: true,
        ),
      );
      await _localNotifs.initialize(
        initSettings,
        onDidReceiveNotificationResponse: _onLocalNotifTap,
      );

      // 5. Foreground FCM messages
      FirebaseMessaging.onMessage.listen(_onForegroundMessage);

      // 6. App brought to foreground by tapping notification
      FirebaseMessaging.onMessageOpenedApp.listen(_onMessageOpenedApp);

      // 7. App launched from terminated state via notification tap
      final initialMessage = await _messaging.getInitialMessage();
      if (initialMessage != null) {
        Future.delayed(const Duration(milliseconds: 1000), () {
          _routeFromMessage(initialMessage.data);
        });
      }

      // 8. Token refresh — re-register with backend
      _messaging.onTokenRefresh.listen(_registerToken);

      // 9. Register current token
      await registerTokenAfterLogin();

    } catch (e) {
      debugPrint('[FCM] init error: $e');
    }
  }

  // ── Register token after login ─────────────────────────────────────────────
  Future<void> registerTokenAfterLogin() async {
    try {
      final token = await _messaging.getToken();
      if (token == null) {
        debugPrint('[FCM] Token is null — permissions may be denied');
        return;
      }
      await _registerToken(token);
    } catch (e) {
      debugPrint('[FCM] registerTokenAfterLogin failed: $e');
    }
  }

  Future<void> _registerToken(String token) async {
    try {
      await getIt<ApiClient>().patch('/auth/fcm-token', {'fcmToken': token});
      debugPrint('[FCM] Token registered: ${token.substring(0, 20)}…');
    } catch (e) {
      debugPrint('[FCM] Token registration error: $e');
    }
  }

  // ── Background message handler ─────────────────────────────────────────────
  Future<void> handleBackgroundMessage(RemoteMessage message) async {
    await _showLocalNotification(message);
  }

  // ── Foreground message ─────────────────────────────────────────────────────
  Future<void> _onForegroundMessage(RemoteMessage message) async {
    debugPrint('[FCM] Foreground: type=${message.data["type"]} orderId=${message.data["orderId"]}');
    await _showLocalNotification(message);
    final orderId = message.data['orderId'] as String?;
    if (orderId != null && orderId.isNotEmpty) {
      _orderUpdateController.add(orderId);
    }
  }

  // ── App opened from background notification ────────────────────────────────
  void _onMessageOpenedApp(RemoteMessage message) {
    debugPrint('[FCM] Opened from background: ${message.data}');
    _routeFromMessage(message.data);
  }

  // ── Local notification tap ─────────────────────────────────────────────────
  void _onLocalNotifTap(NotificationResponse response) {
    final payload = response.payload;
    if (payload == null || payload.isEmpty) return;
    debugPrint('[FCM] Local notif tapped, payload: $payload');
    if (payload.startsWith('order:')) {
      _navigateToOrder(payload.substring(6));
    } else if (payload.startsWith('booking:')) {
      _navigateToBookingPayment(payload.substring(8));
    } else {
      _navigateToOrder(payload);
    }
  }

  // ── Route from FCM data ────────────────────────────────────────────────────
  void _routeFromMessage(Map<String, dynamic> data) {
    final type    = data['type']    as String? ?? '';
    final orderId = data['orderId'] as String? ?? '';

    if (type == 'BOOKING_CONFIRMED') {
      final bookingId = data['bookingId'] as String? ?? '';
      if (bookingId.isNotEmpty) _navigateToBookingPayment(bookingId);
      return;
    }
    if (orderId.isNotEmpty) {
      _navigateToOrder(orderId);
    }
  }

  // ── Show local notification ────────────────────────────────────────────────
  Future<void> _showLocalNotification(RemoteMessage message) async {
    final type   = message.data['type'] as String? ?? '';
    final config = _typeConfig[type];

    String title = config?.$1 ?? message.notification?.title ?? 'Back2Eat';
    String body;
    if (config?.$2 != null) {
      body = config!.$2!;
    } else {
      body = message.notification?.body ?? '';
    }

    final orderNumber = message.data['orderNumber'] as String?;
    if (orderNumber != null && type != 'ORDER_STATUS') {
      body = '#$orderNumber — $body';
    }

    final orderId   = message.data['orderId']   as String?;
    final bookingId = message.data['bookingId'] as String?;

    String payload = '';
    if (orderId != null && orderId.isNotEmpty) {
      payload = 'order:$orderId';
    } else if (bookingId != null && bookingId.isNotEmpty) {
      payload = 'booking:$bookingId';
    }

    final notifId = (orderId ?? bookingId ?? message.messageId ?? '')
        .hashCode
        .abs() % 100000;

    await _localNotifs.show(
      notifId,
      title,
      body,
      NotificationDetails(
        android: AndroidNotificationDetails(
          _channelId, _channelName,
          channelDescription: 'Real-time order and booking updates',
          importance: Importance.max,
          priority:   Priority.high,
          playSound:  true,
          enableVibration: true,
          icon: '@mipmap/ic_launcher',
        ),
        iOS: const DarwinNotificationDetails(
          presentAlert: true,
          presentBadge: true,
          presentSound: true,
        ),
      ),
      payload: payload,
    );
  }

  // ── Navigation helpers ─────────────────────────────────────────────────────
  void _navigateToOrder(String orderId) {
    final ctx = navigatorKey?.currentContext;
    if (ctx == null) {
      debugPrint('[FCM] navigatorKey context is null — cannot navigate');
      return;
    }
    GoRouter.of(ctx).push('/order-tracking', extra: orderId);
  }

  void _navigateToBookingPayment(String bookingId) {
    final ctx = navigatorKey?.currentContext;
    if (ctx == null) return;
    GoRouter.of(ctx).push('/booking-payment', extra: bookingId);
  }
}