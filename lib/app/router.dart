import 'package:go_router/go_router.dart';
import 'package:linko/features/auth/presentation/user_type_screen.dart';
import 'package:linko/features/auth/presentation/welcome_screen.dart';
import 'package:linko/features/home/presentation/data/placeholder_professionals.dart';
import 'package:linko/features/home/presentation/category_placeholder_screen.dart';
import 'package:linko/features/home/presentation/create_request_screen.dart';
import 'package:linko/features/home/presentation/guest_home_screen.dart';
import 'package:linko/features/home/presentation/models/professional_profile_data.dart';
import 'package:linko/features/home/presentation/professional_home_screen.dart';
import 'package:linko/features/home/presentation/professional_profile_screen.dart';
import 'package:linko/features/home/presentation/professionals_results_screen.dart';
import 'package:linko/features/home/presentation/search_screen.dart';
import 'package:linko/features/splash/presentation/splash_screen.dart';

abstract final class AppRoutes {
  static const splash = '/';
  static const welcome = '/welcome';
  static const userType = '/user-type';
  static const guestHome = '/guest-home';
  static const search = '/search';
  static const category = '/category/:categoryName';
  static const createRequest = '/create-request';
  static const professionalHome = '/professional-home';
  static const professionalProfile = '/professional/:professionalName';
  static const results = '/results/:serviceName';
}

abstract final class AppRouteNames {
  static const category = 'category';
  static const professionalProfile = 'professional-profile';
  static const results = 'results';
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
        return WelcomeScreen(
          onContinue: () => context.push(AppRoutes.userType),
        );
      },
    ),
    GoRoute(
      path: AppRoutes.userType,
      builder: (context, state) {
        return UserTypeScreen(
          onCustomerSelected: () => context.push(AppRoutes.guestHome),
          onProfessionalSelected: () {
            context.push(AppRoutes.professionalHome);
          },
        );
      },
    ),
    GoRoute(
      path: AppRoutes.guestHome,
      builder: (context, state) {
        return GuestHomeScreen(
          onCategorySelected: (categoryName) {
            context.pushNamed(
              AppRouteNames.results,
              pathParameters: {'serviceName': categoryName},
            );
          },
          onCreateRequest: () => context.push(AppRoutes.createRequest),
          onSearchRequested: () {
            context.push(AppRoutes.search, extra: true);
          },
          onSearchTabSelected: () {
            context.go(AppRoutes.search);
          },
          onProfessionalSelected: (professional) {
            context.pushNamed(
              AppRouteNames.professionalProfile,
              pathParameters: {'professionalName': professional.name},
              extra: professional,
            );
          },
        );
      },
    ),
    GoRoute(
      path: AppRoutes.search,
      builder: (context, state) {
        return SearchScreen(
          showBackButton: state.extra == true,
          onHomeSelected: () => context.go(AppRoutes.guestHome),
          onProfessionalSelected: (professional) {
            context.pushNamed(
              AppRouteNames.professionalProfile,
              pathParameters: {'professionalName': professional.name},
              extra: professional,
            );
          },
          onResultsRequested: (serviceName) {
            context.pushNamed(
              AppRouteNames.results,
              pathParameters: {'serviceName': serviceName},
            );
          },
        );
      },
    ),
    GoRoute(
      path: AppRoutes.results,
      name: AppRouteNames.results,
      builder: (context, state) {
        return ProfessionalsResultsScreen(
          selectedService: state.pathParameters['serviceName']!,
          onProfessionalSelected: (professional) {
            context.pushNamed(
              AppRouteNames.professionalProfile,
              pathParameters: {'professionalName': professional.name},
              extra: professional,
            );
          },
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
    GoRoute(
      path: AppRoutes.professionalProfile,
      name: AppRouteNames.professionalProfile,
      builder: (context, state) {
        final professionalName = state.pathParameters['professionalName']!;
        final professional =
            state.extra as ProfessionalProfileData? ??
            placeholderProfessionals.firstWhere(
              (item) => item.name == professionalName,
              orElse: () => placeholderProfessionals.first,
            );

        return ProfessionalProfileScreen(professional: professional);
      },
    ),
  ],
);
