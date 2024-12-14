// lib/core/di/service_locator.dart

import 'package:get_it/get_it.dart';
import 'package:http/http.dart' as http;

import '../../repositories/interfaces/i_photo_repository.dart';
import '../../repositories/impl/photo_repository.dart';
import '../../services/interfaces/i_photo_service.dart';
import '../../services/impl/photo_service.dart';
import '../../services/interfaces/i_cache_service.dart';
import '../../services/impl/cache_service.dart';

final GetIt serviceLocator = GetIt.instance;

Future<void> setupServiceLocator() async {
  // Core Services
  serviceLocator.registerLazySingleton<http.Client>(
    () => http.Client(),
  );

  // Cache Service
  serviceLocator.registerLazySingleton<ICacheService>(
    () => CacheService(),
  );

  // Repositories
  serviceLocator.registerLazySingleton<IPhotoRepository>(
    () => PhotoRepository(
      client: serviceLocator<http.Client>(),
      cacheService: serviceLocator<ICacheService>(),
    ),
  );

  // Business Services
  serviceLocator.registerLazySingleton<IPhotoService>(
    () => PhotoService(
      repository: serviceLocator<IPhotoRepository>(),
      cacheService: serviceLocator<ICacheService>(),
    ),
  );
}
