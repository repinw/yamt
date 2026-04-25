// Health service stays class-based for provider overrides and test fakes.
// ignore_for_file: one_member_abstracts

import 'package:yamt/features/health/domain/diary_health_day_data.dart';

/// Defines diary health service.
abstract interface class DiaryHealthService {
  /// Load day data.
  Future<DiaryHealthDayData> loadDayData({
    required DateTime day,
    double? userHeightCm,
  });
}
