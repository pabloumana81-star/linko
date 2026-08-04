import 'dart:ui';

import 'package:flutter/foundation.dart';
import 'package:linko/core/diagnostics/diagnostics_service.dart';

class GlobalErrorHandler {
  GlobalErrorHandler(this.diagnostics);

  final DiagnosticsService diagnostics;

  FlutterExceptionHandler? _previousFlutterHandler;
  ErrorCallback? _previousPlatformHandler;

  void install() {
    _previousFlutterHandler = FlutterError.onError;
    _previousPlatformHandler = PlatformDispatcher.instance.onError;
    FlutterError.onError = (details) {
      diagnostics.unexpectedError(
        details.exception,
        details.stack ?? StackTrace.current,
        context: 'flutter_framework',
      );
      _previousFlutterHandler?.call(details);
    };
    PlatformDispatcher.instance.onError = (error, stackTrace) {
      diagnostics.unexpectedError(
        error,
        stackTrace,
        context: 'platform_dispatcher',
      );
      return _previousPlatformHandler?.call(error, stackTrace) ?? true;
    };
  }

  void restore() {
    FlutterError.onError = _previousFlutterHandler;
    PlatformDispatcher.instance.onError = _previousPlatformHandler;
  }
}
