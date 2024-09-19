import "dart:convert";
import "dart:io" show Platform;

import "package:arcane_framework/arcane_framework.dart";
import "package:arcane_helper_utils/arcane_helper_utils.dart";
import "package:flutter/foundation.dart";
import "package:logger/logger.dart" as l;

class DebugConsole implements LoggingInterface {
  static final DebugConsole _instance = DebugConsole._internal();
  static DebugConsole get I => _instance;

  final bool _initialized = true;

  @override
  bool get initialized => I._initialized;

  DebugConsole._internal();

  @visibleForTesting
  void setMocked() => _mocked = true;
  bool _mocked = false;

  @override
  void log(
    String message, {
    Map<String, dynamic>? metadata,
    Level? level,
    StackTrace? stackTrace,
  }) {
    if (Feature.logging.disabled) return;
    if (Feature.debugConsoleLogging.disabled) return;
    if (!kDebugMode) return;
    if (!initialized) init();

    const Level cutoff = AppConfig.debugLoggingThreshold;

    if ((level?.value ?? Level.debug.value) < cutoff.value) return;

    final l.Level logLevel = l.Level.values
        .firstWhere((value) => value.name == (level ?? Level.debug).name);

    final Map<String, dynamic> localMetadata = metadata ?? {};

    final String? module = localMetadata["module"] as String?;
    final String? method = localMetadata["method"] as String?;

    const JsonEncoder encoder = JsonEncoder.withIndent("  ");
    final String? prettyprint =
        (localMetadata.isNotEmpty) ? encoder.convert(localMetadata) : null;

    final l.Logger logger = l.Logger(
      level: logLevel,
      printer: l.PrettyPrinter(
        methodCount: 2,
        errorMethodCount: kDebugMode &&
                !(level == Level.error ||
                    level == Level.warning ||
                    level == Level.trace ||
                    level == Level.fatal)
            ? 4
            : 8,
        stackTraceBeginIndex: 1,
        lineLength: 120,
        colors: !Platform.isIOS,
        printEmojis: kDebugMode,
        dateTimeFormat: l.DateTimeFormat.none,
      ),
    );

    // Print the message to the debug console
    String prefix = "";
    if (module != null) prefix += "[$module]";
    if (method != null) prefix += "[$method]";
    if (prefix.isNotEmpty) prefix += " ";
    message = "$prefix$message";

    if (prettyprint.isNotNullOrEmpty) message += "\n\n$prettyprint";

    localMetadata.removeWhere((key, value) => key == "module");
    localMetadata.removeWhere((key, value) => key == "method");
    localMetadata.removeWhere((key, value) => key == "filenameAndLineNumber");

    logger.log(
      logLevel,
      message,
      error: localMetadata["error"] ?? "",
      stackTrace: stackTrace,
    );
  }

  @override
  Future<LoggingInterface?> init() async {
    if (_mocked) return null;

    return I;
  }
}
