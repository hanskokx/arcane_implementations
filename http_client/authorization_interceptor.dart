import "dart:developer";

import "package:arcane_framework/arcane_framework.dart";
import "package:arcane_helper_utils/arcane_helper_utils.dart";
import "package:dio/dio.dart";

class AuthorizationInterceptor extends Interceptor {
  AuthorizationInterceptor();

  @override
  Future<void> onRequest(
    RequestOptions options,
    RequestInterceptorHandler handler,
  ) async {
    if (options.path == EnvVar.accessTokenUrl.value) {
      return super.onRequest(options, handler);
    }

    final bool isSignedIn = Arcane.auth.isSignedIn.value;
    String? accessToken;

    if (isSignedIn) accessToken = await Arcane.auth.accessToken;

    // Gather IDs for each request so we can track each HTTP request by session,
    // install, and per-request. These IDs can be used to correlate requests
    // between the front-end and backend in the logs.
    final String requestId = IdService.I.newId;
    final String? installId = IdService.I.installId;
    final String? sessionId = IdService.I.sessionId.value;

    // Logs the auth token to the debug console. Useful for debugging requests
    // using third-party tools where you need to authenticate. Only works if the
    // auth token isn't null and [Feature.debugPrintAuthToken] is enabled.
    if (accessToken != null && Feature.debugPrintAuthToken.enabled) {
      log("Token expires at ${accessToken.jwtExpiryTime()!.toIso8601String()}\n\n$accessToken");
    }

    // Assembles a Map of metadata that we're going to add to each HTTP request
    // so we can log out all the information in the debug console. We also
    // store all of the IDs we've collected into a Map for future use.
    final Map<String, String> metadata = {
      "request_id": requestId,
      if (installId.isNotNullOrEmpty) "install_id": "$installId",
      if (sessionId.isNotNullOrEmpty) "session_id": "$sessionId",
    };

    // Attempts to map the "query" parameter in a GraphQL request to a String
    // so that we can log it out in the debug console.
    try {
      final Map<String, dynamic> query = options.data as Map<String, dynamic>;

      for (final MapEntry<String, dynamic> entry in query.entries) {
        if (entry.key == "query") {
          final String queryString = entry.value.toString();
          final int queryStringOriginalLength = queryString.length;
          const int trimQueryStringAtLength = 64;
          final int trimToLength =
              queryStringOriginalLength > trimQueryStringAtLength
                  ? trimQueryStringAtLength
                  : queryStringOriginalLength;
          final String finalString =
              "${queryString.substring(0, trimToLength)}${trimToLength < queryStringOriginalLength ? "[...]" : ""}";
          metadata.addAll({entry.key: finalString});
        }
      }
    } catch (e) {
      log(e.toString());
    }

    // Removes the extra query string from the headers so we're not sending it
    // to the server along with our request.
    metadata.removeWhere((key, value) => key == "query");

    // Tries to add the authentication token to the header metadata that we're
    // going to add to the request.
    if (accessToken.isNotNullOrEmpty) {
      metadata.addAll({"Authorization": "Bearer $accessToken"});
    }

    // Adds all the collected metadata (auth token, request ID, etc.) to the
    // request headers.
    options.headers.addAll(metadata);

    // Logs the HTTP request so we can see the request ID and truncated query
    // string (if available).
    Arcane.log(
      "Making HTTP Request ${options.path}",
      level: Level.info,
      metadata: metadata,
    );

    return super.onRequest(options, handler);
  }
}
