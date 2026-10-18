import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/misc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';
import 'package:yamt/core/l10n/app_localizations_delegates.dart';
import 'package:yamt/core/preferences/app_preferences.dart';
import 'package:yamt/core/provider/clock_provider.dart';
import 'package:yamt/features/auth/data/auth_service.dart';
import 'package:yamt/features/auth/domain/user_profile.dart';
import 'package:yamt/features/calories/data/calorie_log_repository.dart';
import 'package:yamt/features/calories/data/calorie_settings_repository.dart';
import 'package:yamt/features/health/data/health_connection_service_provider.dart';
import 'package:yamt/features/health/data/health_weight_sample_repository.dart';
import 'package:yamt/features/health/data/health_weight_service_provider.dart';
import 'package:yamt/features/health/data/manual_health_weight_repository_provider.dart';
import 'package:yamt/features/health/data/progress_photo_repository.dart';
import 'package:yamt/features/health/domain/health_connection_models.dart';
import 'package:yamt/features/health/domain/health_weight_sample.dart';
import 'package:yamt/features/health/domain/manual_health_weight_entry.dart';
import 'package:yamt/features/progress/domain/progress_weight_list.dart';
import 'package:yamt/features/progress/presentation/progress_weights_page.dart';
import 'package:yamt/features/progress/presentation/widgets/progress_weight_run_rows.dart';
import 'package:yamt/l10n/app_localizations.dart';

import '../features/calories/support/fake_calories_repositories.dart';
import 'fake_health_weight_sample_repository.dart';
import 'fake_progress_photo_repository.dart';
import 'memory_app_preferences.dart';
import 'progress_source_overrides.dart';

/// A manual weighing on the morning of the Fortschritt examples' today.
final progressManualWeighing = ManualHealthWeightEntry(
  day: DateTime(2026, 9, 24),
  weightKg: 80.7,
  recordedAt: DateTime(2026, 9, 24, 8),
  id: 'morning',
);

/// A weighing of another app the day before.
final progressScaleSample = HealthWeightSample(
  recordedAt: DateTime(2026, 9, 23, 7),
  weightKg: 81.3,
  sourcePackageName: 'com.scale',
);

/// A weighing that this app wrote, two days before.
final progressOwnSample = HealthWeightSample(
  recordedAt: DateTime(2026, 9, 22, 7),
  weightKg: 81.9,
  isFromThisApp: true,
);

/// The row of the weighing of [entry] or [sample] in the weight list.
ValueKey<String> progressWeighingRowKey({
  ManualHealthWeightEntry? entry,
  HealthWeightSample? sample,
}) {
  return ProgressWeighingRow.rowKey(
    ProgressWeighing(
      day: entry?.day ?? DateTime(sample!.recordedAt.year),
      at: entry?.recordedAt ?? sample?.recordedAt,
      weightKg: (entry?.weightKg ?? sample?.weightKg)!,
      source: ProgressWeighingSource.manual,
      entry: entry,
      sample: sample,
    ),
  );
}

/// The fakes behind a weight list: the repository layer only, so the real
/// controllers and providers run.
class ProgressWeighingFakes {
  /// Creates the fakes with [samples] in the cloud and the Health store of
  /// this device holding [onDevice], or [health] in its place.
  new({
    List<HealthWeightSample> samples = const [],
    List<HealthWeightSample> onDevice = const [],
    FakeHealthWeightService? health,
  }) : cloud = FakeHealthWeightSampleRepository(samples),
       health = health ?? FakeHealthWeightService(onDevice),
       manual = FakeManualHealthWeightRepository([
         for (var offset = 2; offset < 20; offset += 2)
           ManualHealthWeightEntry(
             day: DateTime(2026, 9, 24 - offset),
             weightKg: 82 + offset * 0.05,
           ),
         progressManualWeighing,
       ]),
       connection = FakeHealthConnectionService(
         const HealthConnectionStatus.unsupported(),
       ),
       settings = FakeCalorieSettingsRepository(
         initialSettings: progressSettings(),
       ),
       calorieLog = FakeCalorieLogRepository();

  /// The cloud copies of Health weights.
  final FakeHealthWeightSampleRepository cloud;

  /// The Health store of this device.
  final FakeHealthWeightService health;

  /// The manual weights.
  final FakeManualHealthWeightRepository manual;

  /// The Health connection.
  final FakeHealthConnectionService connection;

  /// The calorie settings.
  final FakeCalorieSettingsRepository settings;

  /// The calorie log.
  final FakeCalorieLogRepository calorieLog;

  /// The provider overrides of the fakes.
  List<Override> get overrides => [
    appPreferencesProvider.overrideWithValue(MemoryAppPreferences()),
    calorieSettingsRepositoryProvider.overrideWithValue(settings),
    clockProvider.overrideWithValue(() => progressNow),
    userProfileProvider.overrideWith(
      (ref) => Stream.value(const UserProfile(uid: 'u1')),
    ),
    calorieLogRepositoryProvider.overrideWithValue(calorieLog),
    progressPhotoRepositoryProvider.overrideWithValue(
      FakeProgressPhotoRepository(),
    ),
    manualHealthWeightRepositoryProvider.overrideWithValue(manual),
    healthWeightSampleRepositoryProvider.overrideWithValue(cloud),
    healthWeightServiceProvider.overrideWithValue(health),
    healthConnectionServiceProvider.overrideWithValue(connection),
  ];

  /// Releases the fakes.
  Future<void> dispose() async {
    await settings.dispose();
    await calorieLog.dispose();
    await cloud.dispose();
  }
}

/// Pumps the weight list over [fakes].
Future<void> pumpProgressWeights(
  WidgetTester tester,
  ProgressWeighingFakes fakes,
) async {
  addTearDown(fakes.dispose);
  tester.view.physicalSize = const Size(1080, 4000);
  addTearDown(tester.view.reset);
  await tester.pumpWidget(
    ProviderScope(
      overrides: fakes.overrides,
      child: const MaterialApp(
        locale: Locale('en'),
        localizationsDelegates: appLocalizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        home: ProgressWeightsPage(),
      ),
    ),
  );
  await tester.pumpAndSettle();
}
