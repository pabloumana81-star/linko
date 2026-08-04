import 'package:linko/features/requests/domain/models/quotation.dart';
import 'package:linko/features/requests/domain/models/timeline_event.dart';

class RequestWorkflowSupabaseMapper {
  const RequestWorkflowSupabaseMapper();

  Quotation quotationFromRow(Map<String, dynamic> row) => Quotation(
    requestId: row['request_id'] as String,
    professionalId: row['professional_id'] as String,
    laborAmount: (row['price'] as num).round(),
    materialsAmount: 0,
    workDescription: row['description'] as String,
    estimatedDuration: row['estimated_duration'] as String,
    startTiming: '',
    validityDays: 0,
    status: switch (row['status']) {
      'pending' => QuotationStatus.pending,
      'accepted' => QuotationStatus.accepted,
      'rejected' => QuotationStatus.rejected,
      _ => throw const FormatException('Estado de cotización inválido.'),
    },
    createdAt: DateTime.parse(row['created_at'] as String).toUtc(),
  );

  TimelineEvent eventFromRow(Map<String, dynamic> row) {
    final type = row['type'] as String;
    final payload = row['payload'] is Map
        ? Map<String, dynamic>.from(row['payload'] as Map)
        : <String, dynamic>{};
    final presentation = _eventPresentation(type);
    final createdAt = DateTime.parse(row['created_at'] as String).toUtc();
    return TimelineEvent(
      id: row['id'] as String,
      requestId: row['request_id'] as String,
      stage: presentation.stage,
      title: presentation.title,
      description:
          payload['description'] as String? ?? presentation.description,
      dateLabel: 'Recientemente',
      type: type,
      payload: payload,
      createdAt: createdAt,
    );
  }

  ({TimelineStage stage, String title, String description}) _eventPresentation(
    String type,
  ) => switch (type) {
    'quotation_created' => (
      stage: TimelineStage.quotationSent,
      title: 'Cotización enviada',
      description: 'El profesional envió una cotización.',
    ),
    'quotation_accepted' => (
      stage: TimelineStage.quotationAccepted,
      title: 'Cotización aceptada',
      description: 'El cliente aceptó la cotización.',
    ),
    'quotation_rejected' => (
      stage: TimelineStage.quotationSent,
      title: 'Cotización rechazada',
      description: 'El cliente rechazó la cotización.',
    ),
    'schedule_proposed' => (
      stage: TimelineStage.quotationAccepted,
      title: 'Fecha propuesta',
      description: 'El profesional propuso una fecha.',
    ),
    'schedule_accepted' => (
      stage: TimelineStage.workScheduled,
      title: 'Trabajo programado',
      description: 'El cliente confirmó la fecha.',
    ),
    'work_started' => (
      stage: TimelineStage.workInProgress,
      title: 'Trabajo iniciado',
      description: 'El profesional inició el trabajo.',
    ),
    'work_completed' => (
      stage: TimelineStage.workCompleted,
      title: 'Trabajo completado',
      description: 'El profesional marcó el trabajo como completado.',
    ),
    'rating_requested' => (
      stage: TimelineStage.workCompleted,
      title: 'Calificación solicitada',
      description: 'El servicio está listo para ser calificado.',
    ),
    _ => throw const FormatException('Tipo de evento de solicitud inválido.'),
  };
}

class RequestEventBuffer {
  final Map<String, TimelineEvent> _events = {};

  List<TimelineEvent> merge(Iterable<TimelineEvent> events) {
    for (final event in events) {
      _events[event.id] = event;
    }
    final result = _events.values.toList()
      ..sort((left, right) {
        final comparison = (left.createdAt ?? DateTime(1970)).compareTo(
          right.createdAt ?? DateTime(1970),
        );
        return comparison != 0 ? comparison : left.id.compareTo(right.id);
      });
    return List.unmodifiable(result);
  }
}
