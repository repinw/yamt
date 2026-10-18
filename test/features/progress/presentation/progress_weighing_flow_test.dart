import 'package:material_ui/material_ui.dart' show TextField;
import 'package:flutter_test/flutter_test.dart';
import 'package:yamt/features/health/domain/health_weight_sample.dart';
import 'package:yamt/features/progress/presentation/widgets/progress_weighing_edit_sheet.dart';
import 'package:yamt/features/progress/presentation/widgets/progress_weighing_info_sheet.dart';
import 'package:yamt/l10n/app_localizations_en.dart';

import '../../../helpers/progress_weighing_harness.dart';

final _l10n = AppLocalizationsEn();

Future<void> _tap(WidgetTester tester, Finder finder) async {
  await tester.tap(finder);
  await tester.pumpAndSettle();
}

HealthWeightSample _ownOnThisDevice() => HealthWeightSample(
  recordedAt: progressOwnSample.recordedAt,
  weightKg: progressOwnSample.weightKg,
  isFromThisApp: true,
  uuid: 'health-1',
);

void main() {
  group('a manual weighing', () {
    testWidgets('saves the changed weight under its id', (tester) async {
      final fakes = ProgressWeighingFakes();
      await pumpProgressWeights(tester, fakes);

      await _tap(
        tester,
        find.byKey(progressWeighingRowKey(entry: progressManualWeighing)),
      );
      final field = tester.widget<TextField>(
        find.byKey(ProgressWeighingEditSheet.weightKey),
      );
      expect(field.controller!.text, '80.7');
      await tester.enterText(
        find.byKey(ProgressWeighingEditSheet.weightKey),
        '80,2',
      );
      await _tap(tester, find.byKey(ProgressWeighingEditSheet.saveKey));

      expect(find.byKey(ProgressWeighingEditSheet.saveKey), findsNothing);
      final saved = fakes.manual.entries.singleWhere((e) => e.id == 'morning');
      expect(saved.weightKg, 80.2);
      expect(saved.recordedAt, DateTime(2026, 9, 24, 8));
      expect(find.byKey(progressWeighingRowKey(entry: saved)), findsOneWidget);
      expect(
        find.byKey(progressWeighingRowKey(entry: progressManualWeighing)),
        findsNothing,
      );
      expect(tester.takeException(), isNull);
    });

    testWidgets('refuses an empty or invalid weight', (tester) async {
      final fakes = ProgressWeighingFakes();
      await pumpProgressWeights(tester, fakes);
      await _tap(
        tester,
        find.byKey(progressWeighingRowKey(entry: progressManualWeighing)),
      );

      await tester.enterText(
        find.byKey(ProgressWeighingEditSheet.weightKey),
        '',
      );
      await _tap(tester, find.byKey(ProgressWeighingEditSheet.saveKey));
      expect(find.text(_l10n.caloriesCalculatorWeightEmpty), findsOneWidget);

      await tester.enterText(
        find.byKey(ProgressWeighingEditSheet.weightKey),
        'abc',
      );
      await _tap(tester, find.byKey(ProgressWeighingEditSheet.saveKey));
      expect(find.text(_l10n.caloriesCalculatorWeightInvalid), findsOneWidget);

      expect(
        fakes.manual.entries.singleWhere((e) => e.id == 'morning').weightKg,
        80.7,
      );
    });

    testWidgets('deletes the weighing', (tester) async {
      final fakes = ProgressWeighingFakes();
      await pumpProgressWeights(tester, fakes);

      await _tap(
        tester,
        find.byKey(progressWeighingRowKey(entry: progressManualWeighing)),
      );
      await _tap(tester, find.byKey(ProgressWeighingEditSheet.deleteKey));

      expect(fakes.manual.entries.any((e) => e.id == 'morning'), isFalse);
      expect(
        find.byKey(progressWeighingRowKey(entry: progressManualWeighing)),
        findsNothing,
      );
      expect(tester.takeException(), isNull);
    });

    testWidgets('shows the failure when the delete throws', (tester) async {
      final fakes = ProgressWeighingFakes();
      fakes.manual.failDeletes = true;
      await pumpProgressWeights(tester, fakes);

      await _tap(
        tester,
        find.byKey(progressWeighingRowKey(entry: progressManualWeighing)),
      );
      await _tap(tester, find.byKey(ProgressWeighingEditSheet.deleteKey));

      expect(find.text(_l10n.progressWeighingDeleteFailed), findsOneWidget);
      expect(
        find.byKey(progressWeighingRowKey(entry: progressManualWeighing)),
        findsOneWidget,
      );
    });
  });

  group('a weighing of another app', () {
    testWidgets('opens the info sheet that ignores and counts it again', (
      tester,
    ) async {
      final fakes = ProgressWeighingFakes(samples: [progressScaleSample]);
      await pumpProgressWeights(tester, fakes);
      final row = find.byKey(
        progressWeighingRowKey(sample: progressScaleSample),
      );

      await _tap(tester, row);
      expect(find.byKey(ProgressWeighingEditSheet.saveKey), findsNothing);
      expect(find.text(_l10n.progressWeighingIgnore), findsOneWidget);
      await _tap(tester, find.byKey(ProgressWeighingInfoSheet.ignoreKey));

      expect(fakes.cloud.samples.single.isIgnored, isTrue);
      await _tap(tester, row);
      expect(find.text(_l10n.progressWeighingCount), findsOneWidget);
      await _tap(tester, find.byKey(ProgressWeighingInfoSheet.ignoreKey));

      expect(fakes.cloud.samples.single.isIgnored, isFalse);
      expect(tester.takeException(), isNull);
    });

    testWidgets('opens the Health app', (tester) async {
      final fakes = ProgressWeighingFakes(samples: [progressScaleSample]);
      await pumpProgressWeights(tester, fakes);

      await _tap(
        tester,
        find.byKey(progressWeighingRowKey(sample: progressScaleSample)),
      );
      await _tap(tester, find.byKey(ProgressWeighingInfoSheet.openHealthKey));

      expect(fakes.connection.openHealthAppCallCount, 1);
      expect(find.text(_l10n.progressWeighingOpenHealthFailed), findsNothing);
    });

    testWidgets('shows the failure when the ignore does not reach the cloud', (
      tester,
    ) async {
      final fakes = ProgressWeighingFakes(samples: [progressScaleSample]);
      await pumpProgressWeights(tester, fakes);
      fakes.cloud.failChanges = true;

      await _tap(
        tester,
        find.byKey(progressWeighingRowKey(sample: progressScaleSample)),
      );
      await _tap(tester, find.byKey(ProgressWeighingInfoSheet.ignoreKey));

      expect(find.text(_l10n.progressWeighingIgnoreFailed), findsOneWidget);
      expect(fakes.cloud.samples.single.isIgnored, isFalse);
    });
  });

  group('an own Health weighing', () {
    testWidgets('on this device opens the edit sheet and deletes it', (
      tester,
    ) async {
      final fakes = ProgressWeighingFakes(
        samples: [progressOwnSample],
        onDevice: [_ownOnThisDevice()],
      );
      await pumpProgressWeights(tester, fakes);

      await _tap(
        tester,
        find.byKey(progressWeighingRowKey(sample: progressOwnSample)),
      );
      expect(find.byKey(ProgressWeighingEditSheet.saveKey), findsOneWidget);
      await _tap(tester, find.byKey(ProgressWeighingEditSheet.deleteKey));

      expect(fakes.health.deletedSamples.single.uuid, 'health-1');
      expect(fakes.cloud.samples, isEmpty);
    });

    testWidgets('held by another device is view-only with a hint', (
      tester,
    ) async {
      final fakes = ProgressWeighingFakes(samples: [progressOwnSample]);
      await pumpProgressWeights(tester, fakes);

      await _tap(
        tester,
        find.byKey(progressWeighingRowKey(sample: progressOwnSample)),
      );

      expect(find.byKey(ProgressWeighingEditSheet.saveKey), findsNothing);
      expect(find.text(_l10n.progressWeighingOtherDevice), findsOneWidget);
      expect(find.byKey(ProgressWeighingInfoSheet.openHealthKey), findsNothing);
      await _tap(tester, find.byKey(ProgressWeighingInfoSheet.ignoreKey));
      expect(fakes.cloud.samples.single.isIgnored, isTrue);
    });
  });
}
