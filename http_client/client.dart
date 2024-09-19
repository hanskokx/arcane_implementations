import "package:arcane_framework/arcane_framework.dart";
import "package:dio/dio.dart";
import "package:flutter/foundation.dart";
import "package:gql_dio_link/gql_dio_link.dart";
import "package:graphql/client.dart";

class AppHttpClient {
  static bool _isMocked = false;

  static final AppHttpClient _service = AppHttpClient._internal();

  factory AppHttpClient() {
    return _service;
  }

  AppHttpClient._internal();

  static late GraphQLClient _graphQlClient;
  static GraphQLClient get graphQlClient => _graphQlClient;

  static late GraphQLClient _webSocketClient;
  static GraphQLClient get webSocketClient => _webSocketClient;

  @visibleForTesting
  static void setMocked() => _isMocked = true;

  static Future<void> init(Dio dio, {String? url}) async {
    if (_isMocked) return;

    late final String? authToken;

    try {
      authToken = await Arcane.auth.accessToken;
    } catch (e) {
      return;
    }

    _webSocketClient = GraphQLClient(
      cache: GraphQLCache(),
      queryRequestTimeout: const Duration(seconds: 40),
      defaultPolicies: DefaultPolicies(
        query: Policies(
          fetch: FetchPolicy.networkOnly,
        ),
      ),
      link: WebSocketLink(
        "wss://$url",
        config: SocketClientConfig(
          autoReconnect: true,
          initialPayload: {
            "Authorization": "Bearer $authToken",
          },
        ),
        subProtocol: GraphQLProtocol.graphqlTransportWs,
      ),
    );

    _graphQlClient = GraphQLClient(
      cache: GraphQLCache(),
      queryRequestTimeout: const Duration(seconds: 40),
      defaultPolicies: DefaultPolicies(
        query: Policies(
          fetch: FetchPolicy.networkOnly,
        ),
      ),
      link: DioLink(
        "https://$url",
        client: dio,
      ),
    );
  }
}

extension QueryResultExtension on QueryResult {
  int get errorStatusCode {
    if (exception?.linkException != null &&
        exception!.linkException is HttpLinkServerException) {
      final HttpLinkServerException httpLinkException =
          exception!.linkException as HttpLinkServerException;
      return httpLinkException.response.statusCode;
    }
    return -1;
  }

  bool get failed {
    return !success;
  }

  bool get success {
    return !hasException && (data ?? const <dynamic, dynamic>{}).isNotEmpty;
  }
}
