import 'dart:async';

class ProfessionalAvailabilityStore {
  final _suspended = <String>{};
  final _verified = <String, bool>{};
  final _changes = StreamController<void>.broadcast();

  Stream<void> get changes => _changes.stream;

  bool isAvailable(String professionalId) =>
      !_suspended.contains(professionalId) &&
      (_verified[professionalId] ?? true);

  bool isVerified(String professionalId) => _verified[professionalId] ?? false;

  void setVerified(String professionalId, {required bool verified}) {
    if (_verified[professionalId] == verified) return;
    _verified[professionalId] = verified;
    _changes.add(null);
  }

  void setSuspended(String professionalId, {required bool suspended}) {
    final changed = suspended
        ? _suspended.add(professionalId)
        : _suspended.remove(professionalId);
    if (changed) _changes.add(null);
  }
}
