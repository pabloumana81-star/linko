import 'dart:async';

class ProfessionalAvailabilityStore {
  final _suspended = <String>{};
  final _changes = StreamController<void>.broadcast();

  Stream<void> get changes => _changes.stream;

  bool isAvailable(String professionalId) =>
      !_suspended.contains(professionalId);

  void setSuspended(String professionalId, {required bool suspended}) {
    final changed = suspended
        ? _suspended.add(professionalId)
        : _suspended.remove(professionalId);
    if (changed) _changes.add(null);
  }
}
