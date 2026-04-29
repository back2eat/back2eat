import 'package:flutter/material.dart';
import '../core/theme/app_theme.dart';
import '../shared/utils/location_permission_helper.dart';
import 'app_provider.dart';
import 'router/app_router.dart';

class Back2EatApp extends StatefulWidget {
  const Back2EatApp({super.key});

  @override
  State<Back2EatApp> createState() => _Back2EatAppState();
}

class _Back2EatAppState extends State<Back2EatApp> {
  @override
  void initState() {
    super.initState();

  }

  @override
  Widget build(BuildContext context) {
    return AppProviders(
      child: MaterialApp.router(
        title: 'Back2Eat',
        debugShowCheckedModeBanner: false,
        theme: AppTheme.light(),
        routerConfig: AppRouter.router,
      ),
    );
  }
}