import 'package:yamt/features/health/domain/diary_health_day_data.dart';

abstract interface class DiaryHealthService {
  Future<DiaryHealthDayData> loadDayData({required DateTime day});
}
