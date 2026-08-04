import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:linko/features/home/presentation/models/incoming_service_request.dart';
import 'package:linko/features/requests/domain/models/request_state.dart';
import 'package:linko/features/home/presentation/widgets/empty_requests_state.dart';
import 'package:linko/features/home/presentation/widgets/filter_chip_widget.dart';
import 'package:linko/features/home/presentation/widgets/incoming_request_card.dart';
import 'package:linko/features/home/presentation/widgets/professional_bottom_navigation_widget.dart';
import 'package:linko/features/requests/presentation/adapters/request_view_adapters.dart';
import 'package:linko/features/requests/presentation/providers/request_providers.dart';
import 'package:linko/core/backend/backend_config.dart';
import 'package:linko/core/backend/backend_providers.dart';
import 'package:linko/features/home/presentation/providers/professional_requests_provider.dart';

class ProfessionalRequestsScreen extends ConsumerStatefulWidget {
  const ProfessionalRequestsScreen({
    required this.onHomeSelected,
    required this.onRequestSelected,
    this.showQuotedInitially = false,
    this.showSentConfirmation = false,
    required this.onProfileSelected,
    super.key,
  });

  final VoidCallback onHomeSelected;
  final ValueChanged<IncomingServiceRequest> onRequestSelected;
  final bool showQuotedInitially;
  final bool showSentConfirmation;
  final VoidCallback onProfileSelected;

  @override
  ConsumerState<ProfessionalRequestsScreen> createState() =>
      _ProfessionalRequestsScreenState();
}

class _ProfessionalRequestsScreenState
    extends ConsumerState<ProfessionalRequestsScreen> {
  late _ProfessionalRequestsFilter _selectedFilter;

  @override
  void initState() {
    super.initState();
    _selectedFilter = widget.showQuotedInitially
        ? _ProfessionalRequestsFilter.quoted
        : _ProfessionalRequestsFilter.newRequests;
    if (widget.showSentConfirmation) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!mounted) {
          return;
        }
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Cotización enviada correctamente.')),
        );
      });
    }
  }

  List<IncomingServiceRequest> _visibleRequests(
    List<IncomingServiceRequest> requests,
  ) {
    final status = _selectedFilter.status;
    if (status == null) return requests;

    return requests.where((request) => request.status == status).toList();
  }

  @override
  Widget build(BuildContext context) {
    if (ref.watch(backendRepositoriesProvider).mode == BackendMode.mock) {
      final requests = ref.watch(professionalRequestFlowProvider).requests;
      return _buildScaffold(_requestList(_visibleRequests(requests)));
    }
    final persistedRequests = ref.watch(persistedProfessionalRequestsProvider);
    return persistedRequests.when(
      loading: () =>
          _buildScaffold(const Center(child: CircularProgressIndicator())),
      error: (error, stackTrace) => _buildScaffold(
        _LoadError(
          onRetry: () => ref.invalidate(persistedProfessionalRequestsProvider),
        ),
      ),
      data: (requests) {
        final visibleRequests = _visibleRequests(
          requests.map((request) {
            final status = ref
                .watch(realtimeRequestStatusProvider(request.id))
                .value;
            return request.copyWith(state: status).toIncomingRequest();
          }).toList(),
        );
        return _buildScaffold(_requestList(visibleRequests));
      },
    );
  }

  Widget _requestList(List<IncomingServiceRequest> visibleRequests) {
    return Center(
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 900),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.fromLTRB(20, 16, 20, 12),
              child: Row(
                children: [
                  for (
                    var index = 0;
                    index < _ProfessionalRequestsFilter.values.length;
                    index++
                  ) ...[
                    FilterChipWidget(
                      label: _ProfessionalRequestsFilter.values[index].label,
                      selected:
                          _selectedFilter ==
                          _ProfessionalRequestsFilter.values[index],
                      onPressed: () {
                        setState(() {
                          _selectedFilter =
                              _ProfessionalRequestsFilter.values[index];
                        });
                      },
                    ),
                    if (index != _ProfessionalRequestsFilter.values.length - 1)
                      const SizedBox(width: 8),
                  ],
                ],
              ),
            ),
            Expanded(
              child: visibleRequests.isEmpty
                  ? const EmptyRequestsState()
                  : ListView.separated(
                      padding: const EdgeInsets.fromLTRB(20, 8, 20, 32),
                      itemCount: visibleRequests.length,
                      separatorBuilder: (context, index) =>
                          const SizedBox(height: 12),
                      itemBuilder: (context, index) {
                        final request = visibleRequests[index];
                        return IncomingRequestCard(
                          request: request,
                          onViewRequest: () {
                            widget.onRequestSelected(request);
                          },
                        );
                      },
                    ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildScaffold(Widget body) {
    return Scaffold(
      appBar: AppBar(
        automaticallyImplyLeading: false,
        title: const Text('Solicitudes'),
      ),
      body: body,
      bottomNavigationBar: ProfessionalBottomNavigationWidget(
        selectedIndex: 1,
        onDestinationSelected: (index) {
          if (index == 0) {
            widget.onHomeSelected();
          } else if (index == 3) {
            widget.onProfileSelected();
          }
        },
      ),
    );
  }
}

class _LoadError extends StatelessWidget {
  const _LoadError({required this.onRetry});

  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) => Center(
    child: Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        const Text('No pudimos cargar las solicitudes.'),
        const SizedBox(height: 12),
        OutlinedButton(onPressed: onRetry, child: const Text('Reintentar')),
      ],
    ),
  );
}

enum _ProfessionalRequestsFilter {
  newRequests('Nuevas', RequestState.pending),
  underReview('En revisión', RequestState.underReview),
  quoted('Cotizadas', RequestState.quoted),
  accepted('Aceptadas', RequestState.accepted),
  all('Todas', null);

  const _ProfessionalRequestsFilter(this.label, this.status);

  final String label;
  final RequestState? status;
}
