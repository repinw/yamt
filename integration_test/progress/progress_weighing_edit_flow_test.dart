import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:yamt/features/progress/presentation/widgets/progress_weighing_edit_sheet.dart';
import 'package:yamt/features/progress/presentation/widgets/progress_weighing_info_sheet.dart';

import '../../test/helpers/progress_weighing_harness.dart';

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  testWidgets('the weight list edits an own weighing and ignores a scale one', (
    tester,
  ) async {
    final fakes = ProgressWeighingFakes(samples: [progressScaleSample]);
    await pumpProgressWeights(tester, fakes);

    // An own weighing opens the edit sheet and saves the new weight.
    await tester.tap(
      find.byKey(progressWeighingRowKey(entry: progressManualWeighing)),
    );
    await tester.pumpAndSettle();
    await tester.enterText(
      find.byKey(ProgressWeighingEditSheet.weightKey),
      '80.1',
    );
    await tester.tap(find.byKey(ProgressWeighingEditSheet.saveKey));
    await tester.pumpAndSettle();

    final saved = fakes.manual.entries.singleWhere((e) => e.id == 'morning');
    expect(saved.weightKg, 80.1);
    expect(find.byKey(progressWeighingRowKey(entry: saved)), findsOneWidget);

    // A weighing of another app opens the info sheet and is ignored.
    await tester.tap(
      find.byKey(progressWeighingRowKey(sample: progressScaleSample)),
    );
    await tester.pumpAndSettle();
    expect(find.byKey(ProgressWeighingEditSheet.saveKey), findsNothing);
    await tester.tap(find.byKey(ProgressWeighingInfoSheet.ignoreKey));
    await tester.pumpAndSettle();

    expect(fakes.cloud.samples.single.isIgnored, isTrue);
    expect(
      find.byKey(progressWeighingRowKey(sample: progressScaleSample)),
      findsOneWidget,
    );
    expect(tester.takeException(), isNull);
  });
}
