import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';
import 'package:yamt/core/l10n/app_localizations_delegates.dart';
import 'package:yamt/features/onboarding/presentation/'
    'calorie_goal_onboarding_keys.dart';
import 'package:yamt/features/onboarding/presentation/widgets/intro/fields/'
    'intro_birth_date_card.dart';
import 'package:yamt/l10n/app_localizations.dart';

final _today = DateTime(2026, 9, 17);

/// Drag distance that moves a wheel by one item.
const _oneItem = 34.0;

Future<List<DateTime>> _pumpCard(
  WidgetTester tester, {
  DateTime? birthDate,
  String? errorText,
}) async {
  final emitted = <DateTime>[];
  await tester.pumpWidget(
    MaterialApp(
      locale: const Locale('en'),
      localizationsDelegates: appLocalizationsDelegates,
      supportedLocales: AppLocalizations.supportedLocales,
      home: Scaffold(
        body: IntroBirthDateCard(
          birthDate: birthDate,
          today: _today,
          errorText: errorText,
          onChanged: emitted.add,
        ),
      ),
    ),
  );
  await tester.pumpAndSettle();
  return emitted;
}

Future<void> _scrollWheel(
  WidgetTester tester,
  Key wheelKey, {
  required double by,
}) async {
  final wheel = find.byKey(wheelKey);
  await tester.ensureVisible(wheel);
  await tester.drag(wheel, Offset(0, by));
  await tester.pumpAndSettle();
}

void main() {
  testWidgets('shows a placeholder while no birthday is picked', (
    tester,
  ) async {
    await _pumpCard(tester);

    expect(find.text('--'), findsOneWidget);
  });

  testWidgets('shows the date and the derived age once picked', (tester) async {
    await _pumpCard(tester, birthDate: DateTime(1996, 1, 5));

    expect(find.text('1/5/1996 (30 years)'), findsOneWidget);
  });

  testWidgets('emits a complete date on the first dial touch', (tester) async {
    final emitted = await _pumpCard(tester);

    await _scrollWheel(
      tester,
      CalorieGoalOnboardingKeys.introBirthDayWheel,
      by: -_oneItem,
    );

    expect(emitted.last, DateTime(1996, 9, 18));
  });

  testWidgets('clamps the day to the days of the selected month', (
    tester,
  ) async {
    final emitted = await _pumpCard(tester, birthDate: DateTime(1996, 1, 31));

    await _scrollWheel(
      tester,
      CalorieGoalOnboardingKeys.introBirthMonthWheel,
      by: -_oneItem,
    );

    expect(emitted.last, DateTime(1996, 2, 29));
  });

  testWidgets('never emits a birthday younger than the minimum age', (
    tester,
  ) async {
    final emitted = await _pumpCard(tester, birthDate: DateTime(2010, 9, 17));

    await _scrollWheel(
      tester,
      CalorieGoalOnboardingKeys.introBirthDayWheel,
      by: -_oneItem,
    );

    expect(emitted.last, DateTime(2010, 9, 17));
  });

  testWidgets('shows the validation message', (tester) async {
    await _pumpCard(tester, errorText: 'Please pick your birthday.');

    expect(find.text('Please pick your birthday.'), findsOneWidget);
  });
}
