import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:linko/features/home/presentation/models/incoming_service_request.dart';
import 'package:linko/features/home/presentation/models/request_draft.dart';
import 'package:linko/features/home/presentation/models/request_status.dart';
import 'package:linko/features/home/presentation/providers/professional_requests_provider.dart';
import 'package:linko/features/home/presentation/widgets/customer_summary_card.dart';
import 'package:linko/features/home/presentation/widgets/request_info_banner.dart';
import 'package:linko/features/home/presentation/widgets/request_section_title.dart';
import 'package:linko/features/home/presentation/widgets/request_status_badge.dart';
import 'package:linko/features/home/presentation/widgets/request_summary_item.dart';

class ProfessionalRequestDetailScreen extends ConsumerWidget {
  const ProfessionalRequestDetailScreen({
    required this.request,
    required this.onSendQuotation,
    super.key,
  });

  final IncomingServiceRequest request;
  final ValueChanged<IncomingServiceRequest> onSendQuotation;

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
    ref.read(professionalRequestsProvider.notifier).reject(request.id);
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(const SnackBar(content: Text('Solicitud rechazada.')));
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final currentRequest = ref
        .watch(professionalRequestsProvider)
        .requests
        .firstWhere((item) => item.id == request.id, orElse: () => request);
    final photoSummary = switch (currentRequest.attachedPhotoCount) {
      0 => 'No se agregaron fotos',
      1 => '1 foto adjunta',
      final count => '$count fotos adjuntas',
    };
    final wasRejected = currentRequest.status == RequestStatus.rejected;
    final wasQuoted = currentRequest.status == RequestStatus.quoted;

    return Scaffold(
      appBar: AppBar(
        automaticallyImplyLeading: true,
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
                const RequestInfoBanner(
                  message:
                      'Revisa los detalles antes de enviar una cotización.',
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
                  SizedBox(
                    width: double.infinity,
                    height: 52,
                    child: FilledButton(
                      onPressed: wasRejected
                          ? null
                          : () => onSendQuotation(currentRequest),
                      child: Text(
                        wasQuoted ? 'Ver cotización' : 'Enviar cotización',
                      ),
                    ),
                  ),
                  const SizedBox(height: 4),
                  TextButton(
                    onPressed: wasRejected || wasQuoted
                        ? null
                        : () => _confirmRejection(context, ref),
                    child: const Text('Rechazar solicitud'),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
