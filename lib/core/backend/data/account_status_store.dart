import 'dart:async';

import 'package:linko/features/auth/domain/models/app_user_profile.dart';

class AccountStatusStore {
  final Map<String, AccountStatus> _statuses = {};
  final _changes = StreamController<String>.broadcast();

  AccountStatus statusOf(String userId) =>
      _statuses[userId] ?? AccountStatus.active;

  void setStatus(String userId, AccountStatus status) {
    if (statusOf(userId) == status) return;
    _statuses[userId] = status;
    _changes.add(userId);
  }

  Stream<AccountStatus> watch(String userId) => _changes.stream
      .where((changedUserId) => changedUserId == userId)
      .map((_) => statusOf(userId));
}
