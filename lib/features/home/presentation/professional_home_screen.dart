import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:linko/features/home/presentation/models/incoming_service_request.dart';
import 'package:linko/features/home/presentation/models/request_status.dart';
import 'package:linko/features/home/presentation/providers/professional_requests_provider.dart';
import 'package:linko/features/home/presentation/widgets/incoming_request_card.dart';
import 'package:linko/features/home/presentation/widgets/professional_bottom_navigation_widget.dart';
import 'package:linko/features/home/presentation/widgets/professional_dashboard_metric_card.dart';

class ProfessionalHomeScreen extends ConsumerWidget {
  const ProfessionalHomeScreen({
    required this.onRequestsSelected,
    required this.onRequestSelected,
    super.key,
  });

  final VoidCallback onRequestsSelected;
  final ValueChanged<IncomingServiceRequest> onRequestSelected;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final requests = ref.watch(professionalRequestsProvider).requests;
    final newCount = requests
        .where((request) => request.status == RequestStatus.newRequest)
        .length;
    final quotedCount = requests
        .where((request) => request.status == RequestStatus.quoted)
        .length;
    return Scaffold(
      appBar: AppBar(
        automaticallyImplyLeading: false,
        title: const Text('Inicio'),
      ),
      body: LayoutBuilder(
        builder: (context, constraints) {
          final horizontalPadding = constraints.maxWidth >= 720 ? 40.0 : 20.0;
          final requestColumns = constraints.maxWidth >= 1000 ? 3 : 1;

          return SingleChildScrollView(
            padding: EdgeInsets.fromLTRB(
              horizontalPadding,
              24,
              horizontalPadding,
              40,
            ),
            child: Center(
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 1100),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Text(
                      'Hola, Carlos',
                      style: Theme.of(context).textTheme.headlineMedium
                          ?.copyWith(fontWeight: FontWeight.w800),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      'Tienes nuevas solicitudes por revisar.',
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        color: Theme.of(context).colorScheme.onSurfaceVariant,
                      ),
                    ),
                    const SizedBox(height: 24),
                    SizedBox(
                      height: 136,
                      child: Row(
                        children: [
                          Expanded(
                            child: ProfessionalDashboardMetricCard(
                              label: 'Solicitudes nuevas',
                              value: newCount,
                              icon: Icons.inbox_outlined,
                            ),
                          ),
                          SizedBox(width: 10),
                          Expanded(
                            child: ProfessionalDashboardMetricCard(
                              label: 'Cotizaciones enviadas',
                              value: quotedCount,
                              icon: Icons.send_outlined,
                            ),
                          ),
                          SizedBox(width: 10),
                          Expanded(
                            child: ProfessionalDashboardMetricCard(
                              label: 'Servicios activos',
                              value: 1,
                              icon: Icons.home_repair_service_outlined,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 32),
                    Text(
                      'Solicitudes recientes',
                      style: Theme.of(context).textTheme.titleLarge?.copyWith(
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(height: 14),
                    GridView.builder(
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      itemCount: 3,
                      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                        crossAxisCount: requestColumns,
                        crossAxisSpacing: 14,
                        mainAxisSpacing: 14,
                        mainAxisExtent: 252,
                      ),
                      itemBuilder: (context, index) {
                        final request = requests[index];
                        return IncomingRequestCard(
                          request: request,
                          onViewRequest: () => onRequestSelected(request),
                        );
                      },
                    ),
                  ],
                ),
              ),
            ),
          );
        },
      ),
      bottomNavigationBar: ProfessionalBottomNavigationWidget(
        selectedIndex: 0,
        onDestinationSelected: (index) {
          if (index == 1) {
            onRequestsSelected();
          }
        },
      ),
    );
  }
}
