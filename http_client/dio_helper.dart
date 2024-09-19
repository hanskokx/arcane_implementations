import "package:arcane_framework/arcane_framework.dart";
import "package:dio/dio.dart";
import "package:dio_smart_retry/dio_smart_retry.dart";
import "package:get_it/get_it.dart";
import "package:native_dio_adapter/native_dio_adapter.dart";
import "package:pretty_dio_logger/pretty_dio_logger.dart";

import "authorization_interceptor.dart";

abstract class DioHelper {
  DioHelper._();

  static Dio createDioInstance(GetIt container) {
    final Dio dio = Dio(
      BaseOptions(
        baseUrl: "https://${EnvVar.graphQlUrl.value}",
        connectTimeout: const Duration(seconds: 10),
        sendTimeout: const Duration(seconds: 30),
        receiveTimeout: const Duration(seconds: 40),
        followRedirects: false,
      ),
    );

    dio.interceptors
      ..add(container.get<AuthorizationInterceptor>())
      ..add(dioLogger)
      ..add(smartRetry(dio));

    dio.httpClientAdapter = NativeAdapter();

    return dio;
  }

  static Interceptor smartRetry(Dio dio) => RetryInterceptor(
        dio: dio,
        logPrint: Arcane.log,
        retries: 3,
        retryDelays: const [
          Duration(seconds: 1),
          Duration(seconds: 2),
          Duration(seconds: 3),
        ],
      );

  static PrettyDioLogger get dioLogger => PrettyDioLogger(
        requestHeader: true,
        requestBody: true,
        responseBody: true,
        responseHeader: false,
        error: true,
        compact: true,
        maxWidth: 90,
        enabled: Feature.httpLogging.enabled,
        filter: (options, args) {
          if (options.path.contains("/graphql")) {
            return true;
          }

          // don't print responses with unit8 list data
          return !args.isResponse || !args.hasUint8ListData;
        },
      );
}
