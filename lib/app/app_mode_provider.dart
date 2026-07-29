import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:linko/app/app_mode.dart';

class AppModeNotifier extends Notifier<AppMode> {
  @override
  AppMode build() => AppMode.customer;

  void select(AppMode mode) {
    state = mode;
  }
}

final appModeProvider = NotifierProvider<AppModeNotifier, AppMode>(
  AppModeNotifier.new,
);
