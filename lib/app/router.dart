import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:linko/features/auth/presentation/user_type_screen.dart';
import 'package:linko/features/auth/presentation/welcome_screen.dart';
import 'package:linko/features/home/presentation/data/placeholder_professionals.dart';
import 'package:linko/features/home/presentation/data/placeholder_incoming_requests.dart';
import 'package:linko/features/home/presentation/category_placeholder_screen.dart';
import 'package:linko/features/home/presentation/confirm_request_screen.dart';
import 'package:linko/features/home/presentation/create_request_screen.dart';
import 'package:linko/features/home/presentation/customer_requests_screen.dart';
import 'package:linko/features/home/presentation/guest_home_screen.dart';
import 'package:linko/features/home/presentation/models/professional_profile_data.dart';
import 'package:linko/features/home/presentation/models/incoming_service_request.dart';
import 'package:linko/features/home/presentation/models/request_draft.dart';
import 'package:linko/features/home/presentation/models/quotation_draft.dart';
import 'package:linko/features/home/presentation/professional_home_screen.dart';
import 'package:linko/features/home/presentation/professional_profile_screen.dart';
import 'package:linko/features/home/presentation/professional_request_detail_screen.dart';
import 'package:linko/features/home/presentation/professional_requests_screen.dart';
import 'package:linko/features/home/presentation/providers/professional_requests_provider.dart';
import 'package:linko/features/home/presentation/professionals_results_screen.dart';
import 'package:linko/features/home/presentation/quotation_form_screen.dart';
import 'package:linko/features/home/presentation/quotation_review_screen.dart';
import 'package:linko/features/home/presentation/quotation_success_screen.dart';
import 'package:linko/features/home/presentation/request_service_screen.dart';
import 'package:linko/features/home/presentation/request_success_screen.dart';
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
  static const requestService = '/request-service/:professionalName';
  static const confirmRequest = '/confirm-request';
  static const requestSuccess = '/request-success';
  static const customerRequests = '/customer-requests';
  static const professionalRequests = '/professional/requests';
  static const professionalRequestDetail = '/professional/requests/:requestId';
  static const professionalQuotation =
      '/professional/requests/:requestId/quotation';
  static const professionalQuotationReview =
      '/professional/requests/:requestId/quotation/review';
  static const professionalQuotationSuccess =
      '/professional/requests/:requestId/quotation/success';
}

abstract final class AppRouteNames {
  static const category = 'category';
  static const professionalProfile = 'professional-profile';
  static const results = 'results';
  static const requestService = 'request-service';
  static const professionalRequestDetail = 'professional-request-detail';
  static const professionalQuotation = 'professional-quotation';
  static const professionalQuotationReview = 'professional-quotation-review';
  static const professionalQuotationSuccess = 'professional-quotation-success';
}

IncomingServiceRequest _incomingRequestFromState(GoRouterState state) {
  final requestId = state.pathParameters['requestId']!;

  final extra = state.extra;
  if (extra is IncomingServiceRequest) {
    return extra;
  }
  return placeholderIncomingRequests.firstWhere(
    (request) => request.id == requestId,
    orElse: () => placeholderIncomingRequests.first,
  );
}

ProfessionalProfileData _professionalFromState(GoRouterState state) {
  final professionalName = state.pathParameters['professionalName']!;

  return state.extra as ProfessionalProfileData? ??
      placeholderProfessionals.firstWhere(
        (item) => item.name == professionalName,
        orElse: () => placeholderProfessionals.first,
      );
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
          onRequestsSelected: () {
            context.go(AppRoutes.customerRequests);
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
          onRequestsSelected: () {
            context.go(AppRoutes.customerRequests);
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
      builder: (context, state) {
        return ProfessionalHomeScreen(
          onRequestsSelected: () {
            context.go(AppRoutes.professionalRequests);
          },
          onRequestSelected: (request) {
            context.pushNamed(
              AppRouteNames.professionalRequestDetail,
              pathParameters: {'requestId': request.id},
              extra: request,
            );
          },
        );
      },
    ),
    GoRoute(
      path: AppRoutes.professionalRequests,
      builder: (context, state) {
        return ProfessionalRequestsScreen(
          onHomeSelected: () => context.go(AppRoutes.professionalHome),
          onRequestSelected: (request) {
            context.pushNamed(
              AppRouteNames.professionalRequestDetail,
              pathParameters: {'requestId': request.id},
              extra: request,
            );
          },
        );
      },
    ),
    GoRoute(
      path: AppRoutes.professionalRequestDetail,
      name: AppRouteNames.professionalRequestDetail,
      builder: (context, state) {
        final request = _incomingRequestFromState(state);

        return ProfessionalRequestDetailScreen(
          request: request,
          onSendQuotation: (selectedRequest) {
            final quotation = ProviderScope.containerOf(
              context,
              listen: false,
            ).read(professionalRequestsProvider).quotations[selectedRequest.id];
            if (quotation == null) {
              context.pushNamed(
                AppRouteNames.professionalQuotation,
                pathParameters: {'requestId': selectedRequest.id},
                extra: selectedRequest,
              );
            } else {
              context.pushNamed(
                AppRouteNames.professionalQuotationReview,
                pathParameters: {'requestId': selectedRequest.id},
                extra: quotation,
              );
            }
          },
        );
      },
    ),
    GoRoute(
      path: AppRoutes.professionalQuotation,
      name: AppRouteNames.professionalQuotation,
      builder: (context, state) {
        final request = _incomingRequestFromState(state);
        return QuotationFormScreen(
          request: request,
          onReview: (draft) {
            context.pushNamed(
              AppRouteNames.professionalQuotationReview,
              pathParameters: {'requestId': request.id},
              extra: draft,
            );
          },
        );
      },
    ),
    GoRoute(
      path: AppRoutes.professionalQuotationReview,
      name: AppRouteNames.professionalQuotationReview,
      builder: (context, state) {
        final request = _incomingRequestFromState(state);
        final stored = ProviderScope.containerOf(
          context,
          listen: false,
        ).read(professionalRequestsProvider).quotations[request.id];
        final draft = state.extra as QuotationDraft? ?? stored;
        if (draft == null) {
          return QuotationFormScreen(
            request: request,
            onReview: (newDraft) {
              context.pushNamed(
                AppRouteNames.professionalQuotationReview,
                pathParameters: {'requestId': request.id},
                extra: newDraft,
              );
            },
          );
        }
        return QuotationReviewScreen(
          request: request,
          draft: draft,
          onEdit: () {
            if (stored == null) {
              context.pop();
            }
          },
          onSend: () {
            final sent = ProviderScope.containerOf(
              context,
              listen: false,
            ).read(professionalRequestsProvider.notifier).sendQuotation(draft);
            if (!sent) {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('Esta solicitud ya tiene una cotización.'),
                ),
              );
              return;
            }
            context.goNamed(
              AppRouteNames.professionalQuotationSuccess,
              pathParameters: {'requestId': request.id},
              extra: request.customerName,
            );
          },
        );
      },
    ),
    GoRoute(
      path: AppRoutes.professionalQuotationSuccess,
      name: AppRouteNames.professionalQuotationSuccess,
      builder: (context, state) {
        final customerName =
            state.extra as String? ??
            _incomingRequestFromState(state).customerName;
        return QuotationSuccessScreen(
          customerName: customerName,
          onViewRequests: () => context.go(AppRoutes.professionalRequests),
          onBackHome: () => context.go(AppRoutes.professionalHome),
        );
      },
    ),
    GoRoute(
      path: AppRoutes.professionalProfile,
      name: AppRouteNames.professionalProfile,
      builder: (context, state) {
        final professional = _professionalFromState(state);

        return ProfessionalProfileScreen(
          professional: professional,
          onRequestService: () {
            context.pushNamed(
              AppRouteNames.requestService,
              pathParameters: {'professionalName': professional.name},
              extra: professional,
            );
          },
        );
      },
    ),
    GoRoute(
      path: AppRoutes.requestService,
      name: AppRouteNames.requestService,
      builder: (context, state) {
        final professional = _professionalFromState(state);

        return RequestServiceScreen(
          professional: professional,
          onContinue: (draft) {
            context.push(AppRoutes.confirmRequest, extra: draft);
          },
        );
      },
    ),
    GoRoute(
      path: AppRoutes.confirmRequest,
      builder: (context, state) {
        return ConfirmRequestScreen(
          draft: state.extra! as RequestDraft,
          onSubmit: () {
            final draft = state.extra! as RequestDraft;
            context.go(
              AppRoutes.requestSuccess,
              extra: draft.professional.name,
            );
          },
        );
      },
    ),
    GoRoute(
      path: AppRoutes.requestSuccess,
      builder: (context, state) {
        return RequestSuccessScreen(
          professionalName: state.extra! as String,
          onViewRequests: () => context.go(AppRoutes.customerRequests),
          onBackHome: () => context.go(AppRoutes.guestHome),
        );
      },
    ),
    GoRoute(
      path: AppRoutes.customerRequests,
      builder: (context, state) {
        return CustomerRequestsScreen(
          onHomeSelected: () => context.go(AppRoutes.guestHome),
          onSearchSelected: () => context.go(AppRoutes.search),
        );
      },
    ),
  ],
);
