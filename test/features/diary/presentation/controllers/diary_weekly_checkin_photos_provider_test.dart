import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:yamt/features/calories/application/calorie_weekly_checkin_demo_data.dart';
import 'package:yamt/features/calories/application/calorie_weekly_checkin_plan_provider.dart';
import 'package:yamt/features/calories/domain/macro_goal_settings.dart';
import 'package:yamt/features/diary/presentation/controllers/diary_weekly_checkin_photos_provider.dart';
import 'package:yamt/features/health/data/progress_photo_repository.dart';
import 'package:yamt/features/health/domain/progress_photo.dart';

import '../../../../helpers/fake_progress_photo_repository.dart';

void main() {
  final today = DateTime(2026, 4, 20);
  final plan = calorieWeeklyCheckInDemoPlan(
    today: today,
    macroSettings: const MacroGoalSettings(),
    profile: null,
  );

  test('shows the typed weight, else the weight of the day', () async {
    final start = plan.progress!.startDate;
    final photos = FakeProgressPhotoRepository(
      photos: [
        ProgressPhoto(
          id: 'old',
          day: start.subtract(const Duration(days: 3)),
          pose: ProgressPhotoPose.front,
        ),
        ProgressPhoto(id: 'first', day: start, pose: ProgressPhotoPose.front),
        ProgressPhoto(
          id: 'today',
          day: today,
          pose: ProgressPhotoPose.front,
          weightKg: 70.5,
        ),
        ProgressPhoto(id: 'side', day: today, pose: ProgressPhotoPose.side),
      ],
    );
    addTearDown(photos.dispose);
    final container = ProviderContainer(
      overrides: [
        progressPhotoRepositoryProvider.overrideWithValue(photos),
        calorieWeeklyCheckInPlanProvider.overrideWith((ref) async => plan),
      ],
    );
    addTearDown(container.dispose);

    final provider = diaryWeeklyCheckInPhotosProvider(
      ProgressPhotoPose.front,
      today,
      windowStart: null,
      preview: false,
    );
    final subscription = container.listen(provider, (_, _) {});
    addTearDown(subscription.close);
    final result = await container.read(provider.future);

    // The photo before the goal start does not count.
    expect(result.first?.photo.id, 'first');
    expect(result.first?.weightKg, plan.progress!.weightKgOn(start));
    expect(result.first?.weightKg, isNotNull);
    expect(result.middle, isNull);
    expect(result.today?.photo.id, 'today');
    expect(result.today?.weightKg, 70.5);
  });
}
