// Acceptance tests of criterion W1 (#864): the weight dialog that the diary's
// weight tile opens prefills the weight in the number format of the app's
// language and saves what the field shows.
import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:yamt/features/activity/presentation/widgets/weight_card/diary_weight_dialog_keys.dart';
import 'package:yamt/features/diary/domain/diary_dashboard_tiles.dart';
import 'package:yamt/features/diary/presentation/widgets/diary_dashboard/diary_dashboard_keys.dart';
import 'package:yamt/features/health/domain/manual_health_weight_entry.dart';

import 'acceptance_harness.dart';

void main() {
  final now = DateTime(2026, 6, 17, 12);

  /// Opens the weight dialog from the weight tile; the account's newest
  /// weighing is [weightKg].
  Future<DiaryAcceptanceHarness> openDialog(
    WidgetTester tester, {
    required double weightKg,
    required Locale locale,
  }) async {
    final harness = DiaryAcceptanceHarness(now: now);
    harness.weights.entries.add(
      ManualHealthWeightEntry(
        day: DateTime(2026, 6, 10),
        recordedAt: DateTime(2026, 6, 10, 8),
        weightKg: weightKg,
        id: 'w-1',
      ),
    );
    await harness.pumpDiary(tester, locale: locale);
    await tester.tap(find.byKey(DiaryDashboardKeys.tile(DiaryTileIds.weight)));
    await settle(tester);
    return harness;
  }

  String fieldText(WidgetTester tester) => tester
      .widget<EditableText>(
        find.descendant(
          of: find.byKey(DiaryWeightDialogKeys.weightDialogField),
          matching: find.byType(EditableText),
        ),
      )
      .controller
      .text;

  Future<void> save(WidgetTester tester) async {
    await tester.tap(find.byKey(DiaryWeightDialogKeys.weightDialogSaveButton));
    await settle(tester);
  }

  /// The kg of the one weighing that the save added, wherever it went.
  double savedKg(DiaryAcceptanceHarness harness) {
    final saved = [
      ...harness.healthWeight.savedKg,
      for (final entry in harness.weights.entries)
        if (entry.id != 'w-1') entry.weightKg,
    ];
    expect(saved, hasLength(1));
    return saved.single;
  }

  const de = Locale('de');
  const en = Locale('en');

  testWidgets('W1: German 74.9 kg shows 74,9 and saves 74.9 kg', (
    tester,
  ) async {
    final harness = await openDialog(tester, weightKg: 74.9, locale: de);
    expect(fieldText(tester), '74,9');
    await save(tester);
    expect(savedKg(harness), 74.9);
  });

  testWidgets('W1: German 90 kg shows 90,0 and saves 90 kg', (tester) async {
    final harness = await openDialog(tester, weightKg: 90, locale: de);
    expect(fieldText(tester), '90,0');
    await save(tester);
    expect(savedKg(harness), 90);
  });

  testWidgets('W1: English 74.9 kg shows 74.9 and saves 74.9 kg', (
    tester,
  ) async {
    final harness = await openDialog(tester, weightKg: 74.9, locale: en);
    expect(fieldText(tester), '74.9');
    await save(tester);
    expect(savedKg(harness), 74.9);
  });

  for (final typed in ['78,5', '78.5']) {
    testWidgets('W1: German typing $typed saves 78.5 kg', (tester) async {
      final harness = await openDialog(tester, weightKg: 74.9, locale: de);
      await tester.enterText(
        find.byKey(DiaryWeightDialogKeys.weightDialogField),
        typed,
      );
      await save(tester);
      expect(savedKg(harness), 78.5);
    });
  }
}
