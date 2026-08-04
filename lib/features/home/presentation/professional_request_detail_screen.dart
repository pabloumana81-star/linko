import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:linko/features/home/presentation/models/incoming_service_request.dart';
import 'package:linko/features/home/presentation/models/request_draft.dart';
import 'package:linko/features/requests/domain/services/request_state_machine.dart';
import 'package:linko/core/backend/backend_providers.dart';
import 'package:linko/core/backend/backend_config.dart';
import 'package:linko/features/home/presentation/providers/professional_requests_provider.dart';
import 'package:linko/features/requests/presentation/adapters/request_view_adapters.dart';
import 'package:linko/features/requests/presentation/providers/request_providers.dart';
import 'package:linko/features/requests/presentation/providers/request_workflow_controller.dart';
import 'package:linko/features/home/presentation/widgets/customer_summary_card.dart';
import 'package:linko/features/home/presentation/widgets/request_info_banner.dart';
import 'package:linko/features/home/presentation/widgets/request_section_title.dart';
import 'package:linko/features/home/presentation/widgets/request_status_badge.dart';
import 'package:linko/features/home/presentation/widgets/request_summary_item.dart';

class ProfessionalRequestDetailScreen extends ConsumerWidget {
  const ProfessionalRequestDetailScreen({
    required this.request,
    required this.onBack,
    required this.onSendQuotation,
    required this.onOpenConversation,
    required this.onStartJob,
    required this.onMarkJobCompleted,
    super.key,
  });

  final IncomingServiceRequest request;
  final VoidCallback onBack;
  final ValueChanged<IncomingServiceRequest> onSendQuotation;
  final ValueChanged<IncomingServiceRequest> onOpenConversation;
  final ValueChanged<IncomingServiceRequest> onStartJob;
  final ValueChanged<IncomingServiceRequest> onMarkJobCompleted;

  Future<void> _confirmRejection(BuildContext context, WidgetRef ref) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Rechazar solicitud'),
          content: const Text(
            '¿Seguro que deseas rechazar esta solicitud? Esta acción solo '
            'actualizará el estado local.',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(false),
              child: const Text('Cancelar'),
            ),
            FilledButton(
              onPressed: () => Navigator.of(context).pop(true),
              child: const Text('Rechazar'),
            ),
          ],
        );
      },
    );

    if (confirmed != true || !context.mounted) {
      return;
    }
    try {
      await ref
          .read(requestWorkflowControllerProvider)
          .rejectRequest(request.id);
      ref
        ..invalidate(persistedProfessionalRequestsProvider)
        ..invalidate(persistedCustomerRequestsProvider)
        ..invalidate(persistedRequestDetailProvider(request.id));
      if (context.mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(const SnackBar(content: Text('Solicitud rechazada.')));
      }
    } catch (_) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('No pudimos actualizar el estado de la solicitud.'),
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    var currentRequest =
        ref.watch(backendRepositoriesProvider).mode == BackendMode.mock
        ? ref
              .watch(professionalRequestFlowProvider)
              .requests
              .firstWhere(
                (item) => item.id == request.id,
                orElse: () => request,
              )
        : ref
                  .watch(persistedRequestDetailProvider(request.id))
                  .value
                  ?.toIncomingRequest() ??
              request;
    if (ref.watch(backendRepositoriesProvider).mode == BackendMode.supabase) {
      final realtimeStatus = ref
          .watch(realtimeRequestStatusProvider(request.id))
          .value;
      if (realtimeStatus != null) {
        currentRequest = currentRequest.copyWith(status: realtimeStatus);
      }
    }
    final photoSummary = switch (currentRequest.attachedPhotoCount) {
      0 => 'No se agregaron fotos',
      1 => '1 foto adjunta',
      final count => '$count fotos adjuntas',
    };
    final actions = currentRequest.status.definition.professionalActions;
    final primaryAction =
        currentRequest.status.definition.professionalPrimaryAction;

    return Scaffold(
      appBar: AppBar(
        leading: BackButton(onPressed: onBack),
        title: const Text('Detalle de solicitud'),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(20, 20, 20, 36),
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 760),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                CustomerSummaryCard(request: currentRequest),
                const SizedBox(height: 18),
                Align(
                  alignment: Alignment.centerLeft,
                  child: RequestStatusBadge(status: currentRequest.status),
                ),
                const SizedBox(height: 28),
                const RequestSectionTitle(label: 'Detalles del servicio'),
                const SizedBox(height: 4),
                RequestSummaryItem(
                  icon: Icons.home_repair_service_outlined,
                  label: 'Servicio',
                  value: currentRequest.serviceCategory,
                ),
                RequestSummaryItem(
                  icon: Icons.description_outlined,
                  label: 'Descripción',
                  value: currentRequest.description,
                ),
                RequestSummaryItem(
                  icon: Icons.location_on_outlined,
                  label: 'Ubicación',
                  value: currentRequest.location,
                ),
                RequestSummaryItem(
                  icon: Icons.schedule_outlined,
                  label: 'Cuándo',
                  value: currentRequest.timing.label,
                ),
                if (currentRequest.selectedDate != null)
                  RequestSummaryItem(
                    icon: Icons.calendar_month_outlined,
                    label: 'Fecha',
                    value: currentRequest.selectedDate!.spanishDate,
                  ),
                RequestSummaryItem(
                  icon: Icons.photo_library_outlined,
                  label: 'Fotos adjuntas',
                  value: photoSummary,
                ),
                RequestSummaryItem(
                  icon: Icons.event_outlined,
                  label: 'Solicitud creada',
                  value: currentRequest.creationDate,
                  showDivider: false,
                ),
                const SizedBox(height: 18),
                RequestInfoBanner(
                  message: currentRequest.status.definition.nextStep,
                ),
              ],
            ),
          ),
        ),
      ),
      bottomNavigationBar: SafeArea(
        top: false,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(20, 10, 20, 12),
          child: Center(
            heightFactor: 1,
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 760),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  if (primaryAction != null)
                    SizedBox(
                      width: double.infinity,
                      height: 52,
                      child: FilledButton(
                        key: ValueKey(
                          'professional-action-${primaryAction.name}',
                        ),
                        onPressed: () =>
                            _runAction(primaryAction, currentRequest),
                        child: Text(primaryAction.label),
                      ),
                    ),
                  if (actions.contains(RequestAction.openConversation) &&
                      primaryAction != RequestAction.openConversation) ...[
                    const SizedBox(height: 8),
                    SizedBox(
                      width: double.infinity,
                      child: OutlinedButton.icon(
                        onPressed: () => onOpenConversation(currentRequest),
                        icon: const Icon(Icons.chat_bubble_outline_rounded),
                        label: const Text('Abrir conversación'),
                      ),
                    ),
                  ],
                  const SizedBox(height: 4),
                  if (actions.contains(RequestAction.rejectRequest))
                    TextButton(
                      onPressed: () => _confirmRejection(context, ref),
                      child: Text(RequestAction.rejectRequest.label),
                    ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  void _runAction(RequestAction action, IncomingServiceRequest currentRequest) {
    switch (action) {
      case RequestAction.sendQuotation || RequestAction.viewQuotation:
        onSendQuotation(currentRequest);
      case RequestAction.proposeSchedule || RequestAction.openConversation:
        onOpenConversation(currentRequest);
      case RequestAction.startJob:
        onStartJob(currentRequest);
      case RequestAction.markJobCompleted:
        onMarkJobCompleted(currentRequest);
      default:
        break;
    }
  }
}
