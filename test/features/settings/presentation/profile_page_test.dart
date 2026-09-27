import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';
import 'package:yamt/core/l10n/app_localizations_delegates.dart';
import 'package:yamt/features/calories/domain/calorie_calculator_profile.dart';
import 'package:yamt/features/calories/domain/calorie_goal_settings.dart';
import 'package:yamt/features/health/domain/manual_health_weight_entry.dart';
import 'package:yamt/features/settings/presentation/profile_page.dart';
import 'package:yamt/features/settings/presentation/widgets/profile/profile_weight_card.dart';
import 'package:yamt/l10n/app_localizations.dart';

import '../../../helpers/profile_summary_source_overrides.dart';
import '../../calories/support/fake_calories_repositories.dart';

void main() {
  testWidgets('shows the current profile under a profile app bar', (
    tester,
  ) async {
    final repository = FakeCalorieSettingsRepository(
      initialSettings: CalorieGoalSettings.single(
        dailyKcalGoal: 2100,
        calculatorProfile: const CalorieCalculatorProfile.defaults(),
        effectiveDate: DateTime(2026, 9),
      ),
    );
    addTearDown(repository.dispose);

    await tester.pumpWidget(
      ProviderScope(
        overrides: profileSummarySourceOverrides(
          settingsRepository: repository,
          now: DateTime(2026, 9, 24, 10),
          displayName: 'Alex',
          weighIns: [
            ManualHealthWeightEntry(day: DateTime(2026, 9, 24), weightKg: 79.4),
          ],
        ),
        child: const MaterialApp(
          locale: Locale('de'),
          localizationsDelegates: appLocalizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          home: ProfilePage(),
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(
      find.descendant(of: find.byType(AppBar), matching: find.text('Profil')),
      findsOneWidget,
    );
    expect(find.text('Alex'), findsOneWidget);
    // Trend weight and last weigh-in are the same after one weigh-in.
    expect(find.text('79,4 kg'), findsNWidgets(2));
    expect(find.text('heute'), findsOneWidget);
    expect(find.text('80,0 kg'), findsNWidgets(2));
    expect(find.byKey(ProfileWeightCard.addWeightButtonKey), findsOneWidget);
    expect(find.text('180 cm'), findsOneWidget);
    expect(find.text('Gewicht halten'), findsOneWidget);
    await tester.scrollUntilVisible(find.text('2.100 kcal/Tag'), 200);
    expect(find.text('2.100 kcal/Tag'), findsOneWidget);
  });
}
