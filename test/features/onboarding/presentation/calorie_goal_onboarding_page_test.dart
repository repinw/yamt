import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:yamt/features/calories/data/calorie_settings_repository.dart';
import 'package:yamt/features/calories/domain/calorie_goal_settings.dart';
import 'package:yamt/features/onboarding/presentation/calorie_goal_onboarding_page.dart';
import 'package:yamt/features/onboarding/presentation/widgets/onboarding/'
    'calorie_onboarding_wizard.dart';
import 'package:yamt/l10n/app_localizations.dart';

void main() {
  group('CalorieGoalOnboardingPage', () {
    testWidgets('shows loading indicator while settings have no value', (
      tester,
    ) async {
      final repository = _NeverEmittingCalorieSettingsRepository();
      addTearDown(repository.dispose);

      await _pumpPage(tester, repository);

      expect(find.byType(CircularProgressIndicator), findsOneWidget);
      expect(find.byType(CalorieOnboardingWizard), findsNothing);
    });

    testWidgets('renders wizard after settings load', (tester) async {
      final repository = _StaticCalorieSettingsRepository(
        CalorieGoalSettings.single(
          dailyKcalGoal: 2100,
          calculatorProfile: null,
          effectiveDate: DateTime(2026, 5, 13, 8),
        ),
      );

      await _pumpPage(tester, repository);
      await tester.pump();

      expect(find.byType(CalorieOnboardingWizard), findsOneWidget);
      expect(find.text('Glad you are here!'), findsOneWidget);
    });
  });
}

Future<void> _pumpPage(
  WidgetTester tester,
  CalorieSettingsRepository repository,
) {
  return tester.pumpWidget(
    ProviderScope(
      overrides: [
        calorieSettingsRepositoryProvider.overrideWithValue(repository),
      ],
      child: const MaterialApp(
        locale: Locale('en'),
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        home: CalorieGoalOnboardingPage(),
      ),
    ),
  );
}

class _NeverEmittingCalorieSettingsRepository
    implements CalorieSettingsRepository {
  final _controller = StreamController<CalorieGoalSettings>();

  @override
  Stream<CalorieGoalSettings> watchSettings() {
    return _controller.stream;
  }

  @override
  Future<CalorieGoalSettings> readSettings() async {
    return const CalorieGoalSettings.empty();
  }

  @override
  Future<bool> saveSettings(CalorieGoalSettings settings) async => true;

  @override
  Future<bool> setDailyGoal(double dailyKcalGoal) async => true;

  @override
  Future<bool> clearDailyGoal() async => true;

  Future<void> dispose() {
    return _controller.close();
  }
}

class _StaticCalorieSettingsRepository implements CalorieSettingsRepository {
  const _StaticCalorieSettingsRepository(this.settings);

  final CalorieGoalSettings settings;

  @override
  Stream<CalorieGoalSettings> watchSettings() {
    return Stream<CalorieGoalSettings>.value(settings);
  }

  @override
  Future<CalorieGoalSettings> readSettings() async => settings;

  @override
  Future<bool> saveSettings(CalorieGoalSettings settings) async => true;

  @override
  Future<bool> setDailyGoal(double dailyKcalGoal) async => true;

  @override
  Future<bool> clearDailyGoal() async => true;
}
