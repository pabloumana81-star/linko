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
