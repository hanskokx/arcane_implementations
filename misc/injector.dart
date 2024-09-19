import "package:arcane_framework/arcane_framework.dart";
import "package:dio/dio.dart";
import "package:flutter_secure_storage/flutter_secure_storage.dart";
import "package:get_it/get_it.dart";

abstract class AppInjector {
  static final GetIt getIt = GetIt.I;

  static void _registerApis() {
    getIt.registerSingleton<MyApi>(
      SetupApi(getIt<SecureStorageRepository>()),
    );
  }

  static void _registerHelpers() {
    getIt.registerSingleton<FlutterSecureStorage>(
      const FlutterSecureStorage(
        aOptions: AndroidOptions(
          encryptedSharedPreferences: true,
        ),
      ),
    );
    getIt.registerSingleton<SecureStorageRepository>(
      SecureStorageRepository(getIt<FlutterSecureStorage>()),
    );
    getIt.registerLazySingleton<AuthorizationInterceptor>(
      () => AuthorizationInterceptor(),
    );
    getIt.registerLazySingleton<Dio>(
      () => DioHelper.createDioInstance(getIt),
    );
  }

  static Future<void> init() async {
    Arcane.log(
      "Initializing injector...",
      level: Level.info,
    );

    await getIt.reset();
    _registerHelpers();
    _registerApis();
    await getIt.allReady();

    await IdService.I.init();

    Arcane.log(
      "Injector initialized.",
      level: Level.info,
    );
  }

  static void resetDio() {
    if (getIt.isRegistered<Dio>()) {
      getIt.unregister<Dio>();
    }

    getIt.registerLazySingleton<Dio>(
      () => DioHelper.createDioInstance(getIt),
    );
  }

  static Future<void> configureAsDebug() async {
    Arcane.log(
      "Unregistering production APIs and replacing with Debug versions",
      level: Level.fatal,
    );

    getIt.unregister<MyApi>();

    await getIt.allReady();

    getIt.registerSingleton<SecureStorageRepository>(
      DebugSecureStorageRepository(),
    );

    final SecureStorageRepository storage = getIt<SecureStorageRepository>();

    getIt.registerSingleton<MyApi>(DebugMyApi(storage));

    await getIt.allReady();
  }
}
