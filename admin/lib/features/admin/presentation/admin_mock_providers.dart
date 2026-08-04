import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:linko/core/backend/backend_providers.dart';
import 'package:linko_admin/features/admin/data/mock_admin_state.dart';

final mockAdminStateProvider = Provider<MockAdminState>((ref) {
  return MockAdminState(
    availability: ref
        .watch(backendRepositoriesProvider)
        .professionalAvailability,
  );
});
