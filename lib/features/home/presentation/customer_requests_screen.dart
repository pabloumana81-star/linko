import 'package:flutter/material.dart';
import 'package:linko/features/home/presentation/models/customer_service_request.dart';
import 'package:linko/features/home/presentation/widgets/bottom_navigation_widget.dart';
import 'package:linko/features/home/presentation/widgets/customer_requests_empty_state.dart';
import 'package:linko/features/home/presentation/widgets/request_card.dart';
import 'package:linko/features/requests/domain/models/request_state.dart';

class CustomerRequestsScreen extends StatefulWidget {
  const CustomerRequestsScreen({
    required this.onHomeSelected,
    required this.onSearchSelected,
    required this.onRequestSelected,
    required this.requests,
    required this.onProfileSelected,
    super.key,
  });

  final VoidCallback onHomeSelected;
  final VoidCallback onSearchSelected;
  final ValueChanged<CustomerServiceRequest> onRequestSelected;
  final List<CustomerServiceRequest> requests;
  final VoidCallback onProfileSelected;

  @override
  State<CustomerRequestsScreen> createState() => _CustomerRequestsScreenState();
}

class _CustomerRequestsScreenState extends State<CustomerRequestsScreen> {
  bool _showArchived = false;

  @override
  Widget build(BuildContext context) {
    final visibleRequests = widget.requests
        .where((request) => request.status.isArchived == _showArchived)
        .toList();
    return Scaffold(
      appBar: AppBar(
        automaticallyImplyLeading: false,
        title: const Text('Mis solicitudes'),
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 12, 20, 0),
            child: SegmentedButton<bool>(
              segments: const [
                ButtonSegment(value: false, label: Text('Activas')),
                ButtonSegment(value: true, label: Text('Archivadas')),
              ],
              selected: {_showArchived},
              onSelectionChanged: (selection) {
                setState(() => _showArchived = selection.single);
              },
            ),
          ),
          Expanded(
            child: visibleRequests.isEmpty
                ? CustomerRequestsEmptyState(
                    onSearchProfessionals: widget.onSearchSelected,
                  )
                : Center(
                    child: ConstrainedBox(
                      constraints: const BoxConstraints(maxWidth: 760),
                      child: ListView.separated(
                        padding: const EdgeInsets.fromLTRB(20, 20, 20, 32),
                        itemCount: visibleRequests.length,
                        separatorBuilder: (context, index) =>
                            const SizedBox(height: 12),
                        itemBuilder: (context, index) {
                          final request = visibleRequests[index];
                          return RequestCard(
                            request: request,
                            onTap: () => widget.onRequestSelected(request),
                          );
                        },
                      ),
                    ),
                  ),
          ),
        ],
      ),
      bottomNavigationBar: BottomNavigationWidget(
        selectedIndex: 2,
        onDestinationSelected: (index) {
          if (index == 0) {
            widget.onHomeSelected();
          } else if (index == 1) {
            widget.onSearchSelected();
          } else if (index == 3) {
            widget.onProfileSelected();
          }
        },
      ),
    );
  }
}
