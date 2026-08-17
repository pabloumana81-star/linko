import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:linko/core/backend/backend_config.dart';
import 'package:linko/core/backend/backend_providers.dart';
import 'package:linko/features/home/data/pending_hiring_intent_store.dart';
import 'package:linko/features/home/presentation/models/pending_hiring_intent.dart';

final pendingHiringIntentStoreProvider = Provider<PendingHiringIntentStore>(
  (ref) => ref.watch(backendRepositoriesProvider).mode == BackendMode.supabase
      ? SharedPreferencesPendingHiringIntentStore()
      : MemoryPendingHiringIntentStore(),
);

final pendingHiringIntentProvider =
    AsyncNotifierProvider<PendingHiringIntentController, PendingHiringIntent?>(
      PendingHiringIntentController.new,
    );

class PendingHiringIntentController
    extends AsyncNotifier<PendingHiringIntent?> {
  @override
  Future<PendingHiringIntent?> build() =>
      ref.watch(pendingHiringIntentStoreProvider).read();

  Future<void> save(PendingHiringIntent intent) async {
    await ref.read(pendingHiringIntentStoreProvider).write(intent);
    state = AsyncData(intent);
  }

  Future<void> clear() async {
    await ref.read(pendingHiringIntentStoreProvider).clear();
    state = const AsyncData(null);
  }
}
