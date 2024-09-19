import "package:arcane_framework/arcane_framework.dart";
import "package:flutter/foundation.dart";
import "package:get_it/get_it.dart";
import "package:uuid/uuid.dart";

/// A singleton service that manages unique IDs, including install and session IDs.
///
/// The `IdService` provides a way to generate and retrieve unique identifiers
/// for application installs and sessions. It interacts with secure storage to persist
/// the install ID across app launches and generates new session IDs for each session.
class IdService extends ArcaneService {
  /// Whether the service is mocked for testing purposes.
  static bool _mocked = false;

  /// The singleton instance of `ArcaneIdService`.
  static final IdService _instance = IdService._internal();

  /// Provides access to the singleton instance of `IdService`.
  static IdService get I => _instance;

  IdService._internal();

  SecureStorageRepository get _storage => GetIt.I<SecureStorageRepository>();

  /// Whether the service has been initialized.
  bool _initialized = false;

  /// Returns `true` if the service has been initialized.
  bool get initialized => I._initialized;

  /// The unique install ID.
  ///
  /// This ID is persisted across app launches and is used to uniquely identify
  /// the installation of the app.
  String? _installId;

  /// Retrieves the install ID.
  ///
  /// If the install ID is not yet initialized, this method initializes the service
  /// and generates a new ID if necessary.
  ///
  /// Example:
  /// ```dart
  /// String? id = IdService.I.installId;
  /// ```
  String? get installId => I._installId;

  /// The unique session ID.
  ///
  /// This ID is generated for each app session and is used to uniquely identify
  /// the current session.
  String? _sessionId;

  /// Retrieves the session ID.
  ///
  /// If the session ID is not yet initialized, this method initializes the service
  /// and generates a new session ID.
  ///
  /// Example:
  /// ```dart
  /// String? sessionId = ArcaneIdService.I.sessionId.value;
  /// ```
  ValueListenable<String?> get sessionId =>
      ValueNotifier<String?>(I._sessionId);

  /// Generates a new unique ID.
  ///
  /// This method uses UUID version 7 to generate a new unique ID.
  String get newId => uuid.v7();

  /// The `Uuid` instance used for generating unique IDs.
  static const Uuid uuid = Uuid();

  /// Initializes the `IdService`.
  ///
  /// This method retrieves the install ID from secure storage, generating and storing a new
  /// one if it does not exist. It also generates a new session ID.
  ///
  /// Example:
  /// ```dart
  /// await IdService.I._init();
  /// ```
  Future<void> init() async {
    if (_mocked) return;
    Arcane.log(
      "Initializing ID Service",
      level: Level.debug,
    );

    I._installId = await _storage.getValue(
      SecureStorageRepository.installIdKey,
    );

    if (I._installId == null) {
      // Generate a new ID and store it
      I._installId = uuid.v7();
      await _storage.setValue(
        SecureStorageRepository.installIdKey,
        I._installId,
      );
    }

    I._sessionId = uuid.v7();
    I._initialized = true;
    notifyListeners();
  }

  /// Sets the service as mocked for testing purposes.
  ///
  /// When the service is mocked, it bypasses certain initializations and uses
  /// mocked data for testing.
  @visibleForTesting
  static void setMocked() => _mocked = true;
}

/// Enum representing different types of IDs managed by the `ArcaneIdService`.
///
/// The `ID` enum has two possible values:
/// - `session`: Represents the session ID.
/// - `install`: Represents the install ID.
enum ID {
  /// Represents the session ID.
  session,

  /// Represents the install ID.
  install,
}
