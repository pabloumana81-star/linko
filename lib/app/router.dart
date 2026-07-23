import 'package:go_router/go_router.dart';
import 'package:linko/features/auth/presentation/user_type_screen.dart';
import 'package:linko/features/auth/presentation/welcome_screen.dart';
import 'package:linko/features/home/presentation/category_placeholder_screen.dart';
import 'package:linko/features/home/presentation/create_request_screen.dart';
import 'package:linko/features/home/presentation/guest_home_screen.dart';
import 'package:linko/features/home/presentation/professional_home_screen.dart';
import 'package:linko/features/splash/presentation/splash_screen.dart';

abstract final class AppRoutes {
  static const splash = '/';
  static const welcome = '/welcome';
  static const userType = '/user-type';
  static const guestHome = '/guest-home';
  static const category = '/category/:categoryName';
  static const createRequest = '/create-request';
  static const professionalHome = '/professional-home';
}

abstract final class AppRouteNames {
  static const category = 'category';
}

final GoRouter appRouter = GoRouter(
  initialLocation: AppRoutes.splash,
  routes: [
    GoRoute(
      path: AppRoutes.splash,
      builder: (context, state) {
        return LinkoSplashScreen(
          onComplete: () => context.go(AppRoutes.welcome),
        );
      },
    ),
    GoRoute(
      path: AppRoutes.welcome,
      builder: (context, state) {
        return WelcomeScreen(onContinue: () => context.go(AppRoutes.userType));
      },
    ),
    GoRoute(
      path: AppRoutes.userType,
      builder: (context, state) {
        return UserTypeScreen(
          onCustomerSelected: () => context.go(AppRoutes.guestHome),
          onProfessionalSelected: () {
            context.go(AppRoutes.professionalHome);
          },
        );
      },
    ),
    GoRoute(
      path: AppRoutes.guestHome,
      builder: (context, state) {
        return GuestHomeScreen(
          onCategorySelected: (categoryName) {
            context.goNamed(
              AppRouteNames.category,
              pathParameters: {'categoryName': categoryName},
            );
          },
          onCreateRequest: () => context.go(AppRoutes.createRequest),
        );
      },
    ),
    GoRoute(
      path: AppRoutes.category,
      name: AppRouteNames.category,
      builder: (context, state) {
        return CategoryPlaceholderScreen(
          categoryName: state.pathParameters['categoryName']!,
        );
      },
    ),
    GoRoute(
      path: AppRoutes.createRequest,
      builder: (context, state) => const CreateRequestScreen(),
    ),
    GoRoute(
      path: AppRoutes.professionalHome,
      builder: (context, state) => const ProfessionalHomeScreen(),
    ),
  ],
);
