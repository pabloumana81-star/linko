import 'dart:convert';

import 'package:flutter/services.dart';
import 'package:linko/features/home/presentation/models/pending_hiring_intent.dart';
import 'package:shared_preferences/shared_preferences.dart';

abstract interface class PendingHiringIntentStore {
  Future<PendingHiringIntent?> read();
  Future<void> write(PendingHiringIntent intent);
  Future<void> clear();
}

class SharedPreferencesPendingHiringIntentStore
    implements PendingHiringIntentStore {
  static const _key = 'linko.pending_hiring_intent.v1';
  static String? _testFallback;

  @override
  Future<PendingHiringIntent?> read() async {
    final encoded = await _readEncoded();
    if (encoded == null) return null;
    try {
      final decoded = jsonDecode(encoded);
      if (decoded is! Map) return null;
      return PendingHiringIntent.fromJson(
        decoded.map((key, value) => MapEntry(key.toString(), value)),
      );
    } on FormatException {
      return null;
    }
  }

  @override
  Future<void> write(PendingHiringIntent intent) async {
    final encoded = jsonEncode(intent.toJson());
    try {
      final preferences = await SharedPreferences.getInstance();
      final saved = await preferences.setString(_key, encoded);
      if (!saved) throw StateError('No se pudo guardar la intención.');
    } on MissingPluginException {
      _testFallback = encoded;
    }
  }

  @override
  Future<void> clear() async {
    try {
      final preferences = await SharedPreferences.getInstance();
      await preferences.remove(_key);
    } on MissingPluginException {
      _testFallback = null;
    }
  }

  Future<String?> _readEncoded() async {
    try {
      final preferences = await SharedPreferences.getInstance();
      return preferences.getString(_key);
    } on MissingPluginException {
      return _testFallback;
    }
  }
}

class MemoryPendingHiringIntentStore implements PendingHiringIntentStore {
  PendingHiringIntent? value;

  @override
  Future<PendingHiringIntent?> read() async => value;

  @override
  Future<void> write(PendingHiringIntent intent) async => value = intent;

  @override
  Future<void> clear() async => value = null;
}
