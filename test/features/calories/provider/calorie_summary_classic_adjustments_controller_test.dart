import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:yamt/core/preferences/app_preferences.dart';
import 'package:yamt/features/calories/provider/'
    'calorie_summary_classic_adjustments_controller.dart';

import '../../../helpers/memory_app_preferences.dart';

void main() {
  test('classic summary adjustments use the expected defaults', () {
    final container = ProviderContainer(
      overrides: [
        appPreferencesProvider.overrideWithValue(MemoryAppPreferences()),
      ],
    );
    addTearDown(container.dispose);

    expect(
      container.read(calorieSummaryClassicAdjustmentsControllerProvider),
      isA<CalorieSummaryClassicAdjustments>()
          .having(
            (value) => value.includeActivityDelta,
            'includeActivityDelta',
            isTrue,
          )
          .having(
            (value) => value.includeCarryover,
            'includeCarryover',
            isFalse,
          ),
    );
  });

  test('classic summary adjustments restore stored preferences', () {
    final preferences = MemoryAppPreferences(
      initialStrings: <String, String>{
        'calories_summary_classic_include_activity_delta': 'false',
        'calories_summary_classic_include_carryover': 'true',
      },
    );
    final container = ProviderContainer(
      overrides: [appPreferencesProvider.overrideWithValue(preferences)],
    );
    addTearDown(container.dispose);

    expect(
      container.read(calorieSummaryClassicAdjustmentsControllerProvider),
      isA<CalorieSummaryClassicAdjustments>()
          .having(
            (value) => value.includeActivityDelta,
            'includeActivityDelta',
            isFalse,
          )
          .having(
            (value) => value.includeCarryover,
            'includeCarryover',
            isTrue,
          ),
    );
  });

  test('classic summary adjustments can be updated and persisted', () async {
    final preferences = MemoryAppPreferences();
    final container = ProviderContainer(
      overrides: [appPreferencesProvider.overrideWithValue(preferences)],
    );
    addTearDown(container.dispose);

    final notifier = container.read(
      calorieSummaryClassicAdjustmentsControllerProvider.notifier,
    );

    await notifier.setIncludeActivityDelta(value: false);
    await notifier.setIncludeCarryover(value: true);

    expect(
      container.read(calorieSummaryClassicAdjustmentsControllerProvider),
      isA<CalorieSummaryClassicAdjustments>()
          .having(
            (value) => value.includeActivityDelta,
            'includeActivityDelta',
            isFalse,
          )
          .having(
            (value) => value.includeCarryover,
            'includeCarryover',
            isTrue,
          ),
    );
    expect(
      await preferences.getString(
        'calories_summary_classic_include_activity_delta',
      ),
      'false',
    );
    expect(
      await preferences.getString('calories_summary_classic_include_carryover'),
      'true',
    );
  });
}
