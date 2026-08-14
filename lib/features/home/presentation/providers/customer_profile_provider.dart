import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:linko/core/backend/backend_providers.dart';
import 'package:linko/features/auth/domain/models/app_user_profile.dart';
import 'package:linko/features/auth/presentation/auth_controller.dart';

final customerProfileProvider = StreamProvider<AppUserProfile?>((ref) {
  final user = ref.watch(authControllerProvider).user;
  if (user == null) return const Stream.empty();
  final updates = ref.watch(profileRepositoryProvider).watchProfile(user.id);
  return (() async* {
    yield user;
    yield* updates;
  })();
});
