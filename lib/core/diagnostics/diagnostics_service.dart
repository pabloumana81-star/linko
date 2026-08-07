import 'dart:convert';
import 'dart:developer' as developer;

import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:linko/features/requests/domain/models/request_state.dart';

enum WorkflowEventType {
  requestCreated,
  professionalAssigned,
  quoteSent,
  quoteAccepted,
  scheduleProposed,
  scheduleConfirmed,
  workStarted,
  workCompleted,
  ratingSubmitted,
}

class WorkflowDiagnosticEvent {
  const WorkflowDiagnosticEvent({
    required this.type,
    required this.requestId,
    required this.customerId,
    required this.professionalId,
    required this.timestamp,
    required this.previousState,
    required this.newState,
  });

  final WorkflowEventType type;
  final String requestId;
  final String customerId;
  final String professionalId;
  final DateTime timestamp;
  final RequestState? previousState;
  final RequestState newState;

  Map<String, Object?> toJson() => {
    'kind': 'workflow',
    'event': type.name,
    'requestId': requestId,
    'customerId': customerId,
    'professionalId': professionalId,
    'timestamp': timestamp.toUtc().toIso8601String(),
    'previousState': previousState?.name,
    'newState': newState.name,
  };
}

class UnexpectedErrorDiagnostic {
  const UnexpectedErrorDiagnostic({
    required this.error,
    required this.stackTrace,
    required this.timestamp,
    required this.context,
  });

  final Object error;
  final StackTrace stackTrace;
  final DateTime timestamp;
  final String context;

  Map<String, Object?> toJson() => {
    'kind': 'unexpected_error',
    'context': context,
    'error': error.toString(),
    'stackTrace': stackTrace.toString(),
    'timestamp': timestamp.toUtc().toIso8601String(),
  };
}

class BackendStartupDiagnostic {
  const BackendStartupDiagnostic({
    required this.backendMode,
    required this.hasSupabaseUrl,
    required this.hasSupabaseAnonKey,
    required this.repositoryImplementation,
    required this.timestamp,
  });

  final String backendMode;
  final bool hasSupabaseUrl;
  final bool hasSupabaseAnonKey;
  final String repositoryImplementation;
  final DateTime timestamp;

  Map<String, Object?> toJson() => {
    'kind': 'backend_startup',
    'backendMode': backendMode,
    'hasSupabaseUrl': hasSupabaseUrl,
    'hasSupabaseAnonKey': hasSupabaseAnonKey,
    'repositoryImplementation': repositoryImplementation,
    'timestamp': timestamp.toUtc().toIso8601String(),
  };
}

abstract interface class DiagnosticsSink {
  void write(Map<String, Object?> record);
}

class DeveloperLogDiagnosticsSink implements DiagnosticsSink {
  const DeveloperLogDiagnosticsSink();

  @override
  void write(Map<String, Object?> record) {
    developer.log(jsonEncode(record), name: 'linko.diagnostics');
  }
}

class DiagnosticsService extends ChangeNotifier {
  DiagnosticsService({DiagnosticsSink? sink, DateTime Function()? clock})
    : _sink = sink ?? const DeveloperLogDiagnosticsSink(),
      _clock = clock ?? DateTime.now;

  final DiagnosticsSink _sink;
  final DateTime Function() _clock;

  WorkflowDiagnosticEvent? _lastWorkflowEvent;
  WorkflowDiagnosticEvent? get lastWorkflowEvent => _lastWorkflowEvent;

  void workflow({
    required WorkflowEventType type,
    required String requestId,
    required String customerId,
    required String professionalId,
    required RequestState? previousState,
    required RequestState newState,
  }) {
    final event = WorkflowDiagnosticEvent(
      type: type,
      requestId: requestId,
      customerId: customerId,
      professionalId: professionalId,
      timestamp: _clock(),
      previousState: previousState,
      newState: newState,
    );
    _lastWorkflowEvent = event;
    _sink.write(event.toJson());
    notifyListeners();
  }

  void unexpectedError(
    Object error,
    StackTrace stackTrace, {
    required String context,
  }) {
    _sink.write(
      UnexpectedErrorDiagnostic(
        error: error,
        stackTrace: stackTrace,
        timestamp: _clock(),
        context: context,
      ).toJson(),
    );
  }

  void backendStartup({
    required String backendMode,
    required bool hasSupabaseUrl,
    required bool hasSupabaseAnonKey,
    required String repositoryImplementation,
  }) {
    _sink.write(
      BackendStartupDiagnostic(
        backendMode: backendMode,
        hasSupabaseUrl: hasSupabaseUrl,
        hasSupabaseAnonKey: hasSupabaseAnonKey,
        repositoryImplementation: repositoryImplementation,
        timestamp: _clock(),
      ).toJson(),
    );
  }

  Future<T> guard<T>(String context, Future<T> Function() operation) async {
    try {
      return await operation();
    } catch (error, stackTrace) {
      unexpectedError(error, stackTrace, context: context);
      rethrow;
    }
  }
}

final diagnosticsServiceProvider = Provider<DiagnosticsService>((ref) {
  final service = DiagnosticsService();
  ref.onDispose(service.dispose);
  return service;
});
