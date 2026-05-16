import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:yamt/features/health/data/diary_health_service.dart';
import 'package:yamt/features/health/data/diary_health_service_stub.dart'
    if (dart.library.io) 'package:yamt/features/health/data/diary_health_service_mobile.dart'
    as implementation;

part 'diary_health_service_provider.g.dart';

/// Diary health service.
@Riverpod(keepAlive: true)
DiaryHealthService diaryHealthService(Ref ref) {
  return implementation.createDiaryHealthService();
}
