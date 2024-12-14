// lib/core/di/service_locator.dart

import 'package:get_it/get_it.dart';
import 'package:http/http.dart' as http;

final GetIt serviceLocator = GetIt.instance;

Future<void> setupServiceLocator() async {
  // Core Services
  serviceLocator.registerLazySingleton<http.Client>(
    () => http.Client(),
  );

  // Additional services will be registered here
}
