import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:yamt/core/preferences/app_preferences.dart';
import 'package:yamt/features/calories/provider/'
    'calorie_summary_view_mode_controller.dart';

import '../../../helpers/memory_app_preferences.dart';

void main() {
  test('summary view mode defaults to balance', () {
    final container = ProviderContainer(
      overrides: [
        appPreferencesProvider.overrideWithValue(MemoryAppPreferences()),
      ],
    );
    addTearDown(container.dispose);

    expect(
      container.read(calorieSummaryViewModeControllerProvider),
      CalorieSummaryViewMode.balance,
    );
  });

  test('summary view mode restores a stored local preference', () {
    final preferences = MemoryAppPreferences(
      initialStrings: <String, String>{
        'calories_summary_view_mode': CalorieSummaryViewMode.classic.name,
      },
    );
    final container = ProviderContainer(
      overrides: [appPreferencesProvider.overrideWithValue(preferences)],
    );
    addTearDown(container.dispose);

    expect(
      container.read(calorieSummaryViewModeControllerProvider),
      CalorieSummaryViewMode.classic,
    );
  });

  test('summary view mode can be updated and persisted', () async {
    final preferences = MemoryAppPreferences();
    final container = ProviderContainer(
      overrides: [appPreferencesProvider.overrideWithValue(preferences)],
    );
    addTearDown(container.dispose);

    await container
        .read(calorieSummaryViewModeControllerProvider.notifier)
        .setMode(CalorieSummaryViewMode.classic);

    expect(
      container.read(calorieSummaryViewModeControllerProvider),
      CalorieSummaryViewMode.classic,
    );
    expect(
      await preferences.getString('calories_summary_view_mode'),
      CalorieSummaryViewMode.classic.name,
    );
  });
}
