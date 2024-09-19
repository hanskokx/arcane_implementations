enum Feature {
  /// Prints the current auth token to the debug log each time the API makes a
  /// request.
  debugPrintAuthToken(kDebugMode),
  ;

  /// Determines whether the given [Feature] is enabled by default when the
  /// application launches. Features can be enabled or disabled during runtime,
  /// regardless of this value.
  final bool enabledAtStartup;

  const Feature(this.enabledAtStartup);
}
