enum RequestProgressStage {
  requestSent('Solicitud enviada'),
  professionalReviewing('Profesional revisando'),
  quotationSent('Cotización enviada'),
  quotationAccepted('Cotización aceptada'),
  workScheduled('Trabajo programado'),
  workInProgress('Trabajo en progreso'),
  workCompleted('Trabajo completado');

  const RequestProgressStage(this.label);

  final String label;
}

enum TimelineStepState { completed, active, pending }
