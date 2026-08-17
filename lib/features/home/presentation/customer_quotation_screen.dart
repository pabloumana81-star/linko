import 'package:flutter/material.dart';
import 'package:linko/core/utils/currency_formatter.dart';
import 'package:linko/features/home/presentation/widgets/request_section_title.dart';
import 'package:linko/features/home/presentation/widgets/request_summary_item.dart';
import 'package:linko/features/requests/domain/models/quotation.dart';
import 'package:linko/features/requests/domain/models/service_request.dart';
import 'package:linko/features/requests/domain/services/request_state_machine.dart';

class CustomerQuotationScreen extends StatelessWidget {
  const CustomerQuotationScreen({
    required this.request,
    required this.quotation,
    required this.onAccept,
    required this.onRequestChanges,
    super.key,
  });

  final ServiceRequest request;
  final Quotation quotation;
  final VoidCallback onAccept;
  final VoidCallback onRequestChanges;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    final actions = request.state.definition.customerActions;
    final canAccept = actions.contains(RequestAction.acceptQuotation);
    final canRequestChanges = actions.contains(
      RequestAction.requestQuotationChanges,
    );
    return Scaffold(
      appBar: AppBar(title: const Text('Ver cotización')),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(20, 20, 20, 132),
        children: [
          Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 760),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  const RequestSectionTitle(label: 'Resumen'),
                  RequestSummaryItem(
                    icon: Icons.person_outline_rounded,
                    label: 'Profesional',
                    value: request.professional.user.name,
                  ),
                  RequestSummaryItem(
                    icon: Icons.home_repair_service_outlined,
                    label: 'Servicio · Ubicación',
                    value:
                        '${request.serviceName} · ${request.displayLocation}',
                  ),
                  RequestSummaryItem(
                    icon: Icons.description_outlined,
                    label: 'Qué incluye',
                    value: quotation.workDescription,
                  ),
                  RequestSummaryItem(
                    icon: Icons.schedule_outlined,
                    label: 'Tiempo estimado',
                    value: quotation.estimatedDuration,
                  ),
                  RequestSummaryItem(
                    icon: Icons.event_available_outlined,
                    label: 'Fecha disponible',
                    value: quotation.startTiming,
                  ),
                  RequestSummaryItem(
                    icon: Icons.verified_user_outlined,
                    label: 'Garantía',
                    value: quotation.warrantyLabel,
                    showDivider: false,
                  ),
                  const SizedBox(height: 28),
                  Container(
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      color: colors.primaryContainer,
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Column(
                      children: [
                        Text(
                          'Precio total',
                          style: Theme.of(context).textTheme.titleMedium
                              ?.copyWith(color: colors.onPrimaryContainer),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          CurrencyFormatter.formatColones(
                            quotation.totalAmount,
                          ),
                          style: Theme.of(context).textTheme.headlineMedium
                              ?.copyWith(
                                color: colors.onPrimaryContainer,
                                fontWeight: FontWeight.w800,
                              ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
      bottomNavigationBar: !canAccept && !canRequestChanges
          ? null
          : SafeArea(
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
                        if (canAccept)
                          SizedBox(
                            width: double.infinity,
                            child: FilledButton(
                              onPressed: onAccept,
                              child: Text(RequestAction.acceptQuotation.label),
                            ),
                          ),
                        if (canRequestChanges)
                          TextButton(
                            onPressed: onRequestChanges,
                            child: Text(
                              RequestAction.requestQuotationChanges.label,
                            ),
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
