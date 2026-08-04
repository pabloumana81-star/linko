import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

void main() {
  late String migration;

  setUpAll(() {
    migration = File(
      'supabase/migrations/202608030004_resolve_beta_critical.sql',
    ).readAsStringSync();
  });

  test('versions professional catalog and ratings dependencies', () {
    expect(
      migration,
      contains('create table if not exists public.professional_profiles'),
    );
    expect(migration, contains('create table if not exists public.ratings'));
    expect(migration, contains('public.professional_rating_summaries'));
    expect(migration, contains('public.submit_service_rating'));
  });

  test('removes direct workflow mutation and validates intent RPCs', () {
    expect(
      migration,
      contains('drop policy if exists "Involved users can update requests"'),
    );
    expect(
      migration,
      contains('revoke execute on function public.apply_request_transition'),
    );
    expect(
      migration,
      contains('revoke execute on function public.append_request_event'),
    );
    expect(migration, contains('public.transition_request_status'));
    expect(
      migration,
      contains("raise exception 'Transición de solicitud no permitida.'"),
    );
    expect(migration, contains('public.propose_request_schedule'));
  });

  test('allows counterpart profile reads only through shared requests', () {
    expect(
      migration,
      contains('Request participants can read counterpart profiles'),
    );
    expect(
      migration,
      contains('profiles.id in (request.customer_id, request.professional_id)'),
    );
  });
}
