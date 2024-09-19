import "package:arcane_framework/arcane_framework.dart";
import "package:arcane_helper_utils/arcane_helper_utils.dart";
import "package:flutter/foundation.dart";
import "package:flutter_secure_storage/flutter_secure_storage.dart";

class SecureStorageRepository {
  final FlutterSecureStorage _storage;

  SecureStorageRepository(this._storage);

  static const String installIdKey = "install_id";

  Future<bool> deleteAll() async {
    try {
      final String? cachedInstallId = await getValue(installIdKey);

      await _storage.deleteAll();

      if (cachedInstallId.isNotNullOrEmpty) {
        await setValue(installIdKey, cachedInstallId);
      }

      return true;
    } catch (exception) {
      return false;
    }
  }

  Future<String?> getValue(String key) async {
    if (Feature.secureStorageRepositoryLogs.enabled) {
      Arcane.log(
        "Value requested from secure storage",
        level: Level.debug,
        metadata: {
          "key": key,
        },
      );
    }

    String? value;

    try {
      value = await _storage.read(key: key);
      if (value.isNullOrEmpty && Feature.secureStorageRepositoryLogs.enabled) {
        Arcane.log(
          "Value retrieved from secure storage is empty",
          level: Level.info,
          metadata: {
            "key": key,
          },
        );
      }

      if (Feature.secureStorageRepositoryLogs.enabled) {
        Arcane.log(
          "Successfully retrived value from secure storage",
          level: Level.debug,
          metadata: {
            "key": key,
            if (kDebugMode) "value": "$value",
          },
        );
      }
    } catch (e) {
      Arcane.log(
        "Unable to retrieve value from secure storage",
        level: Level.error,
        metadata: {
          "key": key,
        },
      );
    }

    return value;
  }

  Future<bool> setValue(String key, String? value) async {
    if (Feature.secureStorageRepositoryLogs.enabled) {
      Arcane.log(
        "Setting value in secure storage",
        level: Level.debug,
        metadata: {
          "key": key,
          "value": "$value",
        },
      );
    }

    try {
      await _storage.write(key: key, value: value);

      if (Feature.secureStorageRepositoryLogs.enabled) {
        Arcane.log(
          "Successfully set value in secure storage",
          level: Level.debug,
          metadata: {
            "key": key,
            if (kDebugMode) "value": "$value",
          },
        );
      }
      return true;
    } catch (e) {
      Arcane.log(
        "Unable to set value in secure storage",
        level: Level.error,
        metadata: {
          "key": key,
          if (kDebugMode) "value": "$value",
        },
      );
      return false;
    }
  }
}

class DebugSecureStorageRepository implements SecureStorageRepository {
  @override
  FlutterSecureStorage get _storage => throw UnimplementedError();

  @override
  Future<bool> deleteAll() async {
    return true;
  }

  @override
  Future<String?> getValue(String key) async {
    return switch (key) {
      "install_id" => "install id",
      _ => throw Exception("Unhandled case in secure storage"),
    };
  }

  @override
  Future<bool> setValue(String key, String? value) async {
    return true;
  }
}
