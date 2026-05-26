import 'package:yamt/core/preferences/app_preferences.dart';
import 'package:yamt/features/health/data/diary_health_service.dart';
import 'package:yamt/features/health/domain/diary_health_day_data.dart';

/// Create diary health service.
DiaryHealthService createDiaryHealthService({AppPreferences? preferences}) {
  return const _UnsupportedDiaryHealthService();
}

class _UnsupportedDiaryHealthService implements DiaryHealthService {
  const _UnsupportedDiaryHealthService();

  @override
  Future<DiaryHealthDayData> loadDayData({
    required DateTime day,
    double? userHeightCm,
  }) async {
    return const DiaryHealthDayData(totalSteps: 0, workouts: <Never>[]);
  }
}
