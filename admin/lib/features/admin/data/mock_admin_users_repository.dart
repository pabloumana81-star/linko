import 'package:linko_admin/features/admin/domain/admin_user.dart';
import 'package:linko_admin/features/admin/domain/admin_users_repository.dart';
import 'package:linko/core/backend/data/account_status_store.dart';
import 'package:linko/features/auth/domain/models/app_user_profile.dart';
import 'package:linko/features/requests/domain/models/request_state.dart';
import 'package:linko/features/requests/domain/models/service_request.dart';
import 'package:linko/features/requests/domain/repositories/request_repository.dart';

class MockAdminUsersRepository implements AdminUsersRepository {
  MockAdminUsersRepository(
    this._requests, {
    DateTime Function()? clock,
    this.adminId = 'admin-user',
    AccountStatusStore? accountStatuses,
  }) : _clock = clock ?? DateTime.now,
       _accountStatuses = accountStatuses ?? AccountStatusStore();

  final RequestRepository _requests;
  final DateTime Function() _clock;
  final String adminId;
  final AccountStatusStore _accountStatuses;
  final Map<String, bool> _onboarding = {};
  final List<AdminAuditEntry> _audit = [];

  @override
  Future<List<AdminUser>> listUsers(AdminUserQuery query) async {
    final normalized = query.search.trim().toLowerCase();
    final users = _users().values.where((user) {
      final matchesSearch =
          normalized.isEmpty ||
          user.name.toLowerCase().contains(normalized) ||
          (user.email?.toLowerCase().contains(normalized) ?? false) ||
          user.id.toLowerCase().contains(normalized);
      return matchesSearch &&
          (query.status == null || user.status == query.status) &&
          (query.accountType == null || user.accountType == query.accountType);
    }).toList()..sort((left, right) => left.name.compareTo(right.name));
    return List.unmodifiable(users);
  }

  @override
  Future<AdminUserDetail?> getUser(String userId) async {
    final user = _users()[userId];
    if (user == null) return null;
    final requests = _userRequests(userId);
    return AdminUserDetail(
      user: user,
      activeRequests: requests
          .where((request) => !request.state.isArchived)
          .length,
      completedRequests: requests
          .where(
            (request) =>
                request.state == RequestState.completed ||
                request.state == RequestState.reviewed,
          )
          .length,
      ratings: requests
          .where((request) => _requests.getRating(request.id) != null)
          .length,
      reports: 0,
      onboardingCompleted: _onboarding[userId] ?? true,
      history: await getAuditLog(userId),
    );
  }

  @override
  Future<void> suspendUser(String userId) async {
    _requireUser(userId);
    if (_accountStatuses.statusOf(userId) == AccountStatus.suspended) return;
    _accountStatuses.setStatus(userId, AccountStatus.suspended);
    _record(userId, AdminAuditAction.accountSuspended);
  }

  @override
  Future<void> reactivateUser(String userId) async {
    _requireUser(userId);
    if (_accountStatuses.statusOf(userId) == AccountStatus.active) {
      return;
    }
    _accountStatuses.setStatus(userId, AccountStatus.active);
    _record(userId, AdminAuditAction.accountReactivated);
  }

  @override
  Future<void> resetOnboarding(String userId) async {
    _requireUser(userId);
    _onboarding[userId] = false;
    _record(userId, AdminAuditAction.onboardingReset);
  }

  @override
  Future<List<AdminAuditEntry>> getAuditLog(String userId) async =>
      List.unmodifiable(
        _audit.where((entry) => entry.userId == userId).toList().reversed,
      );

  Map<String, AdminUser> _users() {
    final users = <String, AdminUser>{};
    final professionalIds = <String>{};
    final dates = <String, DateTime>{};
    final names = <String, String>{};
    for (final request in _requests.getCustomerRequests('customer-current')) {
      names[request.customer.id] = request.customer.name;
      names[request.professional.user.id] = request.professional.user.name;
      professionalIds.add(request.professional.user.id);
      final date = request.createdAt ?? request.updatedAt;
      dates.update(
        request.customer.id,
        (current) => date.isBefore(current) ? date : current,
        ifAbsent: () => date,
      );
      dates.update(
        request.professional.user.id,
        (current) => date.isBefore(current) ? date : current,
        ifAbsent: () => date,
      );
    }
    names[adminId] = 'Administración LinkO';
    dates[adminId] = DateTime(2026, 1, 1);
    for (final entry in names.entries) {
      final type = entry.key == adminId
          ? AdminAccountType.admin
          : professionalIds.contains(entry.key)
          ? AdminAccountType.professional
          : AdminAccountType.customer;
      users[entry.key] = AdminUser(
        id: entry.key,
        name: entry.value,
        email: '${entry.key}@mock.linko',
        avatarUrl: null,
        accountType: type,
        status: _accountStatuses.statusOf(entry.key) == AccountStatus.suspended
            ? AdminAccountStatus.suspended
            : AdminAccountStatus.active,
        registeredAt: dates[entry.key]!,
        lastLoginAt: dates[entry.key]!.add(const Duration(days: 1)),
      );
    }
    return users;
  }

  List<ServiceRequest> _userRequests(String userId) => _requests
      .getCustomerRequests('customer-current')
      .where(
        (request) =>
            request.customer.id == userId ||
            request.professional.user.id == userId,
      )
      .toList();

  void _requireUser(String userId) {
    if (!_users().containsKey(userId)) {
      throw StateError('No se encontró el usuario.');
    }
  }

  void _record(String userId, AdminAuditAction action) {
    _audit.add(
      AdminAuditEntry(
        id: 'audit-${_audit.length + 1}',
        adminId: adminId,
        userId: userId,
        action: action,
        timestamp: _clock().toUtc(),
      ),
    );
  }
}
