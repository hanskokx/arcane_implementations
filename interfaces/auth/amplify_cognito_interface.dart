import "package:amplify_auth_cognito/amplify_auth_cognito.dart";
import "package:amplify_flutter/amplify_flutter.dart";
import "package:arcane_framework/arcane_framework.dart";
import "package:flutter/widgets.dart";

class AmplifyInterface implements ArcaneAuthInterface {
  AmplifyInterface._internal();

  static bool _mocked = false;

  static final ArcaneAuthInterface _instance = AmplifyInterface._internal();
  static ArcaneAuthInterface get I => _instance;

  AmplifyAuthCognito get _cognito =>
      Amplify.Auth.getPlugin(AmplifyAuthCognito.pluginKey);

  Future<CognitoAuthSession?> get _session async {
    try {
      return await _cognito.fetchAuthSession();
    } on AuthException catch (_) {
      return null;
    }
  }

  @override
  Future<bool> get isSignedIn =>
      _session.then((value) => value?.isSignedIn == true);

  @override
  Future<String?> get accessToken => isSignedIn.then(
        (loggedIn) => loggedIn
            ? _session.then(
                (value) => value?.userPoolTokensResult.value.accessToken.raw,
              )
            : null,
      );

  @override
  Future<String?> get refreshToken => isSignedIn.then(
        (loggedIn) => loggedIn
            ? _session.then(
                (value) => value?.userPoolTokensResult.value.refreshToken,
              )
            : null,
      );

  @override
  Future<Result<void, String>> logout() async {
    final result = await _cognito.signOut();

    if (result is CognitoFailedSignOut) {
      return Result.error(result.exception.message);
    }

    return Result.ok(null);
  }

  @override
  Future<Result<void, String>> login<T>({
    T? input,
    Future<void> Function()? onLoggedIn,
  }) =>
      throw UnimplementedError();

  @override
  Future<Result<void, String>> loginWithEmailAndPassword({
    required String email,
    required String password,
  }) async {
    final bool alreadyLoggedIn = await isSignedIn;

    if (alreadyLoggedIn) return Result.ok(null);

    try {
      final CognitoSignInResult result = await _cognito.signIn(
        username: email,
        password: password,
      );
      return await _handleSignInResult(result, email);
    } on AuthException catch (e) {
      return Result.error("Error signing in: ${e.message}");
    } catch (e) {
      return Result.error("Error signing in: $e");
    }
  }

  Future<Result<void, String>> _handleSignInResult(
    SignInResult result,
    String email,
  ) async {
    switch (result.nextStep.signInStep) {
      case AuthSignInStep.confirmSignInWithSmsMfaCode:
        final codeDeliveryDetails = result.nextStep.codeDeliveryDetails!;
        return Result.error(_handleCodeDelivery(codeDeliveryDetails));
      case AuthSignInStep.confirmSignInWithNewPassword:
        return Result.error("Enter a new password to continue signing in");
      case AuthSignInStep.confirmSignInWithCustomChallenge:
        final parameters = result.nextStep.additionalInfo;
        final prompt = parameters["prompt"]!;
        return Result.error(prompt);
      case AuthSignInStep.resetPassword:
        final resetResult = await _cognito.resetPassword(
          username: email,
        );
        return Result.error("Reset password result: $resetResult");
      case AuthSignInStep.confirmSignUp:
        // Resend the sign up code to the registered device.
        final resendResult = await _cognito.resendSignUpCode(
          username: email,
        );
        return Result.error(
          _handleCodeDelivery(resendResult.codeDeliveryDetails),
        );
      case AuthSignInStep.done:
        return Result.ok(null);
      default:
        Arcane.log(
          "Sign-in failed",
          level: Level.warning,
          metadata: {
            "result": result.toString(),
          },
        );
        return Result.error(
          "Unexpected sign-in result: ${result.nextStep.signInStep}",
        );
    }
  }

  String _handleCodeDelivery(AuthCodeDeliveryDetails codeDeliveryDetails) {
    // TODO(any): localize this
    return "A confirmation code has been sent to ${codeDeliveryDetails.destination}. "
        "Please check your ${codeDeliveryDetails.deliveryMedium.name} for the code.";
  }

  @override
  Future<Result<String, String>> resendVerificationCode(String email) async {
    try {
      final result = await _cognito.resendSignUpCode(
        username: email.toLowerCase(),
      );
      final codeDeliveryDetails = result.codeDeliveryDetails;
      final String returnValue = _handleCodeDelivery(codeDeliveryDetails);
      return Result.ok(returnValue);
    } on AuthException catch (e) {
      return Result.error("Error resending verification code: ${e.message}");
    }
  }

  @override
  Future<Result<SignUpStep, String>> signup({
    required String password,
    required String email,
  }) async {
    try {
      final String accountEmail = email.toLowerCase();
      final userAttributes = {
        AuthUserAttributeKey.email: accountEmail,
      };
      final SignUpResult result = await _cognito.signUp(
        username: accountEmail,
        password: password,
        options: SignUpOptions(
          userAttributes: userAttributes,
        ),
      );

      if (result.nextStep.signUpStep == AuthSignUpStep.confirmSignUp) {
        return Result.ok(SignUpStep.confirmSignUp);
      }

      return Result.ok(SignUpStep.done);
    } on AuthException catch (e) {
      return Result.error("Error signing up user: ${e.message}");
    }
  }

  @override
  Future<Result<bool, String>> confirmSignup({
    required String username,
    required String confirmationCode,
  }) async {
    try {
      final CognitoSignUpResult result = await _cognito.confirmSignUp(
        username: username.toLowerCase(),
        confirmationCode: confirmationCode,
      );

      return Result.ok(result.isSignUpComplete);
    } on AuthException catch (e) {
      return Result.error("Error confirming user: ${e.message}");
    }
  }

  @override
  Future<Result<bool, String>> resetPassword({
    required String email,
    String? newPassword,
    String? code,
  }) async {
    try {
      late ResetPasswordResult result;
      if (newPassword != null && code != null) {
        result = await _cognito.confirmResetPassword(
          username: email,
          newPassword: newPassword,
          confirmationCode: code,
        );
      }

      if (newPassword == null && code == null) {
        result = await _cognito.resetPassword(
          username: email,
        );
      }

      return Result.ok(result.isPasswordReset);
    } on AuthException catch (e) {
      return Result.error("Error resetting the password: ${e.message}");
    }
  }

  @override
  Future<void> init() async {
    if (_mocked) return;

    if (Amplify.isConfigured) return;

    final plugin = AmplifyAuthCognito();

    await Amplify.addPlugin(plugin);
    await Amplify.configure(_amplifyconfig);
  }

  @visibleForTesting
  static void setMocked() {
    _mocked = true;
  }

  static final String _amplifyconfig = '''
{
  "UserAgent": "aws-amplify-cli/2.0",
  "Version": "1.0",
  "auth": {
    "plugins": {
      "awsCognitoAuthPlugin": {
        "IdentityManager": {
          "Default": {}
        },
        "CredentialsProvider": {
          "CognitoIdentity": {
            "Default": {
              "PoolId": "${EnvVar.cognitoPoolId.value}",
              "Region": "${EnvVar.cognitoRegion.value}"
            }
          }
        },
        "CognitoUserPool": {
          "Default": {
            "PoolId": "${EnvVar.cognitoPoolId.value}",
            "AppClientId": "${EnvVar.cognitoClientId.value}",
            "Region": "${EnvVar.cognitoRegion.value}"
          }
        },
        "Auth": {
          "Default": {
            "authenticationFlowType": "USER_SRP_AUTH",
            "OAuth": {
              "WebDomain": "${EnvVar.authUrl.value}",
              "AppClientId": "${EnvVar.cognitoClientId.value}",
              "SignInRedirectURI": "${EnvVar.redirectUri.value}",
              "SignOutRedirectURI": "${EnvVar.redirectUri.value}",
              "Scopes": [
                "phone",
                "email",
                "openid",
                "profile",
                "aws.cognito.signin.user.admin"
              ]
            }
          }
        }
      }
    }
  }
}''';
}
