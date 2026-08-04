import 'dart:async';

import 'package:flutter_test/flutter_test.dart';
import 'package:linko/core/backend/data/supabase_backend_repositories.dart';
import 'package:linko_admin/features/admin/data/supabase_admin_dashboard_repository.dart';
import 'package:linko_admin/features/admin/data/supabase_admin_professionals_repository.dart';
import 'package:linko_admin/features/admin/domain/admin_dashboard.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

const _run = bool.fromEnvironment('RUN_SUPABASE_TESTS');
const _url = String.fromEnvironment('SUPABASE_URL');
const _anonKey = String.fromEnvironment('SUPABASE_ANON_KEY');
const _serviceKey = String.fromEnvironment('SUPABASE_TEST_SERVICE_ROLE_KEY');

void main() {
  test(
    'real Supabase certifies shared admin and main state',
    () async {
      if (_url.isEmpty || _anonKey.isEmpty || _serviceKey.isEmpty) {
        fail('Faltan variables de certificación Supabase.');
      }
      final service = SupabaseClient(_url, _serviceKey);
      final admin = SupabaseClient(_url, _anonKey);
      final customer = SupabaseClient(_url, _anonKey);
      final suffix = DateTime.now().microsecondsSinceEpoch;
      const password = 'LinkO-test-only-42!';
      final createdIds = <String>[];
      String? requestId;
      try {
        Future<User> create(String kind) async {
          final response = await service.auth.admin.createUser(
            AdminUserAttributes(
              email: 'linko-cert-$kind-$suffix@example.invalid',
              password: password,
              emailConfirm: true,
            ),
          );
          final user = response.user!;
          createdIds.add(user.id);
          return user;
        }

        final adminUser = await create('admin');
        final professional = await create('professional');
        final customerUser = await create('customer');
        await service
            .from('profiles')
            .update({'role': 'admin'})
            .eq('id', adminUser.id);
        await service.from('professional_profiles').insert({
          'id': professional.id,
          'display_name': 'Profesional Certificación $suffix',
          'profession': 'Certificación',
          'rating': 5,
          'review_count': 0,
          'location': 'San José',
          'verification_status': 'verified',
        });
        await admin.auth.signInWithPassword(
          email: 'linko-cert-admin-$suffix@example.invalid',
          password: password,
        );
        await customer.auth.signInWithPassword(
          email: 'linko-cert-customer-$suffix@example.invalid',
          password: password,
        );

        final mainRepository = SupabaseProfessionalsRepository(customer);
        final adminRepository = SupabaseAdminProfessionalsRepository(admin);
        final updates = StreamIterator(mainRepository.watchProfessionals());
        expect(await updates.moveNext(), isTrue);

        var next = updates.moveNext();
        await adminRepository.suspendProfessional(professional.id);
        expect(await next.timeout(const Duration(seconds: 20)), isTrue);
        expect(
          updates.current.any((item) => item.id == professional.id),
          isFalse,
        );

        next = updates.moveNext();
        await adminRepository.reactivateProfessional(professional.id);
        expect(await next.timeout(const Duration(seconds: 20)), isTrue);
        expect(
          updates.current.any((item) => item.id == professional.id),
          isTrue,
        );

        await service
            .from('professional_profiles')
            .update({'verification_status': 'pending'})
            .eq('id', professional.id);
        next = updates.moveNext();
        await adminRepository.approveVerification(professional.id);
        expect(await next.timeout(const Duration(seconds: 20)), isTrue);
        expect(
          updates.current.any((item) => item.id == professional.id),
          isTrue,
        );

        final request = await service
            .from('service_requests')
            .insert({
              'customer_id': customerUser.id,
              'professional_id': professional.id,
              'service_category': 'maintenance',
              'title': 'Certificación $suffix',
              'description': 'Registro aislado de certificación.',
            })
            .select('id')
            .single();
        requestId = request['id'] as String;
        await admin.rpc(
          'correct_admin_request_status',
          params: {'p_request_id': requestId, 'p_new_status': 'cancelled'},
        );
        final mainRequest = await customer
            .from('service_requests')
            .select('status')
            .eq('id', requestId)
            .single();
        expect(mainRequest['status'], 'cancelled');

        await SupabaseReportsRepository(customer).createReport(
          reporterId: customerUser.id,
          requestId: requestId,
          reason: 'Certificación $suffix',
        );
        final dashboard = await SupabaseAdminDashboardRepository(
          admin,
        ).loadDashboard(AdminDashboardRange.today);
        expect(
          dashboard.activities.any(
            (item) =>
                item.type == AdminActivityType.reportOpened &&
                item.title.contains('$suffix'),
          ),
          isTrue,
        );
        expect(await adminRepository.getAuditLog(professional.id), isNotEmpty);
        await updates.cancel();
      } finally {
        if (requestId != null) {
          await service
              .from('admin_request_audit_log')
              .delete()
              .eq('request_id', requestId);
          await service.from('reports').delete().eq('request_id', requestId);
          await service.from('service_requests').delete().eq('id', requestId);
        }
        for (final id in createdIds.reversed) {
          await service
              .from('admin_professional_audit_log')
              .delete()
              .eq('professional_id', id);
          await service.auth.admin.deleteUser(id);
        }
        await admin.dispose();
        await customer.dispose();
        await service.dispose();
      }
    },
    skip: _run ? false : 'RUN_SUPABASE_TESTS no está habilitado.',
    timeout: const Timeout(Duration(minutes: 3)),
  );
}
