import "dart:io";

import "package:app_tracking_transparency/app_tracking_transparency.dart";
import "package:arcane_framework/arcane_framework.dart";
import "package:flutter/material.dart";
import "package:flutter_gen/gen_l10n/app_localizations.dart";

class TrackingService {
  TrackingService._internal();

  static final TrackingService _instance = TrackingService._internal();

  static TrackingService get I => _instance;

  TrackingStatus _trackingStatus = TrackingStatus.notDetermined;

  TrackingStatus get trackingStatus => I._trackingStatus;

  bool _initialized = false;

  bool get initialized => I._initialized;

  @visibleForTesting
  void setMocked() => _mocked = true;
  bool _mocked = false;

  Future<void> init() async {
    if (_mocked) return;

    _trackingStatus = await AppTrackingTransparency.trackingAuthorizationStatus;

    if (!(Platform.isIOS || Platform.isMacOS)) {
      _trackingStatus = TrackingStatus.authorized;
    }

    _initialized = true;
  }

  Future<TrackingStatus?> initalizeAppTracking(BuildContext context) async {
    if (_mocked) return null;
    if (!initialized) await init();

    // If the system can show an authorization request dialog
    if (trackingStatus == TrackingStatus.notDetermined) {
      // Show a custom explainer dialog before the system dialog
      if (!context.mounted) return null;
      await _showTrackingDialog(context);
      // Wait for dialog popping animation
      await Future.delayed(const Duration(milliseconds: 200));
      // Request system's tracking authorization dialog
      await AppTrackingTransparency.requestTrackingAuthorization();
    }

    _trackingStatus = await AppTrackingTransparency.trackingAuthorizationStatus;

    if (trackingStatus == TrackingStatus.authorized) {
      await Arcane.logger.initializeInterfaces();
    }

    return trackingStatus;
  }

  Future<void> _showTrackingDialog(BuildContext context) async {
    await showAdaptiveDialog<void>(
      context: context,
      builder: (context) {
        final buttonStyle = Theme.of(context).textButtonTheme.style?.copyWith(
              textStyle: const WidgetStatePropertyAll(
                TextStyle(
                  decoration: TextDecoration.none,
                ),
              ),
            );
        return AlertDialog.adaptive(
          title: Text(AppLocalizations.of(context).appTrackingTitle),
          content: Text(AppLocalizations.of(context).appTrackingBody),
          actions: [
            TextButton(
              style: buttonStyle,
              onPressed: () async {
                Navigator.of(context).pop();
              },
              child: Text(AppLocalizations.of(context).continueText),
            ),
          ],
        );
      },
    );
  }
}
