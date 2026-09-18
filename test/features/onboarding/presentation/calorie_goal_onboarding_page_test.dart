import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';
import 'package:yamt/core/l10n/app_localizations_delegates.dart';
import 'package:yamt/features/calories/data/calorie_settings_repository.dart';
import 'package:yamt/features/calories/domain/calorie_goal_settings.dart';
import 'package:yamt/features/onboarding/presentation/calorie_goal_onboarding_page.dart';
import 'package:yamt/features/onboarding/presentation/widgets/intro/'
    'calorie_intro_flow.dart';
import 'package:yamt/l10n/app_localizations.dart';

void _disableAnimations(WidgetTester tester) {
  tester.binding.platformDispatcher.accessibilityFeaturesTestValue =
      const FakeAccessibilityFeatures(disableAnimations: true);
  addTearDown(
    tester.binding.platformDispatcher.clearAccessibilityFeaturesTestValue,
  );
}

void main() {
  group('CalorieGoalOnboardingPage', () {
    testWidgets('shows loading indicator while settings have no value', (
      tester,
    ) async {
      final repository = _NeverEmittingCalorieSettingsRepository();
      addTearDown(repository.dispose);

      await _pumpPage(tester, repository);

      expect(find.byType(CircularProgressIndicator), findsOneWidget);
      expect(find.byType(CalorieIntroFlow), findsNothing);
    });

    testWidgets('renders intro flow after settings load', (tester) async {
      final repository = _StaticCalorieSettingsRepository(
        CalorieGoalSettings.single(
          dailyKcalGoal: 2100,
          calculatorProfile: null,
          effectiveDate: DateTime(2026, 5, 13, 8),
        ),
      );

      await _pumpPage(tester, repository);
      await tester.pump();

      expect(find.byType(CalorieIntroFlow), findsOneWidget);
      expect(find.text('Welcome to YAMT'), findsOneWidget);
    });
  });
}

Future<void> _pumpPage(
  WidgetTester tester,
  CalorieSettingsRepository repository,
) {
  _disableAnimations(tester);
  return tester.pumpWidget(
    ProviderScope(
      overrides: [
        calorieSettingsRepositoryProvider.overrideWithValue(repository),
      ],
      child: const MaterialApp(
        locale: Locale('en'),
        localizationsDelegates: appLocalizationsDelegates,
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
  const new(this.settings);

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
