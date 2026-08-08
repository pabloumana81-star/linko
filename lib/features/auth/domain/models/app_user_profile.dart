import 'package:linko/app/app_mode.dart';

enum UserRole { user, admin }

enum AccountStatus { active, suspended }

class AppUserProfile {
  const AppUserProfile({
    required this.id,
    required this.displayName,
    required this.email,
    required this.avatarUrl,
    required this.activeMode,
    required this.createdAt,
    this.role = UserRole.user,
    this.accountStatus = AccountStatus.active,
    this.onboardingCompleted = true,
    DateTime? updatedAt,
  }) : updatedAt = updatedAt ?? createdAt;

  final String id;
  final String displayName;
  final String? email;
  final String? avatarUrl;
  final AppMode activeMode;
  final UserRole role;
  final AccountStatus accountStatus;
  final bool onboardingCompleted;
  final DateTime createdAt;
  final DateTime updatedAt;

  AppUserProfile copyWith({
    String? displayName,
    String? avatarUrl,
    AppMode? activeMode,
    UserRole? role,
    AccountStatus? accountStatus,
    bool? onboardingCompleted,
    DateTime? updatedAt,
  }) {
    return AppUserProfile(
      id: id,
      displayName: displayName ?? this.displayName,
      email: email,
      avatarUrl: avatarUrl ?? this.avatarUrl,
      activeMode: activeMode ?? this.activeMode,
      role: role ?? this.role,
      accountStatus: accountStatus ?? this.accountStatus,
      onboardingCompleted: onboardingCompleted ?? this.onboardingCompleted,
      createdAt: createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }
}
