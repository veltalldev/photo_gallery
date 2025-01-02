// lib/core/di/service_locator.dart

import 'package:flutter_cache_manager/flutter_cache_manager.dart';
import 'package:get_it/get_it.dart';
import 'package:http/http.dart' as http;
import 'package:photo_gallery/services/impl/cache_service.dart';

import '../../repositories/interfaces/i_photo_repository.dart';
import '../../repositories/impl/photo_repository.dart';
import '../../services/interfaces/i_photo_service.dart';
import '../../services/impl/photo_service.dart';
import '../../services/interfaces/i_cache_service.dart';
import '../../services/impl/photo_cache_manager.dart';

final GetIt serviceLocator = GetIt.instance;

Future<void> setupServiceLocator() async {
  // Core Services
  serviceLocator.registerLazySingleton<http.Client>(
    () => http.Client(),
  );

  // Cache Services
  serviceLocator.registerLazySingleton<ICacheService>(
    () => CacheService(cacheManager: DefaultCacheManager()),
  );

  serviceLocator.registerLazySingleton<PhotoCacheManager>(
    () => PhotoCacheManager(
      baseCache: serviceLocator<ICacheService>(),
    ),
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
