// K32 and K36 of lib/features/diary/CRITERIA.md (#911): no intro on the
// week card, the "Was ist neu" entry, and the profile's training note.
import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';
import 'package:yamt/features/calories/application/calorie_run_training_service.dart';
import 'package:yamt/features/settings/presentation/widgets/profile/profile_training_effect.dart';

import 'acceptance_harness.dart';

/// The version on master when the criteria were written (pubspec 3.10.0+43,
/// released); the change ships in a later one.
const _versionBefore = [3, 10, 0];

List<int> _versionOf(String name) =>
    name.split('.').map(int.parse).toList(growable: false);

bool _isAfter(List<int> version, List<int> other) {
  for (var i = 0; i < 3; i += 1) {
    if (version[i] != other[i]) return version[i] > other[i];
  }
  return false;
}

void main() {
  group('K32', () {
    testWidgets('K32: the first time the week card shows, nothing lies over '
        'it: no intro and no "OK" button', (tester) async {
      final harness = DiaryAcceptanceHarness(
        now: morningOf(runDay(3)),
        eaten: {runDay(0): 2200, runDay(1): 1900, runDay(2): 3000},
      );
      await harness.pumpDiary(tester);

      final card = find.byKey(WeekCardKeys.card);
      expect(card, findsOneWidget);
      expect(find.text('OK'), findsNothing);
      final hit = tester.hitTestOnBinding(tester.getCenter(card));
      final cardBox = tester.renderObject(card);
      expect(
        hit.path.any((entry) => identical(entry.target, cardBox)),
        isTrue,
        reason: 'a tap on the card reaches the card, nothing covers it',
      );
    });

    test('K32: "Was ist neu" of the next version has an entry about the '
        'carryover', () {
      final releases = Directory('distribution')
          .listSync()
          .whereType<Directory>()
          .where((dir) {
            final name = dir.uri.pathSegments.lastWhere((s) => s.isNotEmpty);
            return RegExp(r'^\d+\.\d+\.\d+$').hasMatch(name) &&
                _isAfter(_versionOf(name), _versionBefore);
          })
          .map((dir) => File('${dir.path}/whats_new.json'))
          .where((file) => file.existsSync())
          .toList();
      expect(
        releases,
        isNotEmpty,
        reason: 'a "Was ist neu" file for a version after 3.10.0',
      );
      final germanNotes = [
        for (final file in releases)
          for (final list
              in ((jsonDecode(file.readAsStringSync())
                          as Map<String, dynamic>)['de']
                      as Map<String, dynamic>)
                  .values)
            ...(list as List<dynamic>).cast<String>(),
      ];
      expect(
        germanNotes.where((note) => note.contains('Übertrag')),
        isNotEmpty,
        reason: 'an entry about the carryover being off by default',
      );
    });
  });

  group('K36', () {
    const effect = CalorieRunTrainingEffect(
      changes: [],
      otherDays: [],
      runKcalBefore: 15400,
      runKcalAfter: 15400,
    );

    void expectConditionalNote(WidgetTester tester, String mode) {
      final note = allTexts(tester)
          .where((text) => text.contains('Bei eingeschaltetem Übertrag'))
          .toList();
      expect(note, hasLength(1), reason: 'the run note is shown in "$mode"');
      final beforeCondition = note.single.split(
        'Bei eingeschaltetem Übertrag',
      )[0];
      expect(
        beforeCondition,
        isNot(contains('Übertrag')),
        reason: 'the note never names the carryover without the condition',
      );
    }

    testWidgets('K36: in every mode the training note of the profile names '
        'the carryover only "Bei eingeschaltetem Übertrag"', (tester) async {
      final harness = DiaryAcceptanceHarness(now: morningOf(runDay(3)));
      await harness.pumpDiary(tester);
      const effectPage = Scaffold(
        body: SingleChildScrollView(
          child: ProfileTrainingEffect(effect: effect),
        ),
      );

      await harness.push(tester, effectPage);
      expectConditionalNote(tester, WeekBalanceMode.show.label);
      await harness.pop(tester);

      for (final mode in [WeekBalanceMode.carryover, WeekBalanceMode.off]) {
        await chooseModeInDiary(tester, mode);
        await harness.push(tester, effectPage);
        expectConditionalNote(tester, mode.label);
        await harness.pop(tester);
      }
    });
  });
}
