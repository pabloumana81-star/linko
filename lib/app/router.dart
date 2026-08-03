import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:linko/features/auth/presentation/user_type_screen.dart';
import 'package:linko/features/auth/presentation/welcome_screen.dart';
import 'package:linko/features/auth/presentation/auth_controller.dart';
import 'package:linko/app/app_mode.dart';
import 'package:linko/app/app_mode_provider.dart';
import 'package:linko/features/home/presentation/data/placeholder_professionals.dart';
import 'package:linko/features/home/presentation/category_placeholder_screen.dart';
import 'package:linko/features/home/presentation/confirm_request_screen.dart';
import 'package:linko/features/home/presentation/conversation_screen.dart';
import 'package:linko/features/home/presentation/create_request_screen.dart';
import 'package:linko/features/home/presentation/customer_request_detail_screen.dart';
import 'package:linko/features/home/presentation/customer_quotation_screen.dart';
import 'package:linko/features/home/presentation/customer_requests_screen.dart';
import 'package:linko/features/home/presentation/guest_home_screen.dart';
import 'package:linko/features/home/presentation/mode_profile_screen.dart';
import 'package:linko/features/home/presentation/models/professional_profile_data.dart';
import 'package:linko/features/home/presentation/models/customer_service_request.dart';
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
import 'package:linko/features/requests/presentation/adapters/request_view_adapters.dart';
import 'package:linko/features/requests/presentation/providers/request_providers.dart';
import 'package:linko/features/requests/domain/models/conversation_message.dart';
import 'package:linko/features/requests/domain/models/app_user.dart';
import 'package:linko/features/requests/domain/models/professional_profile.dart';
import 'package:linko/features/requests/domain/models/request_state.dart';
import 'package:linko/features/requests/domain/models/service_request.dart';
import 'package:linko/features/requests/domain/models/service_rating.dart';
import 'package:linko/core/backend/backend_providers.dart';
import 'package:linko/core/backend/backend_config.dart';

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
  static const customerModeProfile = '/customer-profile';
  static const customerRequestDetail = '/customer-requests/:requestId';
  static const customerQuotation = '/customer-requests/:requestId/quotation';
  static const customerConversation =
      '/customer-requests/:requestId/conversation';
  static const professionalRequests = '/professional/requests';
  static const professionalModeProfile = '/professional-profile';
  static const professionalRequestDetail = '/professional/requests/:requestId';
  static const professionalConversation =
      '/professional/requests/:requestId/conversation';
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
  static const customerRequestDetail = 'customer-request-detail';
  static const customerQuotation = 'customer-quotation';
  static const customerConversation = 'customer-conversation';
  static const professionalConversation = 'professional-conversation';
}

IncomingServiceRequest _incomingRequestFromState(
  BuildContext context,
  GoRouterState state,
) {
  final requestId = state.pathParameters['requestId']!;

  final extra = state.extra;
  if (extra is IncomingServiceRequest) {
    return extra;
  }
  return ProviderScope.containerOf(
    context,
    listen: false,
  ).read(requestDetailProvider(requestId))!.toIncomingRequest();
}

ServiceCategory _serviceCategoryFor(String profession) {
  final normalized = profession.toLowerCase();
  if (normalized.contains('electric')) {
    return ServiceCategory.electrical;
  }
  if (normalized.contains('plomer')) {
    return ServiceCategory.plumbing;
  }
  if (normalized.contains('limpieza')) {
    return ServiceCategory.cleaning;
  }
  if (normalized.contains('aire acondicionado')) {
    return ServiceCategory.airConditioning;
  }
  return ServiceCategory.maintenance;
}

ProfessionalProfileData _professionalFromState(GoRouterState state) {
  final professionalName = state.pathParameters['professionalName']!;

  return state.extra as ProfessionalProfileData? ??
      placeholderProfessionals.firstWhere(
        (item) => item.name == professionalName,
        orElse: () => placeholderProfessionals.first,
      );
}

CustomerServiceRequest _customerRequestFromState(
  BuildContext context,
  GoRouterState state,
) {
  final extra = state.extra;
  if (extra is CustomerServiceRequest) {
    return extra;
  }
  final requestId = state.pathParameters['requestId']!;
  return ProviderScope.containerOf(
    context,
    listen: false,
  ).read(requestDetailProvider(requestId))!.toCustomerRequest();
}

String? _scheduledDateLabel(List<ConversationMessage> messages) {
  for (final message in messages.reversed) {
    if (message.type == ConversationMessageType.scheduleProposal &&
        message.scheduleStatus == ScheduleProposalStatus.confirmed) {
      return message.scheduleLabel;
    }
  }
  return null;
}

void _sendConversationMessage(
  BuildContext context,
  String requestId,
  String text,
  bool asProfessional,
) {
  final container = ProviderScope.containerOf(context, listen: false);
  container
      .read(requestRepositoryProvider)
      .sendMessage(
        ConversationMessage(
          id: '$requestId-local-${DateTime.now().microsecondsSinceEpoch}',
          requestId: requestId,
          author: asProfessional
              ? MessageAuthor.professional
              : MessageAuthor.customer,
          text: text,
          timeLabel: 'Ahora',
        ),
      );
  container
    ..invalidate(conversationProvider(requestId))
    ..invalidate(requestDetailProvider(requestId))
    ..invalidate(customerRequestsProvider)
    ..invalidate(professionalRequestsProvider);
}

void _invalidateScheduleData(ProviderContainer container, String requestId) {
  container
    ..invalidate(conversationProvider(requestId))
    ..invalidate(requestDetailProvider(requestId))
    ..invalidate(customerRequestsProvider)
    ..invalidate(professionalRequestsProvider)
    ..invalidate(timelineProvider(requestId))
    ..invalidate(professionalRequestFlowProvider);
}

void _popOrGo(BuildContext context, String fallbackLocation) {
  final navigator = Navigator.of(context);
  if (navigator.canPop()) {
    navigator.pop();
  } else {
    context.go(fallbackLocation);
  }
}

void _goToAuthenticatedHome(
  BuildContext context,
  ProviderContainer container,
  AuthState auth,
) {
  final AppMode mode =
      auth.user?.activeMode ??
      container.read(appModeProvider) ??
      AppMode.customer;
  container.read(appModeProvider.notifier).select(mode);
  context.go(
    mode == AppMode.customer ? AppRoutes.guestHome : AppRoutes.professionalHome,
  );
}

Future<void> _signOut(BuildContext context) async {
  final container = ProviderScope.containerOf(context, listen: false);
  await container.read(authControllerProvider.notifier).signOut();
  if (context.mounted) {
    context.go(AppRoutes.welcome);
  }
}

final GoRouter appRouter = GoRouter(
  initialLocation: AppRoutes.splash,
  routes: [
    GoRoute(
      path: AppRoutes.splash,
      builder: (context, state) {
        return Consumer(
          builder: (context, ref, child) {
            ref.watch(authControllerProvider);
            return LinkoSplashScreen(
              onComplete: () async {
                final notifier = ref.read(authControllerProvider.notifier);
                await notifier.restoreSession();
                if (!context.mounted) {
                  return;
                }
                final auth = ref.read(authControllerProvider);
                if (auth.status == AuthStatus.authenticated) {
                  _goToAuthenticatedHome(
                    context,
                    ProviderScope.containerOf(context, listen: false),
                    auth,
                  );
                } else {
                  context.go(AppRoutes.welcome);
                }
              },
            );
          },
        );
      },
    ),
    GoRoute(
      path: AppRoutes.welcome,
      builder: (context, state) {
        return Consumer(
          builder: (context, ref, child) {
            final auth = ref.watch(authControllerProvider);
            final notifier = ref.read(authControllerProvider.notifier);
            Future<void> authenticate(Future<void> Function() action) async {
              await action();
              if (!context.mounted) {
                return;
              }
              final updated = ref.read(authControllerProvider);
              if (updated.status == AuthStatus.authenticated) {
                _goToAuthenticatedHome(
                  context,
                  ProviderScope.containerOf(context, listen: false),
                  updated,
                );
              }
            }

            return WelcomeScreen(
              isLoading: auth.status == AuthStatus.loading,
              message: auth.message,
              errorMessage: auth.error == null
                  ? null
                  : 'No fue posible iniciar sesión. Intenta nuevamente.',
              onContinueAsGuest: () {
                notifier.continueAsGuest();
                context.push(AppRoutes.userType);
              },
              onGoogleSignIn: () => authenticate(notifier.signInWithGoogle),
              onAppleSignIn: () => authenticate(notifier.signInWithApple),
              onSendEmailLink: notifier.sendEmailLink,
            );
          },
        );
      },
    ),
    GoRoute(
      path: AppRoutes.userType,
      builder: (context, state) {
        return UserTypeScreen(
          onCustomerSelected: () {
            ProviderScope.containerOf(
              context,
              listen: false,
            ).read(appModeProvider.notifier).select(AppMode.customer);
            ProviderScope.containerOf(context, listen: false)
                .read(authControllerProvider.notifier)
                .updateActiveMode(AppMode.customer);
            context.go(AppRoutes.guestHome);
          },
          onProfessionalSelected: () {
            ProviderScope.containerOf(
              context,
              listen: false,
            ).read(appModeProvider.notifier).select(AppMode.professional);
            ProviderScope.containerOf(context, listen: false)
                .read(authControllerProvider.notifier)
                .updateActiveMode(AppMode.professional);
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
          onProfileSelected: () {
            context.go(AppRoutes.customerModeProfile);
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
          onProfileSelected: () {
            context.go(AppRoutes.customerModeProfile);
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
          onProfileSelected: () {
            context.go(AppRoutes.professionalModeProfile);
          },
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
      pageBuilder: (context, state) {
        final quotationSent = state.extra == true;
        return CustomTransitionPage<void>(
          key: state.pageKey,
          transitionDuration: const Duration(milliseconds: 250),
          child: ProfessionalRequestsScreen(
            showQuotedInitially: quotationSent,
            showSentConfirmation: quotationSent,
            onProfileSelected: () {
              context.go(AppRoutes.professionalModeProfile);
            },
            onHomeSelected: () => context.go(AppRoutes.professionalHome),
            onRequestSelected: (request) {
              context.pushNamed(
                AppRouteNames.professionalRequestDetail,
                pathParameters: {'requestId': request.id},
                extra: request,
              );
            },
          ),
          transitionsBuilder: (context, animation, secondaryAnimation, child) {
            return FadeTransition(opacity: animation, child: child);
          },
        );
      },
    ),
    GoRoute(
      path: AppRoutes.professionalModeProfile,
      builder: (context, state) {
        return ModeProfileScreen(
          mode: AppMode.professional,
          onChangeMode: () {
            ProviderScope.containerOf(
              context,
              listen: false,
            ).read(appModeProvider.notifier).select(AppMode.customer);
            ProviderScope.containerOf(context, listen: false)
                .read(authControllerProvider.notifier)
                .updateActiveMode(AppMode.customer);
            context.go(AppRoutes.guestHome);
          },
          onSignOut: () => _signOut(context),
          onHomeSelected: () => context.go(AppRoutes.professionalHome),
          onRequestsSelected: () => context.go(AppRoutes.professionalRequests),
        );
      },
    ),
    GoRoute(
      path: AppRoutes.professionalRequestDetail,
      name: AppRouteNames.professionalRequestDetail,
      builder: (context, state) {
        final request = _incomingRequestFromState(context, state);

        return ProfessionalRequestDetailScreen(
          request: request,
          onBack: () => _popOrGo(context, AppRoutes.professionalRequests),
          onStartJob: (selectedRequest) {
            final container = ProviderScope.containerOf(context, listen: false);
            container
                .read(requestRepositoryProvider)
                .startJob(selectedRequest.id);
            _invalidateScheduleData(container, selectedRequest.id);
          },
          onMarkJobCompleted: (selectedRequest) {
            final container = ProviderScope.containerOf(context, listen: false);
            container
                .read(requestRepositoryProvider)
                .markJobCompleted(selectedRequest.id);
            _invalidateScheduleData(container, selectedRequest.id);
          },
          onOpenConversation: (selectedRequest) {
            context.pushNamed(
              AppRouteNames.professionalConversation,
              pathParameters: {'requestId': selectedRequest.id},
              extra: selectedRequest,
            );
          },
          onSendQuotation: (selectedRequest) {
            final quotation = ProviderScope.containerOf(context, listen: false)
                .read(professionalRequestFlowProvider)
                .quotations[selectedRequest.id];
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
      path: AppRoutes.professionalConversation,
      name: AppRouteNames.professionalConversation,
      builder: (context, state) {
        final request = _incomingRequestFromState(context, state);
        return Consumer(
          builder: (context, ref, child) {
            final isMock =
                ref.watch(backendRepositoriesProvider).mode == BackendMode.mock;
            final persisted = isMock
                ? null
                : ref.watch(persistedRequestDetailProvider(request.id));
            if (persisted?.isLoading ?? false) {
              return const Scaffold(
                body: Center(child: CircularProgressIndicator()),
              );
            }
            if (persisted?.hasError ?? false) {
              return const Scaffold(
                body: Center(child: Text('No pudimos cargar la conversación.')),
              );
            }
            final serviceRequest = persisted?.value;
            return ConversationScreen(
              requestId: request.id,
              counterpartName: request.customerName,
              serviceName: request.serviceCategory,
              requestStatus: request.status,
              perspective: ConversationPerspective.professional,
              initialMessages: isMock
                  ? ref.watch(conversationProvider(request.id))
                  : const [],
              realtime: serviceRequest == null
                  ? null
                  : ConversationRealtimeConfig(
                      repository: ref.watch(conversationsRepositoryProvider),
                      customerId: serviceRequest.customer.id,
                      professionalId: serviceRequest.professional.id,
                      senderId: serviceRequest.professional.id,
                    ),
              onBack: () => _popOrGo(context, AppRoutes.professionalRequests),
              onSendMessage: isMock
                  ? (text) => _sendConversationMessage(
                      context,
                      request.id,
                      text,
                      true,
                    )
                  : null,
              onProposeSchedule: isMock
                  ? (scheduleLabel) {
                      final container = ProviderScope.containerOf(
                        context,
                        listen: false,
                      );
                      container
                          .read(requestRepositoryProvider)
                          .proposeSchedule(request.id, scheduleLabel);
                      _invalidateScheduleData(container, request.id);
                    }
                  : null,
            );
          },
        );
      },
    ),
    GoRoute(
      path: AppRoutes.professionalQuotation,
      name: AppRouteNames.professionalQuotation,
      builder: (context, state) {
        final request = _incomingRequestFromState(context, state);
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
        final request = _incomingRequestFromState(context, state);
        final stored = ProviderScope.containerOf(
          context,
          listen: false,
        ).read(professionalRequestFlowProvider).quotations[request.id];
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
            final sent = ProviderScope.containerOf(context, listen: false)
                .read(professionalRequestFlowProvider.notifier)
                .sendQuotation(draft);
            if (!sent) {
              final messenger = ScaffoldMessenger.of(context);
              messenger.removeCurrentSnackBar();
              messenger.showSnackBar(
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
        return QuotationSuccessScreen(
          onViewRequests: () =>
              context.go(AppRoutes.professionalRequests, extra: true),
        );
      },
    ),
    GoRoute(
      path: AppRoutes.professionalProfile,
      name: AppRouteNames.professionalProfile,
      builder: (context, state) {
        final professional = _professionalFromState(state);

        return Consumer(
          builder: (context, ref, child) {
            final summary = ref.watch(
              professionalRatingSummaryProvider(professional.id),
            );
            final currentProfessional = professional.copyWith(
              rating: summary.averageRating,
              reviewCount: summary.reviewCount,
            );
            return ProfessionalProfileScreen(
              professional: currentProfessional,
              completedJobsCount: summary.completedJobsCount,
              onRequestService: () {
                context.pushNamed(
                  AppRouteNames.requestService,
                  pathParameters: {'professionalName': professional.name},
                  extra: currentProfessional,
                );
              },
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
          onSubmit: () async {
            final draft = state.extra! as RequestDraft;
            final container = ProviderScope.containerOf(context, listen: false);
            final now = DateTime.now();
            final request = ServiceRequest(
              id: 'request-${now.microsecondsSinceEpoch}',
              customer: const AppUser(
                id: currentCustomerId,
                name: 'Cliente LinkO',
              ),
              professional: ProfessionalProfile(
                id: 'profile-${draft.professional.id}',
                user: AppUser(
                  id: draft.professional.id,
                  name: draft.professional.name,
                ),
                profession: draft.professional.profession,
                rating: draft.professional.rating,
                reviewCount: draft.professional.reviewCount,
                location: draft.professional.location,
              ),
              serviceName: draft.professional.profession,
              category: _serviceCategoryFor(draft.professional.profession),
              description: draft.description,
              location: draft.location,
              availabilityLabel:
                  draft.selectedDate?.spanishDate ?? draft.timing.label,
              state: RequestState.pending,
              updatedAt: now,
              createdAtLabel: 'Ahora',
              memberSinceLabel: 'Miembro desde 2026',
              attachedPhotoCount: draft.attachedPhotoCount,
              scheduledAt: draft.selectedDate,
              createdAt: now.toUtc(),
            );
            await container
                .read(activeServiceRequestsRepositoryProvider)
                .createRequest(request);
            container
              ..invalidate(persistedCustomerRequestsProvider)
              ..invalidate(persistedProfessionalRequestsProvider)
              ..invalidate(persistedRequestDetailProvider(request.id))
              ..invalidate(customerRequestsProvider)
              ..invalidate(professionalRequestsProvider)
              ..invalidate(requestDetailProvider(request.id))
              ..invalidate(professionalRequestFlowProvider);
            if (context.mounted) {
              context.go(
                AppRoutes.requestSuccess,
                extra: draft.professional.name,
              );
            }
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
        CustomerRequestsScreen buildScreen(
          List<CustomerServiceRequest> requests,
        ) {
          return CustomerRequestsScreen(
            onHomeSelected: () => context.go(AppRoutes.guestHome),
            onSearchSelected: () => context.go(AppRoutes.search),
            requests: requests,
            onProfileSelected: () {
              context.go(AppRoutes.customerModeProfile);
            },
            onRequestSelected: (request) {
              context.pushNamed(
                AppRouteNames.customerRequestDetail,
                pathParameters: {'requestId': request.id},
                extra: request,
              );
            },
          );
        }

        if (state.extra case final List<CustomerServiceRequest> requests) {
          return buildScreen(requests);
        }
        return Consumer(
          builder: (context, ref, child) {
            if (ref.watch(backendRepositoriesProvider).mode ==
                BackendMode.mock) {
              return buildScreen(
                ref
                    .watch(customerRequestsProvider)
                    .map((item) => item.toCustomerRequest())
                    .toList(),
              );
            }
            return ref
                .watch(persistedCustomerRequestsProvider)
                .when(
                  loading: () => const Scaffold(
                    body: Center(child: CircularProgressIndicator()),
                  ),
                  error: (error, stackTrace) => Scaffold(
                    body: Center(
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Text('No pudimos cargar las solicitudes.'),
                          const SizedBox(height: 12),
                          OutlinedButton(
                            onPressed: () => ref.invalidate(
                              persistedCustomerRequestsProvider,
                            ),
                            child: const Text('Reintentar'),
                          ),
                        ],
                      ),
                    ),
                  ),
                  data: (items) => buildScreen(
                    items.map((item) => item.toCustomerRequest()).toList(),
                  ),
                );
          },
        );
      },
    ),
    GoRoute(
      path: AppRoutes.customerModeProfile,
      builder: (context, state) {
        return ModeProfileScreen(
          mode: AppMode.customer,
          onChangeMode: () {
            ProviderScope.containerOf(
              context,
              listen: false,
            ).read(appModeProvider.notifier).select(AppMode.professional);
            ProviderScope.containerOf(context, listen: false)
                .read(authControllerProvider.notifier)
                .updateActiveMode(AppMode.professional);
            context.go(AppRoutes.professionalHome);
          },
          onSignOut: () => _signOut(context),
          onHomeSelected: () => context.go(AppRoutes.guestHome),
          onSearchSelected: () => context.go(AppRoutes.search),
          onRequestsSelected: () => context.go(AppRoutes.customerRequests),
        );
      },
    ),
    GoRoute(
      path: AppRoutes.customerRequestDetail,
      name: AppRouteNames.customerRequestDetail,
      builder: (context, state) {
        final requestId = state.pathParameters['requestId']!;
        return Consumer(
          builder: (context, ref, child) {
            ServiceRequest? serviceRequest;
            if (ref.watch(backendRepositoriesProvider).mode ==
                BackendMode.mock) {
              serviceRequest = ref.watch(requestDetailProvider(requestId));
            } else {
              final requestState = ref.watch(
                persistedRequestDetailProvider(requestId),
              );
              if (requestState.isLoading) {
                return const Scaffold(
                  body: Center(child: CircularProgressIndicator()),
                );
              }
              if (requestState.hasError) {
                return Scaffold(
                  body: Center(
                    child: TextButton(
                      onPressed: () => ref.invalidate(
                        persistedRequestDetailProvider(requestId),
                      ),
                      child: const Text(
                        'No pudimos cargar la solicitud. Reintentar',
                      ),
                    ),
                  ),
                );
              }
              serviceRequest = requestState.value;
            }
            if (serviceRequest == null) {
              return const Scaffold(
                body: Center(child: Text('No se encontró la solicitud.')),
              );
            }
            final resolvedRequest = serviceRequest;
            final request = resolvedRequest.toCustomerRequest();
            final quotation = ref.watch(quotationProvider(requestId));
            final messages = ref.watch(conversationProvider(requestId));
            return CustomerRequestDetailScreen(
              request: request,
              onBack: () => _popOrGo(context, AppRoutes.customerRequests),
              timelineEvents: ref.watch(timelineProvider(requestId)),
              scheduledDateLabel: _scheduledDateLabel(messages),
              onSubmitRating: (stars, comment) {
                final container = ProviderScope.containerOf(
                  context,
                  listen: false,
                );
                container
                    .read(requestRepositoryProvider)
                    .submitRating(
                      ServiceRating(
                        requestId: requestId,
                        professionalId: resolvedRequest.professional.user.id,
                        stars: stars,
                        comment: comment,
                      ),
                    );
                container
                  ..invalidate(requestDetailProvider(requestId))
                  ..invalidate(customerRequestsProvider)
                  ..invalidate(professionalRequestsProvider)
                  ..invalidate(conversationProvider(requestId))
                  ..invalidate(timelineProvider(requestId))
                  ..invalidate(ratingProvider(requestId))
                  ..invalidate(
                    professionalRatingSummaryProvider(
                      resolvedRequest.professional.user.id,
                    ),
                  )
                  ..invalidate(professionalRequestFlowProvider);
              },
              onViewQuotation: quotation == null
                  ? null
                  : () {
                      context.pushNamed(
                        AppRouteNames.customerQuotation,
                        pathParameters: {'requestId': request.id},
                      );
                    },
              onOpenConversation: () {
                context.pushNamed(
                  AppRouteNames.customerConversation,
                  pathParameters: {'requestId': request.id},
                  extra: request,
                );
              },
            );
          },
        );
      },
    ),
    GoRoute(
      path: AppRoutes.customerQuotation,
      name: AppRouteNames.customerQuotation,
      builder: (context, state) {
        final requestId = state.pathParameters['requestId']!;
        final container = ProviderScope.containerOf(context, listen: false);
        final request = container.read(requestDetailProvider(requestId))!;
        final quotation = container.read(quotationProvider(requestId))!;
        return CustomerQuotationScreen(
          request: request,
          quotation: quotation,
          onAccept: () {
            container
                .read(requestRepositoryProvider)
                .acceptQuotation(requestId);
            container
              ..invalidate(requestDetailProvider(requestId))
              ..invalidate(customerRequestsProvider)
              ..invalidate(professionalRequestsProvider)
              ..invalidate(conversationProvider(requestId))
              ..invalidate(timelineProvider(requestId))
              ..invalidate(professionalRequestFlowProvider);
            context.goNamed(
              AppRouteNames.customerRequestDetail,
              pathParameters: {'requestId': requestId},
            );
          },
          onRequestChanges: () {
            container
                .read(requestRepositoryProvider)
                .sendMessage(
                  ConversationMessage(
                    id: '$requestId-changes-${DateTime.now().microsecondsSinceEpoch}',
                    requestId: requestId,
                    author: MessageAuthor.system,
                    text: 'El cliente solicitó cambios en la cotización.',
                    timeLabel: 'Ahora',
                  ),
                );
            container
              ..invalidate(conversationProvider(requestId))
              ..invalidate(requestDetailProvider(requestId))
              ..invalidate(customerRequestsProvider);
            context.goNamed(
              AppRouteNames.customerConversation,
              pathParameters: {'requestId': requestId},
            );
          },
        );
      },
    ),
    GoRoute(
      path: AppRoutes.customerConversation,
      name: AppRouteNames.customerConversation,
      builder: (context, state) {
        final request = _customerRequestFromState(context, state);
        return Consumer(
          builder: (context, ref, child) {
            final isMock =
                ref.watch(backendRepositoriesProvider).mode == BackendMode.mock;
            final persisted = isMock
                ? null
                : ref.watch(persistedRequestDetailProvider(request.id));
            if (persisted?.isLoading ?? false) {
              return const Scaffold(
                body: Center(child: CircularProgressIndicator()),
              );
            }
            if (persisted?.hasError ?? false) {
              return const Scaffold(
                body: Center(child: Text('No pudimos cargar la conversación.')),
              );
            }
            final serviceRequest = persisted?.value;
            return ConversationScreen(
              requestId: request.id,
              counterpartName: request.professionalName,
              serviceName: request.serviceName,
              requestStatus: request.status,
              perspective: ConversationPerspective.customer,
              initialMessages: isMock
                  ? ref.watch(conversationProvider(request.id))
                  : const [],
              realtime: serviceRequest == null
                  ? null
                  : ConversationRealtimeConfig(
                      repository: ref.watch(conversationsRepositoryProvider),
                      customerId: serviceRequest.customer.id,
                      professionalId: serviceRequest.professional.id,
                      senderId: serviceRequest.customer.id,
                    ),
              onBack: () => _popOrGo(context, AppRoutes.customerRequests),
              onSendMessage: isMock
                  ? (text) => _sendConversationMessage(
                      context,
                      request.id,
                      text,
                      false,
                    )
                  : null,
              onConfirmSchedule: (messageId) {
                final container = ProviderScope.containerOf(
                  context,
                  listen: false,
                );
                container
                    .read(requestRepositoryProvider)
                    .confirmSchedule(request.id, messageId);
                _invalidateScheduleData(container, request.id);
              },
              onRequestScheduleChange: (messageId) {
                final container = ProviderScope.containerOf(
                  context,
                  listen: false,
                );
                container
                    .read(requestRepositoryProvider)
                    .requestScheduleChange(request.id, messageId);
                _invalidateScheduleData(container, request.id);
              },
              onConfirmJob: () {
                final container = ProviderScope.containerOf(
                  context,
                  listen: false,
                );
                container
                    .read(requestRepositoryProvider)
                    .confirmJob(request.id);
                _invalidateScheduleData(container, request.id);
              },
              onReportProblem: () {
                final container = ProviderScope.containerOf(
                  context,
                  listen: false,
                );
                container
                    .read(requestRepositoryProvider)
                    .reportCompletedWorkProblem(request.id);
                _invalidateScheduleData(container, request.id);
              },
            );
          },
        );
      },
    ),
  ],
);
