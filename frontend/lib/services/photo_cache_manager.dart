import 'package:flutter_cache_manager/flutter_cache_manager.dart';

class PhotoCacheManager extends CacheManager {
  static const key = 'photoCache';

  static final PhotoCacheManager _instance = PhotoCacheManager._();
  factory PhotoCacheManager() => _instance;

  PhotoCacheManager._()
      : super(
          Config(
            key,
            stalePeriod: const Duration(days: 7),
            maxNrOfCacheObjects: 500,
            repo: JsonCacheInfoRepository(databaseName: key),
            fileService: HttpFileService(),
          ),
        );
}
