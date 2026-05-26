import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:yamt/core/preferences/app_preferences.dart';
import 'package:yamt/features/health/data/diary_health_service.dart';
import 'package:yamt/features/health/data/diary_health_service_mobile.dart';
import 'package:yamt/features/health/data/diary_health_service_provider.dart';
import 'package:yamt/features/health/data/diary_health_service_stub.dart'
    as stub;

import '../../../helpers/memory_app_preferences.dart';

void main() {
  test('provider creates mobile service with app preferences', () {
    final container = ProviderContainer(
      overrides: [
        appPreferencesProvider.overrideWithValue(MemoryAppPreferences()),
      ],
    );
    addTearDown(container.dispose);

    final service = container.read(diaryHealthServiceProvider);

    expect(service, isA<MobileDiaryHealthService>());
    expect(service, isA<DiaryHealthActivityTrendService>());
  });

  test('stub service returns empty unsupported data', () async {
    final service = stub.createDiaryHealthService();

    final data = await service.loadDayData(day: DateTime(2026, 4, 27));

    expect(data.totalSteps, 0);
    expect(data.workouts, isEmpty);
  });
}
