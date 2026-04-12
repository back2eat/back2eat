import 'package:get_it/get_it.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../features/auth/data/repositories/auth_repository_impl.dart';
import '../../features/auth/domain/repositories/auth_repository.dart';
import '../../features/auth/presentation/bloc/auth_bloc.dart';

import '../../features/home/data/datasources/restaurant_remote_datasource.dart';
import '../../features/home/data/repositories/restaurant_repository_impl.dart';
import '../../features/home/domain/repositories/restaurant_repository.dart';
import '../../features/home/presentation/bloc/restaurant_bloc.dart';

import '../../features/orders/data/repositories/order_repository_impl.dart';
import '../../features/orders/domain/repositories/order_repository.dart';
import '../../features/orders/presentation/bloc/order_bloc.dart';

import '../../features/cart/presentation/bloc/cart_bloc.dart';

// New features
import '../../features/payments/data/repositories/payment_repository_impl.dart';
import '../../features/payments/domain/repositories/payment_repository.dart';
import '../../features/payments/presentation/bloc/payment_bloc.dart';

import '../../features/bookings/data/repositories/booking_repository_impl.dart';
import '../../features/bookings/domain/repositories/booking_repository.dart';
import '../../features/bookings/presentation/bloc/booking_bloc.dart';

import '../../features/points/data/repositories/points_repository_impl.dart';
import '../../features/points/presentation/bloc/points_cubit.dart';

import '../../features/reviews/data/repositories/reviews_cubit.dart';

import '../network/api_client.dart';
import '../storage/token_storage.dart';

final getIt = GetIt.instance;

Future<void> setupDependencies() async {
  final prefs = await SharedPreferences.getInstance();

  // ── Core ────────────────────────────────────────────────────────────
  getIt.registerLazySingleton<TokenStorage>(() => TokenStorage(prefs));
  getIt.registerLazySingleton<ApiClient>(() => ApiClient(getIt()));

  // ── Auth ─────────────────────────────────────────────────────────────
  getIt.registerLazySingleton<AuthRepository>(
          () => AuthRepositoryImpl(getIt(), getIt()));
  getIt.registerFactory<AuthBloc>(() => AuthBloc(getIt()));

  // ── Home / Restaurants ────────────────────────────────────────────────
  getIt.registerLazySingleton<RestaurantRemoteDatasource>(
          () => RestaurantRemoteDatasource(getIt()));
  getIt.registerLazySingleton<RestaurantRepository>(
          () => RestaurantRepositoryImpl(getIt()));
  getIt.registerFactory<RestaurantBloc>(() => RestaurantBloc(getIt()));

  // ── Orders ────────────────────────────────────────────────────────────
  getIt.registerLazySingleton<OrderRepository>(
          () => OrderRepositoryImpl(getIt(), getIt()));
  getIt.registerFactory<OrderBloc>(() => OrderBloc(getIt()));

  // ── Cart (UI-only, in-memory) ─────────────────────────────────────────
  getIt.registerFactory<CartBloc>(() => CartBloc());

  // ── Payments (Razorpay) ───────────────────────────────────────────────
  getIt.registerLazySingleton<PaymentRepository>(
          () => PaymentRepositoryImpl(getIt()));
  getIt.registerFactory<PaymentBloc>(() => PaymentBloc(getIt()));

  // ── Bookings ─────────────────────────────────────────────────────────
  getIt.registerLazySingleton<BookingRepository>(
          () => BookingRepositoryImpl(getIt()));
  getIt.registerFactory<BookingBloc>(() => BookingBloc(getIt()));

  // ── Points (loyalty) ─────────────────────────────────────────────────
  getIt.registerLazySingleton<PointsRepository>(
          () => PointsRepositoryImpl(getIt()));
  getIt.registerFactory<PointsCubit>(() => PointsCubit(getIt()));

  // ── Reviews ──────────────────────────────────────────────────────────
  getIt.registerLazySingleton<ReviewRepository>(
          () => ReviewRepository(getIt()));
  getIt.registerFactory<ReviewsCubit>(() => ReviewsCubit(getIt()));
}