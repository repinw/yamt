import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:yamt/features/calories/data/calorie_settings_repository.dart';
import 'package:yamt/features/calories/domain/calorie_goal_settings.dart';
import 'package:yamt/features/calories/presentation/burn_week_mock_page.dart';
import 'package:yamt/features/calories/presentation/widgets/calories_page_keys.dart';
import 'package:yamt/l10n/app_localizations.dart';

import '../support/fake_calories_repositories.dart';

Widget _buildHarness({
  required FakeCalorieSettingsRepository settingsRepository,
}) {
  final container = ProviderContainer(
    overrides: [
      calorieSettingsRepositoryProvider.overrideWithValue(settingsRepository),
    ],
  );
  addTearDown(container.dispose);
  addTearDown(settingsRepository.dispose);

  return UncontrolledProviderScope(
    container: container,
    child: MaterialApp(
      locale: const Locale('en'),
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      supportedLocales: AppLocalizations.supportedLocales,
      home: BurnWeekMockPage(
        referenceNow: DateTime(2026, 4, 21, 12),
      ),
    ),
  );
}

void main() {
  testWidgets('renders mock page and opens details dialog', (tester) async {
    final settingsRepository = FakeCalorieSettingsRepository(
      initialSettings: CalorieGoalSettings.single(
        dailyKcalGoal: 2200,
        calculatorProfile: null,
        effectiveDate: DateTime(2026, 4, 20),
      ),
    );

    await tester.pumpWidget(
      _buildHarness(settingsRepository: settingsRepository),
    );
    await tester.pump();

    expect(find.text('Burn Week'), findsOneWidget);
    expect(find.byKey(CaloriesPageKeys.burnWeekMockBar), findsOneWidget);
    expect(find.text('EATEN'), findsOneWidget);
    expect(find.text('TODAY LEFT'), findsOneWidget);

    await tester.tap(find.byTooltip('Show Burn Week details'));
    await tester.pumpAndSettle();

    expect(find.text('Burn Week details'), findsOneWidget);
    expect(find.byKey(CaloriesPageKeys.burnWeekMockInfoCard), findsOneWidget);
  });
}
