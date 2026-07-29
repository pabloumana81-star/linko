import 'package:flutter/material.dart';
import 'package:linko/features/home/presentation/models/customer_service_request.dart';
import 'package:linko/features/home/presentation/widgets/bottom_navigation_widget.dart';
import 'package:linko/features/home/presentation/widgets/customer_requests_empty_state.dart';
import 'package:linko/features/home/presentation/widgets/request_card.dart';

class CustomerRequestsScreen extends StatelessWidget {
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
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        automaticallyImplyLeading: false,
        title: const Text('Mis solicitudes'),
      ),
      body: requests.isEmpty
          ? CustomerRequestsEmptyState(onSearchProfessionals: onSearchSelected)
          : Center(
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 760),
                child: ListView.separated(
                  padding: const EdgeInsets.fromLTRB(20, 20, 20, 32),
                  itemCount: requests.length,
                  separatorBuilder: (context, index) =>
                      const SizedBox(height: 12),
                  itemBuilder: (context, index) {
                    final request = requests[index];
                    return RequestCard(
                      request: request,
                      onTap: () => onRequestSelected(request),
                    );
                  },
                ),
              ),
            ),
      bottomNavigationBar: BottomNavigationWidget(
        selectedIndex: 2,
        onDestinationSelected: (index) {
          if (index == 0) {
            onHomeSelected();
          } else if (index == 1) {
            onSearchSelected();
          } else if (index == 3) {
            onProfileSelected();
          }
        },
      ),
    );
  }
}
