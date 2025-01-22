import 'package:aad_oauth/aad_oauth.dart';
import 'package:aad_oauth/model/config.dart';
import 'package:arcane_framework/arcane_framework.dart';
import 'package:flutter/material.dart';

class MicrosoftEntraInterface implements ArcaneAuthInterface {
  MicrosoftEntraInterface._internal();
  static final ArcaneAuthInterface _instance = MicrosoftEntraInterface._internal();
  static ArcaneAuthInterface get I => _instance;

  static bool _mocked = false;

  AadOAuth? _oauth;

  @override
  Future<String?>? get refreshToken async {
    if (!await isSignedIn) return null;

    final result = await _oauth?.refreshToken();

    if (result == null) return null;

    return result.fold(
      (l) => null,
      (r) async => r.refreshToken,
    );
  }

  @override
  Future<String?> get accessToken async => _oauth?.getAccessToken() ?? Future.value(null);

  @override
  Future<bool> get isSignedIn async => _oauth?.hasCachedAccountInformation ?? Future.value(false);

  @override
  Future<void> init() async {
    if (_oauth != null) return;

    final String? tenant = AppEnv.valueOf(EnvVar.adSsoTenant);
    final String? clientId = AppEnv.valueOf(EnvVar.adSsoClientId);
    final String? scope = AppEnv.valueOf(EnvVar.adSsoScope);
    final String? redirectUri = AppEnv.valueOf(EnvVar.adSsoRedirectUri);

    if (tenant == null) throw const FormatException('Tenant must not be null.');
    if (clientId == null) throw const FormatException('Client ID must not be null.');
    if (scope == null) throw const FormatException('Scope must not be null.');
    if (redirectUri == null) throw const FormatException('Redirect URI must not be null.');

    final Config config = Config(
      tenant: tenant,
      clientId: clientId,
      scope: scope,
      redirectUri: redirectUri,
      // Should be a GlobalKey<NavigatorState>() in the app's router
      navigatorKey: navigatorKey,
    );

    _oauth = AadOAuth(config);
  }

  @override
  Future<Result<void, String>> login<T>({T? input, Future<void> Function()? onLoggedIn}) async {
    if (_oauth == null) await init();

    if (await isSignedIn) return Result.ok(null);

    final result = await _oauth!.login();

    return result.fold(
      (l) {
        print(l);
        return Result.error('Microsoft Authentication Failed!');
      },
      (r) async {
        if (onLoggedIn != null) await onLoggedIn();
        return Result.ok(null);
      },
    );
  }

  @override
  Future<Result<void, String>> logout() async {
    if (_oauth == null) await init();

    if (!await isSignedIn) return Result.error('Not signed in');

    await _oauth?.logout();

    return Result.ok(null);
  }
}
