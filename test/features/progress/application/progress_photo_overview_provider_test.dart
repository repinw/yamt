import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:yamt/features/calories/domain/calorie_goal_settings.dart';
import 'package:yamt/features/health/domain/manual_health_weight_entry.dart';
import 'package:yamt/features/health/domain/progress_photo.dart';
import 'package:yamt/features/progress/application/progress_photo_overview_provider.dart';
import 'package:yamt/features/progress/domain/progress_period.dart';
import 'package:yamt/features/progress/domain/progress_photo_overview.dart';

import '../../../helpers/fake_progress_photo_repository.dart';
import '../../../helpers/progress_source_overrides.dart';
import '../../calories/support/fake_calories_repositories.dart';

ProgressPhoto _photo(String id, DateTime day, {double? weightKg}) =>
    ProgressPhoto(
      id: id,
      day: day,
      pose: ProgressPhotoPose.front,
      weightKg: weightKg,
    );

Future<ProgressPhotoOverview> _overview(
  ProgressScope scope, {
  List<ProgressPhoto> olderPhotos = const [],
  List<ManualHealthWeightEntry> extraWeighIns = const [],
  CalorieGoalSettings? goals,
}) async {
  final settings = FakeCalorieSettingsRepository(
    initialSettings: goals ?? progressSettings(),
  );
  addTearDown(settings.dispose);
  final calorieLog = FakeCalorieLogRepository();
  addTearDown(calorieLog.dispose);
  final photos = FakeProgressPhotoRepository(
    // Oldest first, as the repository returns them.
    photos: [
      ...olderPhotos,
      _photo('before', DateTime(2026, 9)),
      _photo('start', DateTime(2026, 9, 7)),
      _photo('typed', DateTime(2026, 9, 12), weightKg: 90),
    ],
  );
  addTearDown(photos.dispose);
  final container = ProviderContainer(
    overrides: progressSourceOverrides(
      settingsRepository: settings,
      calorieLog: calorieLog,
      photos: photos,
      extraWeighIns: extraWeighIns,
    ),
  );
  addTearDown(container.dispose);
  final subscription = container.listen(
    progressPhotoOverviewProvider(scope),
    (_, _) {},
  );
  addTearDown(subscription.close);
  return await container.read(progressPhotoOverviewProvider(scope).future);
}

void main() {
  test('the goal scope keeps the photos from the goal start on', () async {
    final overview = await _overview(ProgressScope.goal);

    expect(overview.photos.map((photo) => photo.id), ['start', 'typed']);
    expect(overview.goalStarts.single.day, DateTime(2026, 9, 7));
    expect(overview.groups.single.goal?.number, 1);
  });

  test('a past goal keeps the photos from its start to its last day', () async {
    final overview = await _overview(
      const ProgressPastGoalScope(1),
      goals: progressTwoGoalSettings(),
    );

    // The goal runs from 1 to 9 September.
    expect(overview.photos.map((photo) => photo.id), ['before', 'start']);
    expect(overview.groups.single.goal?.number, 1);
  });

  test('the all scope keeps every photo, also before the first goal', () async {
    final overview = await _overview(ProgressScope.all);

    expect(overview.photos.map((photo) => photo.id), [
      'before',
      'start',
      'typed',
    ]);
    expect(overview.groups.map((group) => group.goal?.number), [1, null]);
  });

  test('a typed weight wins over the trend of the day', () async {
    final overview = await _overview(ProgressScope.all);

    expect(overview.dayWeightsKg[DateTime(2026, 9, 12)], isNotNull);
    expect(overview.weightKg(overview.photos.last), 90);
    expect(overview.weightKg(overview.photos[1]), isNotNull);
  });

  test('a photo of years ago gets the weight of its day', () async {
    final longAgo = DateTime(2024, 3, 4);
    final overview = await _overview(
      ProgressScope.all,
      olderPhotos: [_photo('old', longAgo)],
      extraWeighIns: [ManualHealthWeightEntry(day: longAgo, weightKg: 101)],
    );

    expect(overview.dayWeightsKg[longAgo], isNotNull);
    expect(overview.weightKg(overview.photos.first), isNotNull);
  });
}
