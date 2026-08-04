import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

void main() {
  late String migration;

  setUpAll(() async {
    migration = await File(
      '../supabase/migrations/202608030006_create_admin_dashboard.sql',
    ).readAsString();
  });

  test('admin dashboard RPC validates the caller role', () {
    expect(migration, contains('profile.role = \'admin\''));
    expect(migration, contains('No tienes permisos de administrador.'));
    expect(
      migration,
      contains('revoke execute on function public.get_admin_dashboard'),
    );
  });

  test('dashboard aggregates every persisted activity source', () {
    for (final source in [
      'public.profiles',
      'public.professional_profiles',
      'public.service_requests',
      'public.quotations',
      'public.request_events',
      'public.reports',
      'public.ratings',
    ]) {
      expect(migration, contains(source));
    }
    for (final activityType in [
      'userRegistered',
      'professionalCreated',
      'requestCreated',
      'quotationSent',
      'jobCompleted',
      'reportOpened',
    ]) {
      expect(migration, contains(activityType));
    }
  });
}
