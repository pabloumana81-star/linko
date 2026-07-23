import 'package:go_router/go_router.dart';
import 'package:linko/features/splash/presentation/splash_screen.dart';

abstract final class AppRoutes {
  static const splash = '/';
}

final GoRouter appRouter = GoRouter(
  initialLocation: AppRoutes.splash,
  routes: [
    GoRoute(
      path: AppRoutes.splash,
      builder: (context, state) => const LinkoSplashScreen(),
    ),
  ],
);
