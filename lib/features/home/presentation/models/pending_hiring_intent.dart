class PendingHiringIntent {
  const PendingHiringIntent({
    required this.professionalId,
    required this.selectedService,
  });

  final String professionalId;
  final String selectedService;

  Map<String, Object?> toJson() => {
    'professionalId': professionalId,
    'selectedService': selectedService,
  };

  static PendingHiringIntent? fromJson(Map<String, Object?> json) {
    final professionalId = json['professionalId'];
    final selectedService = json['selectedService'];
    if (professionalId is! String ||
        professionalId.trim().isEmpty ||
        selectedService is! String ||
        selectedService.trim().isEmpty) {
      return null;
    }
    return PendingHiringIntent(
      professionalId: professionalId,
      selectedService: selectedService,
    );
  }
}
