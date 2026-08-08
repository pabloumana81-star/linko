enum AdminAccountType { customer, professional, admin }

extension AdminAccountTypeLabel on AdminAccountType {
  String get label => switch (this) {
    AdminAccountType.customer => 'Cliente',
    AdminAccountType.professional => 'Profesional',
    AdminAccountType.admin => 'Administrador',
  };
}

enum AdminAccountStatus { active, suspended }

extension AdminAccountStatusLabel on AdminAccountStatus {
  String get label => switch (this) {
    AdminAccountStatus.active => 'Activo',
    AdminAccountStatus.suspended => 'Suspendido',
  };
}

class AdminUser {
  const AdminUser({
    required this.id,
    required this.name,
    required this.email,
    required this.avatarUrl,
    required this.accountType,
    required this.status,
    required this.registeredAt,
    required this.lastLoginAt,
  });

  final String id;
  final String name;
  final String? email;
  final String? avatarUrl;
  final AdminAccountType accountType;
  final AdminAccountStatus status;
  final DateTime registeredAt;
  final DateTime? lastLoginAt;

  AdminUser copyWith({AdminAccountStatus? status}) => AdminUser(
    id: id,
    name: name,
    email: email,
    avatarUrl: avatarUrl,
    accountType: accountType,
    status: status ?? this.status,
    registeredAt: registeredAt,
    lastLoginAt: lastLoginAt,
  );
}

class AdminUserQuery {
  const AdminUserQuery({this.search = '', this.status, this.accountType});

  final String search;
  final AdminAccountStatus? status;
  final AdminAccountType? accountType;

  AdminUserQuery copyWith({
    String? search,
    AdminAccountStatus? status,
    bool clearStatus = false,
    AdminAccountType? accountType,
    bool clearAccountType = false,
  }) => AdminUserQuery(
    search: search ?? this.search,
    status: clearStatus ? null : status ?? this.status,
    accountType: clearAccountType ? null : accountType ?? this.accountType,
  );
}

class AdminUserDetail {
  const AdminUserDetail({
    required this.user,
    required this.activeRequests,
    required this.completedRequests,
    required this.ratings,
    required this.reports,
    required this.onboardingCompleted,
    required this.history,
  });

  final AdminUser user;
  final int activeRequests;
  final int completedRequests;
  final int ratings;
  final int reports;
  final bool onboardingCompleted;
  final List<AdminAuditEntry> history;
}

enum AdminAuditAction { accountSuspended, accountReactivated, onboardingReset }

extension AdminAuditActionLabel on AdminAuditAction {
  String get label => switch (this) {
    AdminAuditAction.accountSuspended => 'Cuenta suspendida',
    AdminAuditAction.accountReactivated => 'Cuenta reactivada',
    AdminAuditAction.onboardingReset => 'Onboarding reiniciado',
  };
}

class AdminAuditEntry {
  const AdminAuditEntry({
    required this.id,
    required this.adminId,
    required this.userId,
    required this.action,
    required this.timestamp,
  });

  final String id;
  final String adminId;
  final String userId;
  final AdminAuditAction action;
  final DateTime timestamp;
}
