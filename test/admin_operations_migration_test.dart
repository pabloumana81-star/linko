import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

void main() {
  final sql = File(
    'supabase/migrations/202608090002_admin_operations_closure.sql',
  ).readAsStringSync();

  test('admin operation RPCs enforce role, mandatory notes and audit', () {
    expect(sql, contains("profile.role = 'admin'"));
    expect(sql, contains("coalesce(trim(p_note), '') = ''"));
    expect(sql, contains('insert into public.admin_report_audit_log'));
    expect(sql, contains('insert into public.admin_request_audit_log'));
  });

  test('arbitrary request status correction is no longer client callable', () {
    expect(
      sql,
      contains(
        'revoke execute on function public.correct_admin_request_status(uuid,text)',
      ),
    );
    expect(
      sql,
      isNot(
        contains(
          'grant execute on function public.correct_admin_request_status',
        ),
      ),
    );
    expect(sql, contains("p_action = 'cancel'"));
    expect(
      sql,
      contains(
        "'pending_customer_confirmation', 'completed', 'reviewed', 'cancelled'",
      ),
    );
  });

  test('reports are never deleted and terminal operations cannot repeat', () {
    expect(sql, isNot(contains('delete from public.reports')));
    expect(sql, contains("previous in ('resolved', 'dismissed')"));
    expect(sql, contains("previous = next"));
  });
}
