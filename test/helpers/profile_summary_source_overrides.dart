import 'package:flutter_riverpod/misc.dart';
import 'package:yamt/core/preferences/app_preferences.dart';
import 'package:yamt/core/provider/clock_provider.dart';
import 'package:yamt/features/auth/data/auth_service.dart';
import 'package:yamt/features/auth/domain/user_profile.dart';
import 'package:yamt/features/calories/data/calorie_settings_repository.dart';
import 'package:yamt/features/health/data/health_connection_service_provider.dart';
import 'package:yamt/features/health/data/health_weight_service_provider.dart';
import 'package:yamt/features/health/data/manual_health_weight_repository_provider.dart';
import 'package:yamt/features/health/domain/health_connection_models.dart';
import 'package:yamt/features/health/domain/manual_health_weight_entry.dart';

import '../features/calories/support/fake_calories_repositories.dart';
import 'memory_app_preferences.dart';

/// Backs the settings profile summary with fake data sources: calorie
/// settings, the user's name, and manual weigh-ins without Health access.
List<Override> profileSummarySourceOverrides({
  required CalorieSettingsRepository settingsRepository,
  required DateTime now,
  String? displayName,
  List<ManualHealthWeightEntry> weighIns = const [],
}) {
  return [
    appPreferencesProvider.overrideWithValue(MemoryAppPreferences()),
    calorieSettingsRepositoryProvider.overrideWithValue(settingsRepository),
    clockProvider.overrideWithValue(() => now),
    userProfileProvider.overrideWith(
      (ref) => Stream.value(UserProfile(uid: 'u1', displayName: displayName)),
    ),
    healthConnectionServiceProvider.overrideWith(
      (ref) => FakeHealthConnectionService(
        const HealthConnectionStatus.unsupported(),
      ),
    ),
    healthWeightServiceProvider.overrideWith(
      (ref) => FakeHealthWeightService(const []),
    ),
    manualHealthWeightRepositoryProvider.overrideWith(
      (ref) => FakeManualHealthWeightRepository([...weighIns]),
    ),
  ];
}
