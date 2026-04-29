import 'package:flutter/cupertino.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import '../../core/di/injection.dart';
import '../../features/home/presentation/bloc/restaurant_bloc.dart';
import '../../features/home/presentation/bloc/restaurant_event.dart';
import '../../features/splash/presentation/pages/splash_page.dart';
import '../../features/start/presentation/pages/start_page.dart';
import '../../features/auth/presentation/pages/signin_page.dart';
import '../../features/auth/presentation/pages/signup_page.dart';
import '../../features/home/presentation/pages/categories_page.dart';
import '../../features/home/presentation/pages/partners_page.dart';
import '../../features/home/presentation/pages/home_page.dart';
import '../../features/home/presentation/pages/restaurant_detail_page.dart';
import '../../features/cart/presentation/pages/cart_page.dart';
import '../../features/checkout/presentation/pages/checkout_page.dart';
import '../../features/profile/presentation/pages/profile_page.dart';
import '../../features/orders/presentation/pages/order_tracking_page.dart';
import '../../features/orders/presentation/pages/order_history_page.dart';
import '../../features/bookings/presentation/pages/bookings_page.dart';
import '../../features/points/presentation/pages/points_page.dart';
import '../../features/reviews/presentation/pages/submit_review_page.dart';
import '../../shared/services/notification_service.dart';

class AppRouter {
  // Create nav key independently — do NOT read NotificationService here
  static final GlobalKey<NavigatorState> _navKey = GlobalKey<NavigatorState>();

  static final GoRouter router = GoRouter(
    initialLocation: '/splash',
    navigatorKey: _navKey,
    observers: [_NotifNavObserver()],
    routes: [
      GoRoute(path: '/splash', builder: (_, __) => const SplashPage()),
      GoRoute(path: '/start',  builder: (_, __) => const StartPage()),
      GoRoute(path: '/signin', builder: (_, __) => const SignInPage()),
      GoRoute(
        path: '/signup',
        builder: (_, state) =>
            SignUpPage(prefillMobile: state.extra as String?),
      ),
      GoRoute(path: '/home',       builder: (_, __) => const HomePage()),
      GoRoute(path: '/categories', builder: (_, __) => const CategoriesPage()),
      GoRoute(
        path: '/partners',
        builder: (_, state) {
          final category = state.uri.queryParameters['category'];
          return PartnersPage(category: category);
        },
      ),
      GoRoute(
        path: '/restaurant/:id',
        builder: (context, state) {
          final id               = state.pathParameters['id']!;
          final selectedBranchId = state.extra as String?;
          return BlocProvider(
            create: (_) => getIt<RestaurantBloc>()
              ..add(LoadRestaurantDetailEvent(
                restaurantId:     id,
                selectedBranchId: selectedBranchId,
              )),
            child: RestaurantDetailPage(
              restaurantId:     id,
              selectedBranchId: selectedBranchId,
            ),
          );
        },
      ),
      GoRoute(path: '/cart',     builder: (_, __) => const CartPage()),
      GoRoute(path: '/checkout', builder: (_, __) => const CheckoutPage()),
      GoRoute(path: '/profile',  builder: (_, __) => const ProfilePage()),
      GoRoute(
        path: '/order-tracking',
        builder: (_, state) =>
            OrderTrackingPage(orderId: state.extra as String?),
      ),
      GoRoute(
        path: '/order-history',
        builder: (_, __) => const OrderHistoryPage(),
      ),
      GoRoute(path: '/bookings', builder: (_, __) => const BookingsPage()),
      GoRoute(path: '/points',   builder: (_, __) => const PointsPage()),
      GoRoute(
        path: '/review',
        builder: (_, state) {
          final extra = state.extra as Map<String, String>;
          return SubmitReviewPage(
            orderId:        extra['orderId']!,
            restaurantName: extra['restaurantName'] ?? 'Restaurant',
          );
        },
      ),
    ],
  );
}

/// Keeps NotificationService.navigatorKey in sync after router builds
class _NotifNavObserver extends NavigatorObserver {
  @override
  void didPush(Route route, Route? previousRoute) {
    NotificationService.instance.navigatorKey =
        AppRouter._navKey;
  }
}