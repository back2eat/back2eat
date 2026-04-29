import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

import 'app/app.dart';
import 'core/di/injection.dart';
import 'firebase_options.dart';
import 'shared/services/notification_service.dart';

@pragma('vm:entry-point')
Future<void> _firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
  await NotificationService.instance.handleBackgroundMessage(message);
}

void main() async {
  // 1. Necessary for Flutter to interact with the platform
  WidgetsFlutterBinding.ensureInitialized();

  // 2. START THE APP IMMEDIATELY
  // This removes the white screen immediately and shows your splash/loading UI.
  runApp(const Back2EatBootstrap());

  // 3. Run initializations in a separate block so they don't block the UI
  try {
    // Initialize Firebase
    await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);

    // Register background handler
    FirebaseMessaging.onBackgroundMessage(_firebaseMessagingBackgroundHandler);

    // Initialize DI (ApiClient, repos, etc.)
    await setupDependencies();

    // FCM init
    NotificationService.instance.init().catchError((e) {
      debugPrint('FCM init error: $e');
    });

    debugPrint('App Initialized Successfully');
  } catch (e) {
    // If Firebase fails (due to the SHA mismatch), the app stays open
    // instead of staying on a white screen.
    debugPrint('Critical Initialization Error: $e');
  }
}

class Back2EatBootstrap extends StatelessWidget {
  const Back2EatBootstrap({super.key});

  @override
  Widget build(BuildContext context) {
    return ScreenUtilInit(
      designSize: const Size(375, 812),
      minTextAdapt: true,
      splitScreenMode: true,
      // Removed useInheritedMediaQuery: true as it is often
      // the cause of layout freezes in newer Flutter versions.
      builder: (_, __) => const Back2EatApp(),
    );
  }
}