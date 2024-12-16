import 'dart:developer' as dev;

import 'package:arcane_framework/arcane_framework.dart';
import 'package:arcane_helper_utils/arcane_helper_utils.dart';
import 'package:flutter/foundation.dart';

class DevLog implements LoggingInterface {
  static final DevLog _instance = DevLog._internal();
  static DevLog get I => _instance;

  final bool _initialized = true;

  @override
  bool get initialized => I._initialized;

  DevLog._internal();

  @visibleForTesting
  void setMocked() => _mocked = true;
  bool _mocked = false;

  @override
  void log(
    String message, {
    Map<String, dynamic>? metadata,
    Level? level,
    StackTrace? stackTrace,
    Object? extra,
  }) {
    // If the string is too long, the message won't print. This _shouldn't_ be
    // the case with `log`, yet here we are.
    for (final String part in message.splitByLength(256)) {
      dev.log(part);
    }
  }

  @override
  Future<LoggingInterface?> init() async {
    if (_mocked) return null;

    return I;
  }
}
