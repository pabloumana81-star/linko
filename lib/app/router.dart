import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:linko/features/auth/presentation/user_type_screen.dart';
import 'package:linko/features/auth/presentation/welcome_screen.dart';
import 'package:linko/features/auth/presentation/auth_controller.dart';
import 'package:linko/app/app_mode.dart';
import 'package:linko/app/app_mode_provider.dart';
import 'package:linko/features/home/presentation/confirm_request_screen.dart';
import 'package:linko/features/home/presentation/conversation_screen.dart';
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
import 'package:linko/features/home/presentation/professional_profile_route.dart';
import 'package:linko/features/home/presentation/professional_request_detail_screen.dart';
import 'package:linko/features/home/presentation/professional_requests_screen.dart';
import 'package:linko/features/home/presentation/providers/professional_requests_provider.dart';
import 'package:linko/features/home/presentation/providers/professional_discovery_provider.dart';
import 'package:linko/features/home/presentation/professionals_results_screen.dart';
import 'package:linko/features/home/presentation/quotation_form_screen.dart';
import 'package:linko/features/home/presentation/quotation_review_screen.dart';
import 'package:linko/features/home/presentation/quotation_success_screen.dart';
import 'package:linko/features/home/presentation/request_service_screen.dart';
import 'package:linko/features/home/presentation/request_success_screen.dart';
import 'package:linko/features/home/presentation/widgets/labeled_loading_indicator.dart';
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
import 'package:linko/features/requests/domain/models/quotation.dart';
import 'package:linko/core/backend/backend_providers.dart';
import 'package:linko/core/diagnostics/diagnostics_service.dart';
import 'package:linko/core/backend/backend_config.dart';
import 'package:linko/features/requests/presentation/providers/request_workflow_controller.dart';
import 'package:uuid/uuid.dart';

abstract final class AppRoutes {
  static const splash = '/';
  static const welcome = '/welcome';
  static const userType = '/user-type';
  static const guestHome = '/guest-home';
  static const search = '/search';
  static const category = '/category/:categoryName';
  static const createRequest = '/create-request';
  static const professionalHome = '/professional-home';
  static const professionalProfile = '/professional/:professionalId';
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

Widget _incomingRequestRoute(
  GoRouterState state,
  Widget Function(IncomingServiceRequest request) builder,
) {
  final requestId = state.pathParameters['requestId']!;
  final extra = state.extra;
  return Consumer(
    builder: (context, ref, child) {
      if (extra is IncomingServiceRequest) return builder(extra);
      final isMock =
          ref.watch(backendRepositoriesProvider).mode == BackendMode.mock;
      if (isMock) {
        final request = ref.watch(requestDetailProvider(requestId));
        return request == null
            ? const _MissingRequestScreen()
            : builder(request.toIncomingRequest());
      }
      return ref
          .watch(persistedRequestDetailProvider(requestId))
          .when(
            loading: () => const Scaffold(
              body: Center(child: CircularProgressIndicator()),
            ),
            error: (_, _) => Scaffold(
              body: Center(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Text('No pudimos cargar la solicitud.'),
                    const SizedBox(height: 12),
                    OutlinedButton(
                      onPressed: () => ref.invalidate(
                        persistedRequestDetailProvider(requestId),
                      ),
                      child: const Text('Reintentar'),
                    ),
                  ],
                ),
              ),
            ),
            data: (request) => request == null
                ? const _MissingRequestScreen()
                : builder(request.toIncomingRequest()),
          );
    },
  );
}

class _DevelopmentRouteObserver extends NavigatorObserver {
  void _log(String action, Route<dynamic>? route) {
    if (!kDebugMode) return;
    final name = route?.settings.name ?? 'unnamed';
    debugPrint('linko_navigation action=$action route=$name');
  }

  @override
  void didPush(Route<dynamic> route, Route<dynamic>? previousRoute) {
    _log('push', route);
    super.didPush(route, previousRoute);
  }

  @override
  void didPop(Route<dynamic> route, Route<dynamic>? previousRoute) {
    _log('pop', route);
    super.didPop(route, previousRoute);
  }

  @override
  void didReplace({Route<dynamic>? newRoute, Route<dynamic>? oldRoute}) {
    _log('replace', newRoute);
    super.didReplace(newRoute: newRoute, oldRoute: oldRoute);
  }
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

Widget _customerRequestRoute(
  GoRouterState state,
  Widget Function(CustomerServiceRequest request) builder,
) {
  final extra = state.extra;
  final requestId = state.pathParameters['requestId']!;
  return Consumer(
    builder: (context, ref, child) {
      if (extra is CustomerServiceRequest) return builder(extra);
      final isMock =
          ref.watch(backendRepositoriesProvider).mode == BackendMode.mock;
      if (isMock) {
        final request = ref.watch(requestDetailProvider(requestId));
        return request == null
            ? const _MissingRequestScreen()
            : builder(request.toCustomerRequest());
      }
      return ref
          .watch(persistedRequestDetailProvider(requestId))
          .when(
            loading: () => const Scaffold(
              body: Center(child: CircularProgressIndicator()),
            ),
            error: (_, _) => const Scaffold(
              body: Center(child: Text('No pudimos cargar la solicitud.')),
            ),
            data: (request) => request == null
                ? const _MissingRequestScreen()
                : builder(request.toCustomerRequest()),
          );
    },
  );
}

class _MissingRequestScreen extends StatelessWidget {
  const _MissingRequestScreen();

  @override
  Widget build(BuildContext context) =>
      const Scaffold(body: Center(child: Text('No se encontró la solicitud.')));
}

class _HiringRouteState extends StatelessWidget {
  const _HiringRouteState({
    required this.title,
    this.message,
    this.onRetry,
    this.loading = false,
  });

  final String title;
  final String? message;
  final VoidCallback? onRetry;
  final bool loading;

  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(title: Text(title)),
    body: Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (loading) ...[
              const CircularProgressIndicator(),
              const SizedBox(height: 12),
              const Text('Cargando…'),
            ] else if (message != null)
              Text(message!, textAlign: TextAlign.center),
            if (onRetry != null) ...[
              const SizedBox(height: 12),
              OutlinedButton(
                onPressed: onRetry,
                child: const Text('Reintentar'),
              ),
            ],
          ],
        ),
      ),
    ),
  );
}

enum _CustomerRequestDetailBranch { loading, content, notFound, error }

class _CustomerRequestDetailRoute extends ConsumerStatefulWidget {
  const _CustomerRequestDetailRoute({
    required this.requestId,
    this.initialRequest,
  });

  final String requestId;
  final CustomerServiceRequest? initialRequest;

  @override
  ConsumerState<_CustomerRequestDetailRoute> createState() =>
      _CustomerRequestDetailRouteState();
}

class _CustomerRequestDetailRouteState
    extends ConsumerState<_CustomerRequestDetailRoute>
    with WidgetsBindingObserver {
  CustomerServiceRequest? _retainedRequest;
  ServiceRequest? _retainedServiceRequest;
  List<ConversationMessage> _retainedMessages = const [];

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _retainedRequest = widget.initialRequest;
    _debugLog('route_entered', providerState: 'not_read');
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      _debugLog('lifecycle_resume', providerState: 'unchanged');
    }
  }

  @override
  void dispose() {
    _debugLog('navigation_exit', providerState: 'disposed');
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  String _stateName(AsyncValue<Object?> state) {
    if (state.hasError) return 'error';
    if (state.isLoading) return 'loading';
    return 'data';
  }

  void _debugLog(
    String event, {
    required String providerState,
    _CustomerRequestDetailBranch? branch,
  }) {
    if (!kDebugMode) return;
    debugPrint(
      'linko_customer_request_detail event=$event '
      'route=${AppRouteNames.customerRequestDetail} '
      'request_id=${widget.requestId} '
      'snapshot=${widget.initialRequest != null} '
      'provider=$providerState '
      'retained=${_retainedRequest != null} '
      'branch=${branch?.name ?? 'none'}',
    );
  }

  Widget _renderBranch(
    _CustomerRequestDetailBranch branch,
    Widget child, {
    required String providerState,
  }) {
    _debugLog('render', providerState: providerState, branch: branch);
    return child;
  }

  Widget _failFastGuard(String providerState) {
    if (kDebugMode) {
      return Scaffold(
        appBar: AppBar(title: const Text('Diagnóstico de solicitud')),
        body: Padding(
          padding: const EdgeInsets.all(24),
          child: Text(
            'Ruta: ${AppRouteNames.customerRequestDetail}\n'
            'ID presente: ${widget.requestId.isNotEmpty ? 'sí' : 'no'}\n'
            'Proveedor: $providerState',
          ),
        ),
      );
    }
    return const Scaffold(
      body: Center(child: Text('No pudimos mostrar la solicitud.')),
    );
  }

  Widget _guardDestination(Widget? destination, String providerState) =>
      destination ?? _failFastGuard(providerState);

  @override
  Widget build(BuildContext context) {
    final isMock =
        ref.watch(backendRepositoriesProvider).mode == BackendMode.mock;
    AsyncValue<ServiceRequest?>? persistedState;
    ServiceRequest? serviceRequest;

    if (isMock) {
      serviceRequest = ref.watch(requestDetailProvider(widget.requestId));
    } else {
      final state = ref.watch(persistedRequestDetailProvider(widget.requestId));
      persistedState = state;
      if (!state.hasError) {
        final freshRequest = state.value;
        if (freshRequest != null) {
          _retainedServiceRequest = freshRequest;
          _retainedRequest = freshRequest.toCustomerRequest();
        }
        serviceRequest = freshRequest ?? _retainedServiceRequest;
      }
    }

    final providerState = persistedState == null
        ? 'mock_data'
        : _stateName(persistedState);
    _debugLog('provider_state', providerState: providerState);

    if (persistedState?.hasError ?? false) {
      return _renderBranch(
        _CustomerRequestDetailBranch.error,
        Scaffold(
          appBar: AppBar(
            leading: BackButton(
              onPressed: () => _popOrGo(context, AppRoutes.customerRequests),
            ),
            title: const Text('Detalle de solicitud'),
          ),
          body: Center(
            child: Padding(
              padding: const EdgeInsets.all(24),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Text(
                    'No pudimos cargar la solicitud.',
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 12),
                  OutlinedButton(
                    onPressed: () => ref.invalidate(
                      persistedRequestDetailProvider(widget.requestId),
                    ),
                    child: const Text('Reintentar'),
                  ),
                  TextButton(
                    onPressed: () =>
                        _popOrGo(context, AppRoutes.customerRequests),
                    child: const Text('Volver'),
                  ),
                ],
              ),
            ),
          ),
        ),
        providerState: providerState,
      );
    }

    final request = serviceRequest?.toCustomerRequest() ?? _retainedRequest;
    if (request == null && (persistedState?.isLoading ?? false)) {
      return _renderBranch(
        _CustomerRequestDetailBranch.loading,
        Scaffold(
          appBar: AppBar(
            leading: BackButton(
              onPressed: () => _popOrGo(context, AppRoutes.customerRequests),
            ),
            title: const Text('Detalle de solicitud'),
          ),
          body: const LabeledLoadingIndicator(label: 'Cargando solicitud…'),
        ),
        providerState: providerState,
      );
    }
    if (request == null) {
      return _renderBranch(
        _CustomerRequestDetailBranch.notFound,
        Scaffold(
          appBar: AppBar(
            leading: BackButton(
              onPressed: () => _popOrGo(context, AppRoutes.customerRequests),
            ),
            title: const Text('Detalle de solicitud'),
          ),
          body: const Center(child: Text('No se encontró la solicitud.')),
        ),
        providerState: providerState,
      );
    }

    final realtimeStatusState = serviceRequest == null || isMock
        ? null
        : ref.watch(realtimeRequestStatusProvider(widget.requestId));
    final realtimeQuotationState = serviceRequest == null || isMock
        ? null
        : ref.watch(realtimeQuotationProvider(widget.requestId));
    final realtimeTimelineState = serviceRequest == null || isMock
        ? null
        : ref.watch(realtimeTimelineProvider(widget.requestId));
    final messagesState = ref.watch(
      requestConversationMessagesProvider(widget.requestId),
    );
    if ((realtimeStatusState?.hasError ?? false) ||
        (realtimeQuotationState?.hasError ?? false) ||
        (realtimeTimelineState?.hasError ?? false) ||
        messagesState.hasError) {
      return _renderBranch(
        _CustomerRequestDetailBranch.error,
        Scaffold(
          appBar: AppBar(
            leading: BackButton(
              onPressed: () => _popOrGo(context, AppRoutes.customerRequests),
            ),
            title: const Text('Detalle de solicitud'),
          ),
          body: Center(
            child: Padding(
              padding: const EdgeInsets.all(24),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Text(
                    'Perdimos la sincronización de la solicitud.',
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 12),
                  OutlinedButton(
                    onPressed: () {
                      ref
                        ..invalidate(
                          realtimeRequestStatusProvider(widget.requestId),
                        )
                        ..invalidate(
                          realtimeQuotationProvider(widget.requestId),
                        )
                        ..invalidate(realtimeTimelineProvider(widget.requestId))
                        ..invalidate(
                          requestConversationMessagesProvider(widget.requestId),
                        );
                    },
                    child: const Text('Reconectar'),
                  ),
                ],
              ),
            ),
          ),
        ),
        providerState: providerState,
      );
    }

    var resolvedRequest = serviceRequest;
    final realtimeStatus = realtimeStatusState?.value;
    if (resolvedRequest != null && realtimeStatus != null) {
      resolvedRequest = resolvedRequest.copyWith(state: realtimeStatus);
      _retainedServiceRequest = resolvedRequest;
      _retainedRequest = resolvedRequest.toCustomerRequest();
    }
    final visibleRequest = resolvedRequest?.toCustomerRequest() ?? request;
    final professionalId = resolvedRequest?.professional.user.id;
    final quotation = isMock
        ? ref.watch(quotationProvider(widget.requestId))
        : realtimeQuotationState?.value;
    final freshMessages = messagesState.value;
    if (freshMessages != null) _retainedMessages = freshMessages;
    final messages = freshMessages ?? _retainedMessages;
    Widget? destination = CustomerRequestDetailScreen(
      request: visibleRequest,
      onBack: () => _popOrGo(context, AppRoutes.customerRequests),
      timelineEvents: isMock
          ? ref.watch(timelineProvider(widget.requestId))
          : realtimeTimelineState?.value ?? const [],
      scheduledDateLabel: _scheduledDateLabel(messages),
      onSubmitRating: professionalId == null
          ? null
          : (stars, comment) async {
              final rating = ServiceRating(
                requestId: widget.requestId,
                professionalId: professionalId,
                stars: stars,
                comment: comment,
              );
              try {
                await ref
                    .read(requestWorkflowControllerProvider)
                    .submitRating(rating);
                ref
                  ..invalidate(requestDetailProvider(widget.requestId))
                  ..invalidate(customerRequestsProvider)
                  ..invalidate(professionalRequestsProvider)
                  ..invalidate(
                    requestConversationMessagesProvider(widget.requestId),
                  )
                  ..invalidate(timelineProvider(widget.requestId))
                  ..invalidate(ratingProvider(widget.requestId))
                  ..invalidate(
                    professionalRatingSummaryProvider(professionalId),
                  )
                  ..invalidate(professionalRequestFlowProvider);
              } catch (_) {
                if (context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('No pudimos enviar la calificación.'),
                    ),
                  );
                }
              }
            },
      onViewQuotation: quotation == null
          ? null
          : () => context.pushNamed(
              AppRouteNames.customerQuotation,
              pathParameters: {'requestId': visibleRequest.id},
            ),
      onOpenConversation: () => context.pushNamed(
        AppRouteNames.customerConversation,
        pathParameters: {'requestId': visibleRequest.id},
        extra: visibleRequest,
      ),
    );
    destination = _renderBranch(
      _CustomerRequestDetailBranch.content,
      destination,
      providerState: providerState,
    );
    return _guardDestination(destination, providerState);
  }
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

Future<void> _runWorkflowAction(
  BuildContext context,
  Future<void> operation,
  VoidCallback onSuccess,
) async {
  final diagnostics = ProviderScope.containerOf(
    context,
    listen: false,
  ).read(diagnosticsServiceProvider);
  try {
    await operation;
    onSuccess();
  } catch (error, stackTrace) {
    diagnostics.unexpectedError(error, stackTrace, context: 'workflow_action');
    if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('No pudimos completar la acción. Intenta nuevamente.'),
        ),
      );
    }
  }
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
  if (auth.user?.onboardingCompleted == false) {
    context.go(AppRoutes.userType);
    return;
  }
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
  observers: [_DevelopmentRouteObserver()],
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
          onCustomerSelected: () async {
            final container = ProviderScope.containerOf(context, listen: false);
            if (container.read(authControllerProvider).user == null) {
              container.read(appModeProvider.notifier).select(AppMode.customer);
              context.go(AppRoutes.guestHome);
              return;
            }
            await container
                .read(authControllerProvider.notifier)
                .updateActiveMode(AppMode.customer);
            if (!context.mounted) return;
            final auth = container.read(authControllerProvider);
            if (auth.status == AuthStatus.authenticated &&
                auth.user?.activeMode == AppMode.customer &&
                auth.user?.onboardingCompleted == true) {
              container.read(appModeProvider.notifier).select(AppMode.customer);
              context.go(AppRoutes.guestHome);
            }
          },
          onProfessionalSelected: () async {
            final container = ProviderScope.containerOf(context, listen: false);
            if (container.read(authControllerProvider).user == null) {
              container
                  .read(appModeProvider.notifier)
                  .select(AppMode.professional);
              context.go(AppRoutes.professionalHome);
              return;
            }
            await container
                .read(authControllerProvider.notifier)
                .updateActiveMode(AppMode.professional);
            if (!context.mounted) return;
            final auth = container.read(authControllerProvider);
            if (auth.status == AuthStatus.authenticated &&
                auth.user?.activeMode == AppMode.professional &&
                auth.user?.onboardingCompleted == true) {
              container
                  .read(appModeProvider.notifier)
                  .select(AppMode.professional);
              context.go(AppRoutes.professionalHome);
            }
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
              pathParameters: {'professionalId': professional.id},
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
              pathParameters: {'professionalId': professional.id},
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
              pathParameters: {'professionalId': professional.id},
              extra: professional,
            );
          },
        );
      },
    ),
    GoRoute(
      path: AppRoutes.category,
      name: AppRouteNames.category,
      redirect: (context, state) => Uri(
        path: '/results/${state.pathParameters['categoryName']!}',
      ).toString(),
    ),
    GoRoute(
      path: AppRoutes.createRequest,
      redirect: (context, state) => AppRoutes.search,
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
        return _incomingRequestRoute(
          state,
          (request) => ProfessionalRequestDetailScreen(
            request: request,
            onBack: () => _popOrGo(context, AppRoutes.professionalRequests),
            onStartJob: (selectedRequest) {
              final container = ProviderScope.containerOf(
                context,
                listen: false,
              );
              unawaited(
                _runWorkflowAction(
                  context,
                  container
                      .read(requestWorkflowControllerProvider)
                      .startWork(selectedRequest.id),
                  () => _invalidateScheduleData(container, selectedRequest.id),
                ),
              );
            },
            onMarkJobCompleted: (selectedRequest) {
              final container = ProviderScope.containerOf(
                context,
                listen: false,
              );
              unawaited(
                _runWorkflowAction(
                  context,
                  container
                      .read(requestWorkflowControllerProvider)
                      .completeWork(selectedRequest.id),
                  () => _invalidateScheduleData(container, selectedRequest.id),
                ),
              );
            },
            onOpenConversation: (selectedRequest) {
              context.pushNamed(
                AppRouteNames.professionalConversation,
                pathParameters: {'requestId': selectedRequest.id},
                extra: selectedRequest,
              );
            },
            onSendQuotation: (selectedRequest) {
              final quotation =
                  ProviderScope.containerOf(context, listen: false)
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
          ),
        );
      },
    ),
    GoRoute(
      path: AppRoutes.professionalConversation,
      name: AppRouteNames.professionalConversation,
      builder: (context, state) {
        return _incomingRequestRoute(
          state,
          (request) => Consumer(
            builder: (context, ref, child) {
              final isMock =
                  ref.watch(backendRepositoriesProvider).mode ==
                  BackendMode.mock;
              final persisted = isMock
                  ? null
                  : ref.watch(persistedRequestDetailProvider(request.id));
              if (persisted?.isLoading ?? false) {
                return const Scaffold(
                  body: LabeledLoadingIndicator(label: 'Cargando solicitud…'),
                );
              }
              if (persisted?.hasError ?? false) {
                return const Scaffold(
                  body: Center(
                    child: Text('No pudimos cargar la conversación.'),
                  ),
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
                diagnostics: ref.watch(diagnosticsServiceProvider),
                onBack: () => _popOrGo(context, AppRoutes.professionalRequests),
                onSendMessage: isMock
                    ? (text) => _sendConversationMessage(
                        context,
                        request.id,
                        text,
                        true,
                      )
                    : null,
                onProposeSchedule: (scheduleLabel) {
                  final container = ProviderScope.containerOf(
                    context,
                    listen: false,
                  );
                  unawaited(
                    _runWorkflowAction(
                      context,
                      container
                          .read(requestWorkflowControllerProvider)
                          .proposeSchedule(request.id, scheduleLabel),
                      () => _invalidateScheduleData(container, request.id),
                    ),
                  );
                },
              );
            },
          ),
        );
      },
    ),
    GoRoute(
      path: AppRoutes.professionalQuotation,
      name: AppRouteNames.professionalQuotation,
      builder: (context, state) {
        return _incomingRequestRoute(
          state,
          (request) => QuotationFormScreen(
            request: request,
            onReview: (draft) {
              context.pushNamed(
                AppRouteNames.professionalQuotationReview,
                pathParameters: {'requestId': request.id},
                extra: draft,
              );
            },
          ),
        );
      },
    ),
    GoRoute(
      path: AppRoutes.professionalQuotationReview,
      name: AppRouteNames.professionalQuotationReview,
      builder: (context, state) {
        return _incomingRequestRoute(state, (request) {
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
            onSend: () async {
              final container = ProviderScope.containerOf(
                context,
                listen: false,
              );
              if (container.read(backendRepositoriesProvider).mode ==
                  BackendMode.mock) {
                final previousState = request.status;
                final sent = container
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
                container
                    .read(requestWorkflowControllerProvider)
                    .recordQuotationSent(request.id, previousState);
              } else {
                try {
                  await container
                      .read(requestWorkflowControllerProvider)
                      .createQuotation(
                        Quotation(
                          requestId: request.id,
                          laborAmount: draft.laborAmount,
                          materialsAmount: draft.materialsAmount,
                          workDescription: draft.workDescription,
                          estimatedDuration: draft.estimatedDuration.label,
                          startTiming: draft.startTiming.label,
                          validityDays: draft.validityDays,
                        ),
                      );
                } catch (_) {
                  if (!context.mounted) return;
                  final messenger = ScaffoldMessenger.of(context);
                  messenger.removeCurrentSnackBar();
                  messenger.showSnackBar(
                    const SnackBar(
                      content: Text('No pudimos enviar la cotización.'),
                    ),
                  );
                  return;
                }
              }
              if (!context.mounted) return;
              context.goNamed(
                AppRouteNames.professionalQuotationSuccess,
                pathParameters: {'requestId': request.id},
                extra: request.customerName,
              );
            },
          );
        });
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
        final extra = state.extra;
        return ProfessionalProfileRoute(
          professionalId: state.pathParameters['professionalId']!,
          initialProfessional: extra is ProfessionalProfileData ? extra : null,
          onRequestService: (professional) {
            context.pushNamed(
              AppRouteNames.requestService,
              pathParameters: {'professionalName': professional.id},
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
        final professionalId = state.pathParameters['professionalName']!;
        final extra = state.extra;
        return Consumer(
          builder: (context, ref, child) {
            final selected =
                extra is ProfessionalProfileData && extra.id == professionalId
                ? extra
                : null;
            final lookup = selected == null
                ? ref.watch(professionalProfileByIdProvider(professionalId))
                : AsyncData<ProfessionalProfileData?>(selected);
            if (lookup.hasError) {
              return _HiringRouteState(
                title: 'Solicitar servicio',
                message: 'No pudimos cargar el profesional seleccionado.',
                onRetry: () => ref.invalidate(
                  professionalProfileByIdProvider(professionalId),
                ),
              );
            }
            final professional = lookup.value;
            if (professional == null && lookup.isLoading) {
              return const _HiringRouteState(
                title: 'Solicitar servicio',
                loading: true,
              );
            }
            if (professional == null) {
              return const _HiringRouteState(
                title: 'Solicitar servicio',
                message: 'No se encontró el profesional seleccionado.',
              );
            }
            return RequestServiceScreen(
              professional: professional,
              onContinue: (draft) {
                context.push(AppRoutes.confirmRequest, extra: draft);
              },
            );
          },
        );
      },
    ),
    GoRoute(
      path: AppRoutes.confirmRequest,
      builder: (context, state) {
        final extra = state.extra;
        final draft = extra is RequestDraft ? extra : null;
        if (draft == null) {
          return const _HiringRouteState(
            title: 'Confirmar solicitud',
            message: 'No se encontraron los datos de la solicitud.',
          );
        }
        return ConfirmRequestScreen(
          draft: draft,
          onSubmit: () async {
            final container = ProviderScope.containerOf(context, listen: false);
            final isMock =
                container.read(backendRepositoriesProvider).mode ==
                BackendMode.mock;
            final authenticatedUser = container
                .read(authControllerProvider)
                .user;
            if (!isMock && authenticatedUser == null) {
              throw StateError(
                'Debes iniciar sesión para crear una solicitud.',
              );
            }
            final persistedProfessional = isMock
                ? null
                : await container
                      .read(professionalsRepositoryProvider)
                      .getProfessionalById(draft.professional.id);
            if (!isMock && persistedProfessional == null) {
              throw StateError('No se encontró el profesional seleccionado.');
            }
            final now = DateTime.now();
            final request = ServiceRequest(
              id: isMock
                  ? 'request-${now.microsecondsSinceEpoch}'
                  : const Uuid().v4(),
              customer: AppUser(
                id: isMock ? currentCustomerId : authenticatedUser!.id,
                name: 'Cliente LinkO',
              ),
              professional:
                  persistedProfessional ??
                  ProfessionalProfile(
                    id: draft.professional.id,
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
                .read(requestWorkflowControllerProvider)
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
        final extra = state.extra;
        final professionalName = extra is String ? extra : null;
        if (professionalName == null) {
          return const _MissingRequestScreen();
        }
        return RequestSuccessScreen(
          professionalName: professionalName,
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
                    items.map((item) {
                      final status = ref
                          .watch(realtimeRequestStatusProvider(item.id))
                          .value;
                      return item.copyWith(state: status).toCustomerRequest();
                    }).toList(),
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
        final extra = state.extra;
        return _CustomerRequestDetailRoute(
          requestId: requestId,
          initialRequest: extra is CustomerServiceRequest ? extra : null,
        );
      },
    ),
    GoRoute(
      path: AppRoutes.customerQuotation,
      name: AppRouteNames.customerQuotation,
      builder: (context, state) {
        final requestId = state.pathParameters['requestId']!;
        return Consumer(
          builder: (context, ref, child) {
            final isMock =
                ref.watch(backendRepositoriesProvider).mode == BackendMode.mock;
            ServiceRequest? request;
            Quotation? quotation;
            if (isMock) {
              request = ref.watch(requestDetailProvider(requestId));
              quotation = ref.watch(quotationProvider(requestId));
            } else {
              final requestState = ref.watch(
                persistedRequestDetailProvider(requestId),
              );
              final quotationState = ref.watch(
                realtimeQuotationProvider(requestId),
              );
              if ((requestState.isLoading && requestState.value == null) ||
                  (quotationState.isLoading && quotationState.value == null)) {
                return const Scaffold(
                  body: Center(child: CircularProgressIndicator()),
                );
              }
              if (requestState.hasError || quotationState.hasError) {
                return Scaffold(
                  body: Center(
                    child: Padding(
                      padding: const EdgeInsets.all(24),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Text(
                            'No pudimos cargar la cotización.',
                            textAlign: TextAlign.center,
                          ),
                          const SizedBox(height: 12),
                          OutlinedButton(
                            onPressed: () {
                              ref
                                ..invalidate(
                                  persistedRequestDetailProvider(requestId),
                                )
                                ..invalidate(
                                  realtimeQuotationProvider(requestId),
                                );
                            },
                            child: const Text('Reintentar'),
                          ),
                        ],
                      ),
                    ),
                  ),
                );
              }
              request = requestState.value;
              quotation = quotationState.value;
            }
            if (request == null || quotation == null) {
              return Scaffold(
                appBar: AppBar(),
                body: const Center(
                  child: Padding(
                    padding: EdgeInsets.all(24),
                    child: Text(
                      'No se encontró una cotización disponible.',
                      textAlign: TextAlign.center,
                    ),
                  ),
                ),
              );
            }
            return CustomerQuotationScreen(
              request: request,
              quotation: quotation,
              onAccept: () async {
                try {
                  await ref
                      .read(requestWorkflowControllerProvider)
                      .acceptQuotation(requestId);
                } catch (_) {
                  if (context.mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('No pudimos aceptar la cotización.'),
                      ),
                    );
                  }
                  return;
                }
                if (!context.mounted) return;
                ref
                  ..invalidate(requestDetailProvider(requestId))
                  ..invalidate(customerRequestsProvider)
                  ..invalidate(professionalRequestsProvider)
                  ..invalidate(requestConversationMessagesProvider(requestId))
                  ..invalidate(timelineProvider(requestId))
                  ..invalidate(professionalRequestFlowProvider);
                context.goNamed(
                  AppRouteNames.customerRequestDetail,
                  pathParameters: {'requestId': requestId},
                );
              },
              onRequestChanges: () async {
                if (!isMock) {
                  await ref
                      .read(requestWorkflowControllerProvider)
                      .rejectQuotation(requestId);
                  if (context.mounted) {
                    context.goNamed(
                      AppRouteNames.customerRequestDetail,
                      pathParameters: {'requestId': requestId},
                    );
                  }
                  return;
                }
                ref
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
                ref
                  ..invalidate(conversationProvider(requestId))
                  ..invalidate(requestDetailProvider(requestId))
                  ..invalidate(customerRequestsProvider);
                if (context.mounted) {
                  context.goNamed(
                    AppRouteNames.customerConversation,
                    pathParameters: {'requestId': requestId},
                  );
                }
              },
            );
          },
        );
      },
    ),
    GoRoute(
      path: AppRoutes.customerConversation,
      name: AppRouteNames.customerConversation,
      builder: (context, state) {
        return _customerRequestRoute(
          state,
          (request) => Consumer(
            builder: (context, ref, child) {
              final isMock =
                  ref.watch(backendRepositoriesProvider).mode ==
                  BackendMode.mock;
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
                  body: Center(
                    child: Text('No pudimos cargar la conversación.'),
                  ),
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
                diagnostics: ref.watch(diagnosticsServiceProvider),
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
                  unawaited(
                    _runWorkflowAction(
                      context,
                      container
                          .read(requestWorkflowControllerProvider)
                          .acceptSchedule(request.id, messageId),
                      () => _invalidateScheduleData(container, request.id),
                    ),
                  );
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
                  unawaited(
                    _runWorkflowAction(
                      context,
                      container
                          .read(requestWorkflowControllerProvider)
                          .requestRating(request.id),
                      () => _invalidateScheduleData(container, request.id),
                    ),
                  );
                },
                onReportProblem: () {
                  final container = ProviderScope.containerOf(
                    context,
                    listen: false,
                  );
                  final user = container.read(authControllerProvider).user;
                  if (!isMock && user == null) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text(
                          'Debes iniciar sesión para reportar un problema.',
                        ),
                      ),
                    );
                    return;
                  }
                  unawaited(
                    container
                        .read(reportsRepositoryProvider)
                        .createReport(
                          reporterId: user?.id ?? currentCustomerId,
                          requestId: request.id,
                          reason: 'Problema con el trabajo completado',
                        )
                        .then(
                          (_) => _invalidateScheduleData(container, request.id),
                        )
                        .catchError((Object error, StackTrace stackTrace) {
                          container
                              .read(diagnosticsServiceProvider)
                              .unexpectedError(
                                error,
                                stackTrace,
                                context: 'customer_create_report',
                              );
                        }),
                  );
                },
              );
            },
          ),
        );
      },
    ),
  ],
);
