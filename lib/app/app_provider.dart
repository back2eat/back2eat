import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../core/di/injection.dart';
import '../features/auth/presentation/bloc/auth_bloc.dart';
import '../features/cart/presentation/bloc/cart_bloc.dart';
import '../features/home/presentation/bloc/restaurant_bloc.dart';
import '../features/home/presentation/bloc/restaurant_event.dart';
import '../features/order_type/presentation/cubit/order_type_cubit.dart';

class AppProviders extends StatelessWidget {
  final Widget child;
  const AppProviders({super.key, required this.child});

  @override
  Widget build(BuildContext context) {
    return MultiBlocProvider(
      providers: [
        BlocProvider<OrderTypeCubit>(
          create: (_) => OrderTypeCubit(),
        ),
        BlocProvider<AuthBloc>(
          create: (_) => getIt<AuthBloc>(),
        ),
        BlocProvider<RestaurantBloc>(
          create: (_) =>
          getIt<RestaurantBloc>()..add(const LoadRestaurantsEvent()),
        ),
        BlocProvider<CartBloc>(
          create: (_) => getIt<CartBloc>(),
        ),
      ],
      child: child,
    );
  }
}