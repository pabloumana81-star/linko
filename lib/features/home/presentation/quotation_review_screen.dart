import 'package:flutter/material.dart';
import 'package:linko/features/home/presentation/models/incoming_service_request.dart';
import 'package:linko/features/home/presentation/models/quotation_draft.dart';
import 'package:linko/features/home/presentation/widgets/quotation_widgets.dart';
import 'package:linko/features/home/presentation/widgets/request_section_title.dart';
import 'package:linko/features/home/presentation/widgets/request_summary_item.dart';

class QuotationReviewScreen extends StatelessWidget {
  const QuotationReviewScreen({
    required this.request,
    required this.draft,
    required this.onEdit,
    required this.onSend,
    super.key,
  });
  final IncomingServiceRequest request;
  final QuotationDraft draft;
  final VoidCallback onEdit;
  final VoidCallback onSend;

  @override
  Widget build(BuildContext context) {
    final start = draft.startTiming == QuotationStartTiming.proposedDate
        ? draft.proposedStartDate!.spanishDate
        : draft.startTiming.label;
    return Scaffold(
      appBar: AppBar(title: const Text('Revisar cotización')),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(20, 20, 20, 130),
        children: [
          Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 760),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  QuotationRequestSummary(request: request),
                  const SizedBox(height: 30),
                  const RequestSectionTitle(label: 'Resumen de costos'),
                  const SizedBox(height: 10),
                  QuotationCostSummary(
                    labor: draft.laborAmount,
                    materials: draft.materialsAmount,
                    totalLabel: 'Total estimado',
                  ),
                  const SizedBox(height: 30),
                  const RequestSectionTitle(label: 'Detalles de la cotización'),
                  RequestSummaryItem(
                    icon: Icons.description_outlined,
                    label: 'Trabajo incluido',
                    value: draft.workDescription,
                  ),
                  RequestSummaryItem(
                    icon: Icons.schedule_outlined,
                    label: 'Duración estimada',
                    value: draft.estimatedDuration.label,
                  ),
                  RequestSummaryItem(
                    icon: Icons.calendar_month_outlined,
                    label: 'Inicio propuesto',
                    value: start,
                  ),
                  RequestSummaryItem(
                    icon: Icons.event_available_outlined,
                    label: 'Validez',
                    value: '${draft.validityDays} días',
                    showDivider: false,
                  ),
                  const SizedBox(height: 24),
                  const QuotationInfoBanner(),
                ],
              ),
            ),
          ),
        ],
      ),
      bottomNavigationBar: SafeArea(
        top: false,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(20, 8, 20, 12),
          child: Center(
            heightFactor: 1,
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 760),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  SizedBox(
                    width: double.infinity,
                    child: FilledButton(
                      key: const ValueKey('send-quotation'),
                      onPressed: draft.totalAmount > 0 ? onSend : null,
                      child: const Text('Enviar cotización'),
                    ),
                  ),
                  if (draft.totalAmount <= 0)
                    Padding(
                      padding: const EdgeInsets.only(top: 8),
                      child: Text(
                        'Ingresa un monto válido antes de enviar.',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          color: Theme.of(context).colorScheme.error,
                        ),
                      ),
                    ),
                  TextButton(
                    onPressed: onEdit,
                    child: const Text('Editar cotización'),
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

extension on DateTime {
  String get spanishDate {
    const months = [
      'enero',
      'febrero',
      'marzo',
      'abril',
      'mayo',
      'junio',
      'julio',
      'agosto',
      'septiembre',
      'octubre',
      'noviembre',
      'diciembre',
    ];
    return '$day de ${months[month - 1]} de $year';
  }
}
