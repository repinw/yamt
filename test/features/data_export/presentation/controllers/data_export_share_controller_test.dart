import 'dart:ui';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:yamt/features/data_export/application/data_export_labels.dart';
import 'package:yamt/features/data_export/data/data_export_file_sharer.dart';
import 'package:yamt/features/data_export/domain/data_export_purpose.dart';
import 'package:yamt/features/data_export/presentation/controllers/data_export_share_controller.dart';

import '../../../../helpers/data_export_fixtures.dart';
import '../../../../helpers/fake_data_export_file_sharer.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late DataExportLabels labels;
  late FakeDataExportFileSharer sharer;
  late ProviderContainer container;
  late List<AsyncValue<void>> states;

  setUpAll(() async {
    labels = await englishLabels();
  });

  setUp(() {
    sharer = FakeDataExportFileSharer();
    container = ProviderContainer(
      overrides: [dataExportFileSharerProvider.overrideWithValue(sharer)],
    );
    addTearDown(container.dispose);
    states = [];
    container.listen(
      dataExportShareControllerProvider,
      (_, next) => states.add(next),
    );
  });

  Future<DataExportOutcome> share(DataExportPurpose purpose, {Rect? origin}) =>
      container
          .read(dataExportShareControllerProvider.notifier)
          .share(
            report: sampleReport(),
            purpose: purpose,
            labels: labels,
            origin: origin,
          );

  test('the AI purpose shares the text file with the origin', () async {
    const origin = Rect.fromLTWH(1, 2, 3, 4);

    final outcome = await share(DataExportPurpose.ai, origin: origin);

    expect(outcome, DataExportOutcome.shared);
    expect(sharer.shared, hasLength(1));
    expect(sharer.shared.single.map((file) => file.mimeType), ['text/plain']);
    expect(sharer.origins, [origin]);
    expect(sharer.saved, isEmpty);
    expect(states.map((state) => state.isLoading), [true, false]);
    expect(states.last.hasError, isFalse);
  });

  test('the advisor purpose shares the PDF and the spreadsheet', () async {
    final outcome = await share(DataExportPurpose.advisor);

    expect(outcome, DataExportOutcome.shared);
    expect(sharer.shared.single.map((file) => file.name), [
      'yamt-2026-09-20-2026-09-22.pdf',
      'yamt-2026-09-20-2026-09-22.xlsx',
    ]);
    expect(sharer.saved, isEmpty);
  });

  test('the personal purpose saves the PDF instead of sharing', () async {
    final outcome = await share(DataExportPurpose.self);

    expect(outcome, DataExportOutcome.saved);
    expect(sharer.shared, isEmpty);
    expect(sharer.saved.map((file) => file.name), [
      'yamt-2026-09-20-2026-09-22.pdf',
    ]);
  });

  test('closing the save dialog cancels', () async {
    sharer.saveResult = false;

    final outcome = await share(DataExportPurpose.self);

    expect(outcome, DataExportOutcome.canceled);
    expect(states.last.hasError, isFalse);
  });

  test('a failing share sheet fails with an error state', () async {
    sharer.shareError = Exception('no share sheet');

    final outcome = await share(DataExportPurpose.ai);

    expect(outcome, DataExportOutcome.failed);
    expect(states.map((state) => state.isLoading), [true, false]);
    expect(states.last.hasError, isTrue);
  });

  test('a failing save fails with an error state', () async {
    sharer.saveError = Exception('no storage');

    final outcome = await share(DataExportPurpose.self);

    expect(outcome, DataExportOutcome.failed);
    expect(states.last.hasError, isTrue);
  });
}
