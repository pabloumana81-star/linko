enum RequestState {
  pending,
  underReview,
  quoted,
  accepted,
  scheduled,
  inProgress,
  pendingCustomerConfirmation,
  completed,
  reviewed,
  cancelled,
}

typedef RequestStatus = RequestState;

extension RequestArchiveState on RequestStatus {
  bool get isArchived =>
      this == RequestStatus.reviewed || this == RequestStatus.cancelled;
}
