import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:riverpod/src/framework.dart' show Override;
import 'package:yamt/core/preferences/app_preferences.dart';
import 'package:yamt/features/activity/application/diary_activity_weight_data_provider.dart';
import 'package:yamt/features/activity/application/diary_weight_actions.dart';
import 'package:yamt/features/activity/domain/diary_activity_weight_models.dart';
import 'package:yamt/features/activity/presentation/widgets/activity_weight_section/diary_activity_weight_section.dart';
import 'package:yamt/features/activity/presentation/widgets/weight_card/diary_weight_details_card.dart';
import 'package:yamt/features/activity/presentation/widgets/weight_card/diary_weight_dialog_keys.dart';
import 'package:yamt/features/auth/data/auth_service.dart';
import 'package:yamt/features/health/domain/health_weight_sample.dart';
import 'package:yamt/l10n/app_localizations.dart';

import '../../../../helpers/memory_app_preferences.dart';

void main() {
  final selectedDay = DateTime(2026, 4, 27);

  testWidgets('shows weekly bar left of weight without steps or activity', (
    tester,
  ) async {
    await _pumpWeightSection(
      tester,
      selectedDay: selectedDay,
      header: const Text('Wochenleiste'),
      data: _weightData(selectedDay, hasSavedWeight: true),
    );

    final l10n = _l10n(tester);
    expect(find.text('Wochenleiste'), findsOneWidget);
    expect(find.text(l10n.diaryWeightTitle.toUpperCase()), findsOneWidget);
    expect(find.text(l10n.diaryStepsTitle.toUpperCase()), findsNothing);
    expect(find.text(l10n.diaryActivityTitle.toUpperCase()), findsNothing);
    expect(find.textContaining('78,4 kg', findRichText: true), findsOneWidget);

    final weekCenter = tester.getCenter(find.text('Wochenleiste'));
    final weightCenter = tester.getCenter(
      find.text(l10n.diaryWeightTitle.toUpperCase()),
    );
    expect(weekCenter.dx, lessThan(weightCenter.dx));
  });

  testWidgets('expands weight details', (tester) async {
    await _pumpWeightSection(
      tester,
      selectedDay: selectedDay,
      header: const Text('Wochenleiste'),
      data: _weightData(selectedDay, hasSavedWeight: true),
      includeWeightActions: true,
    );

    final l10n = _l10n(tester);
    await tester.tap(find.text(l10n.diaryWeightTitle.toUpperCase()));
    await tester.pumpAndSettle();

    expect(find.byType(DiaryWeightDetailsCard), findsOneWidget);
    expect(find.text(l10n.diaryWeightAddAction), findsOneWidget);
  });

  testWidgets('opens weight dialog when the selected day has no entry', (
    tester,
  ) async {
    await _pumpWeightSection(
      tester,
      selectedDay: selectedDay,
      header: const Text('Wochenleiste'),
      data: _weightData(selectedDay, hasSavedWeight: false),
      includeWeightActions: true,
    );

    final l10n = _l10n(tester);
    await tester.tap(find.text(l10n.diaryWeightTitle.toUpperCase()));
    await tester.pumpAndSettle();

    expect(find.byKey(DiaryWeightDialogKeys.weightDialogField), findsOneWidget);
    expect(find.byType(DiaryWeightDetailsCard), findsNothing);
  });
}

Future<void> _pumpWeightSection(
  WidgetTester tester, {
  required DateTime selectedDay,
  required Widget header,
  required DiaryActivityWeightData data,
  bool includeWeightActions = false,
}) async {
  final overrides = <Override>[
    appPreferencesProvider.overrideWithValue(MemoryAppPreferences()),
    authStateChangesProvider.overrideWith((ref) => const Stream.empty()),
    diaryActivityWeightDataProvider(
      selectedDay,
    ).overrideWith((ref) async => data),
    if (includeWeightActions)
      diaryWeightActionsProvider.overrideWith(
        (ref) => DiaryWeightActions(
          saveManualWeight: ({required day, required weightKg}) async => true,
          deleteManualWeight: (day) async => true,
          deleteHealthWeightSample: (sample) async => true,
          refreshDependents: ({required selectedDay, day}) async {},
        ),
      ),
  ];

  await tester.pumpWidget(
    ProviderScope(
      overrides: overrides,
      child: MaterialApp(
        locale: const Locale('de'),
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        home: Scaffold(
          body: SingleChildScrollView(
            padding: const EdgeInsets.all(16),
            child: DiaryActivityWeightSection(
              selectedDay: selectedDay,
              header: header,
            ),
          ),
        ),
      ),
    ),
  );
  await tester.pump();
  await tester.pump(const Duration(milliseconds: 800));
  await tester.pumpAndSettle();
}

DiaryActivityWeightData _weightData(
  DateTime selectedDay, {
  required bool hasSavedWeight,
}) {
  final days = List<DiaryWeightDayData>.generate(7, (index) {
    final day = selectedDay.subtract(Duration(days: 6 - index));
    final isSelectedDay = index == 6;
    final weight = isSelectedDay && hasSavedWeight ? 78.4 : null;
    final sample = weight == null
        ? null
        : HealthWeightSample(
            recordedAt: day.add(const Duration(hours: 8)),
            weightKg: weight,
            uuid: 'sample-$index',
            sourcePackageName: 'de.yamt.app',
            isFromThisApp: true,
          );
    return DiaryWeightDayData(
      day: day,
      weightKg: weight,
      hasManualWeight: false,
      hasAppOwnedHealthWeight: sample != null,
      healthSample: sample,
    );
  });

  return DiaryActivityWeightData(
    profileWeightKg: 78.4,
    selectedWeightKg: 78.4,
    hasSelectedDayWeight: hasSavedWeight,
    weightTrend: days.map((day) => day.weightKg).toList(growable: false),
    weightDays: days,
  );
}

AppLocalizations _l10n(WidgetTester tester) {
  return AppLocalizations.of(tester.element(find.byType(Scaffold)))!;
}
