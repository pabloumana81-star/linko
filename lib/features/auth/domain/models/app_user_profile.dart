import 'package:linko/app/app_mode.dart';

class AppUserProfile {
  const AppUserProfile({
    required this.id,
    required this.displayName,
    required this.email,
    required this.avatarUrl,
    required this.activeMode,
    required this.createdAt,
    DateTime? updatedAt,
  }) : updatedAt = updatedAt ?? createdAt;

  final String id;
  final String displayName;
  final String? email;
  final String? avatarUrl;
  final AppMode activeMode;
  final DateTime createdAt;
  final DateTime updatedAt;

  AppUserProfile copyWith({
    String? displayName,
    String? avatarUrl,
    AppMode? activeMode,
    DateTime? updatedAt,
  }) {
    return AppUserProfile(
      id: id,
      displayName: displayName ?? this.displayName,
      email: email,
      avatarUrl: avatarUrl ?? this.avatarUrl,
      activeMode: activeMode ?? this.activeMode,
      createdAt: createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }
}
