import "dart:io" show Platform;

import "package:arcane_framework/arcane_framework.dart";
import "package:arcane_helper_utils/arcane_helper_utils.dart";
import "package:flutter/foundation.dart";
import "package:newrelic_mobile/config.dart";
import "package:newrelic_mobile/newrelic_mobile.dart";

class NewRelic implements LoggingInterface {
  static final NewRelic _instance = NewRelic._internal();
  static NewRelic get I => _instance;

  bool _initialized = false;
  @override
  bool get initialized => I._initialized;

  NewRelic._internal();

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
    if (Feature.newRelic.disabled) return;
    if (!initialized) return;

    final Map<String, dynamic> metadataToSend = metadata ?? {};

    // New Relic strips this out, anyway, so let's not cause additional logs.
    metadataToSend.removeWhere((key, _) => key == "timestamp");

    // Add the logging level to the metadata
    metadataToSend.putIfAbsent(
      "level",
      () => (level?.name ?? "debug").capitalize,
    );

    NewrelicMobile.instance.recordCustomEvent(
      "App",
      eventName: message,
      eventAttributes: metadataToSend,
    );

    if (stackTrace != null) {
      NewrelicMobile.instance.recordError(message, stackTrace);
    }
  }

  @override
  Future<NewRelic?> init() async {
    if (_mocked) return null;
    if (Feature.newRelic.disabled) return null;
    if (initialized) return I;

    final String appToken = AppEnv.valueOf(
      Platform.isAndroid
          ? EnvVar.newRelicAppTokenAndroid
          : EnvVar.newRelicAppTokenIos,
    );

    final Config config = Config(
      accessToken: appToken,

      //Android Specific
      // Optional: Enable or disable collection of event data.
      analyticsEventEnabled: true,
      // Optional: Enable or disable reporting successful HTTP requests to the MobileRequest event type.
      networkErrorRequestEnabled: true,
      // Optional: Enable or disable reporting network and HTTP request errors to the MobileRequestError event type.
      networkRequestEnabled: true,
      // Optional: Enable or disable crash reporting.
      crashReportingEnabled: true,
      // Optional: Enable or disable interaction tracing. Trace instrumentation still occurs, but no traces are harvested. This will disable default and custom interactions.
      interactionTracingEnabled: true,
      // Optional: Enable or disable capture of HTTP response bodies for HTTP error traces and MobileRequestError events.
      httpResponseBodyCaptureEnabled: true,
      // Optional: Enable or disable agent logging.
      loggingEnabled: true,
      // iOS specific
      // Optional: Enable or disable automatic instrumentation of WebViews
      webViewInstrumentation: false,
      //Optional: Enable or disable Print Statements as Analytics Events
      printStatementAsEventsEnabled: false,
      // Optional: Enable or disable automatic instrumentation of HTTP Request
      httpInstrumentationEnabled: true,
      // Optional: Enable or disable reporting data using different endpoints for US government clients
      fedRampEnabled: false,
      // Optional: Enable or disable offline data storage when no internet connection is available.
      offlineStorageEnabled: true,
      // iOS Specific
      // Optional: Enable or disable background reporting functionality.
      backgroundReportingEnabled: false,
      // iOS Specific
      // Optional: Enable or disable to use our new, more stable, event system for iOS agent.
      newEventSystemEnabled: true,

      // Optional: Enable or disable distributed tracing.
      distributedTracingEnabled: true,
    );

    await NewrelicMobile.instance.startAgent(config);

    // Initialization complete.
    I._initialized = true;

    return I;
  }
}
