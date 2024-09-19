import "package:flutter/foundation.dart";
import "package:flutter_dotenv/flutter_dotenv.dart";

class AppEnv {
  /// Fetches the environment variable value for the given [EnvVar]. If the
  /// value is not set, defaults to an empty string.
  static String valueOf(EnvVar val) {
    return dotenv.maybeGet(val.key) ?? "";
  }

  /// Returns [true] if all of the [EnvVar] variables are set.
  static bool get hasEnv =>
      dotenv.isEveryDefined(EnvVar.values.map((e) => e.key).toList());

  static Future<void> init() async {
    await dotenv.load();
  }

  static const FlutterMode flutterMode = kDebugMode
      ? FlutterMode.debug
      : kReleaseMode
          ? FlutterMode.release
          : kProfileMode
              ? FlutterMode.profile
              : FlutterMode.unknown;
}

enum FlutterMode {
  debug,
  profile,
  release,
  unknown,
}

extension EnvVarValue on EnvVar {
  /// The value of the [EnvVar] as a string. If the environment variable is not
  /// set, returns an empty string.
  String get value => AppEnv.valueOf(this);
}

enum EnvVar {
  /// The environment to use for the API calls. Returns either [dev] or [prod].
  ///
  /// Example `.env` configuration:
  /// ```
  /// API_ENVIRONMENT="dev"
  /// ```
  apiEnvironment("API_ENVIRONMENT"),
  ;

  /// The environment variable to use when retrieving the value of this [EnvVar].
  final String key;

  const EnvVar(this.key);
}
