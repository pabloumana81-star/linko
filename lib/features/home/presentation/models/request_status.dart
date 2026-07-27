enum RequestStatus {
  newRequest,
  underReview,
  quoted,
  accepted,
  rejected,
  inProgress,
  completed,
}

extension RequestStatusLabel on RequestStatus {
  String get label {
    return switch (this) {
      RequestStatus.newRequest => 'Nueva',
      RequestStatus.underReview => 'En revisión',
      RequestStatus.quoted => 'Cotizada',
      RequestStatus.accepted => 'Aceptada',
      RequestStatus.rejected => 'Rechazada',
      RequestStatus.inProgress => 'En progreso',
      RequestStatus.completed => 'Completada',
    };
  }
}
