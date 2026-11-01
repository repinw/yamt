import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:material_ui/material_ui.dart';
import 'package:yamt/core/l10n/app_localizations_delegates.dart';
import 'package:yamt/features/data_export/application/data_export_labels.dart';
import 'package:yamt/features/data_export/data/data_export_file_sharer.dart';
import 'package:yamt/features/data_export/domain/data_export_purpose.dart';
import 'package:yamt/features/data_export/presentation/data_export_page.dart';
import 'package:yamt/features/data_export/presentation/widgets/'
    'data_export_purpose_tile.dart';
import 'package:yamt/features/data_export/presentation/widgets/'
    'data_export_range_chips.dart';
import 'package:yamt/l10n/app_localizations.dart';

import '../../test/features/calories/support/fake_calories_repositories.dart';
import '../../test/helpers/fake_data_export_file_sharer.dart';
import '../../test/helpers/progress_source_overrides.dart';

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  late FakeCalorieSettingsRepository settings;
  late FakeCalorieLogRepository calorieLog;
  late FakeDataExportFileSharer sharer;
  late String? clipboardText;

  setUp(() {
    settings = FakeCalorieSettingsRepository(
      initialSettings: progressTwoGoalSettings(),
    );
    addTearDown(settings.dispose);
    calorieLog = FakeCalorieLogRepository(initialEntries: progressEntries());
    addTearDown(calorieLog.dispose);
    sharer = FakeDataExportFileSharer();
    clipboardText = null;
  });

  Future<void> pumpPage(WidgetTester tester) async {
    tester.binding.defaultBinaryMessenger.setMockMethodCallHandler(
      SystemChannels.platform,
      (call) async {
        if (call.method == 'Clipboard.setData') {
          clipboardText = (call.arguments as Map)['text'] as String?;
        }
        return null;
      },
    );
    addTearDown(
      () => tester.binding.defaultBinaryMessenger.setMockMethodCallHandler(
        SystemChannels.platform,
        null,
      ),
    );
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          ...progressSourceOverrides(
            settingsRepository: settings,
            calorieLog: calorieLog,
          ),
          dataExportFileSharerProvider.overrideWithValue(sharer),
        ],
        child: const MaterialApp(
          locale: Locale('de'),
          localizationsDelegates: appLocalizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          home: DataExportPage(),
        ),
      ),
    );
    await tester.pumpAndSettle();
  }

  AppLocalizations l10nOf(WidgetTester tester) =>
      AppLocalizations.of(tester.element(find.byType(DataExportPage)))!;

  String summaryOf(WidgetTester tester) =>
      tester.widget<Text>(find.byKey(DataExportPage.summaryKey)).data!;

  /// The summary line that the page shows for [from] to [to].
  String expectedSummary(
    WidgetTester tester, {
    required DateTime from,
    required DateTime to,
    required int days,
    required int entries,
    required int weighings,
  }) {
    final l10n = l10nOf(tester);
    final labels = DataExportLabels(l10n, 'de');
    return l10n.dataExportSummary(
      labels.date(from),
      labels.date(to),
      days,
      entries,
      weighings,
    );
  }

  testWidgets('starts on Meine KI with the current goal and its summary', (
    tester,
  ) async {
    await pumpPage(tester);

    expect(
      find.byKey(DataExportPurposeTile.keyOf(DataExportPurpose.ai)),
      findsOneWidget,
    );
    expect(find.byKey(DataExportPage.copyKey), findsOneWidget);
    // Goal 2 runs from 10 to 24 September: 15 days, a meal each, and a
    // weighing every second day.
    expect(
      summaryOf(tester),
      expectedSummary(
        tester,
        from: DateTime(2026, 9, 10),
        to: DateTime(2026, 9, 24),
        days: 15,
        entries: 15,
        weighings: 8,
      ),
    );
    expect(
      find.descendant(
        of: find.byKey(DataExportPage.shareKey),
        matching: find.text(l10nOf(tester).dataExportShare),
      ),
      findsOneWidget,
    );
    expect(tester.takeException(), isNull);
  });

  testWidgets('the range chips change the period', (tester) async {
    await pumpPage(tester);

    await tester.tap(find.byKey(DataExportRangeChips.allKey));
    await tester.pumpAndSettle();
    expect(
      summaryOf(tester),
      expectedSummary(
        tester,
        from: DateTime(2026, 9),
        to: DateTime(2026, 9, 24),
        days: 24,
        entries: 24,
        weighings: 10,
      ),
    );

    await tester.tap(find.byKey(DataExportRangeChips.lastDaysKey(7)));
    await tester.pumpAndSettle();
    expect(
      summaryOf(tester),
      expectedSummary(
        tester,
        from: DateTime(2026, 9, 18),
        to: DateTime(2026, 9, 24),
        days: 7,
        entries: 7,
        weighings: 4,
      ),
    );

    await tester.tap(find.byKey(DataExportRangeChips.goalKey));
    await tester.pumpAndSettle();
    expect(summaryOf(tester), contains('15'));
    expect(tester.takeException(), isNull);
  });

  testWidgets('the goals menu picks and extends goals', (tester) async {
    await pumpPage(tester);

    await tester.tap(find.byKey(DataExportRangeChips.goalsKey));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(DataExportRangeChips.goalEntryKey(1)));
    await tester.pumpAndSettle();
    // Goal 1 alone: 1 to 9 September.
    expect(
      summaryOf(tester),
      expectedSummary(
        tester,
        from: DateTime(2026, 9),
        to: DateTime(2026, 9, 9),
        days: 9,
        entries: 9,
        weighings: 2,
      ),
    );

    await tester.tap(find.byKey(DataExportRangeChips.goalEntryKey(2)));
    await tester.pumpAndSettle();
    // Goals 1 and 2: everything up to today.
    expect(
      summaryOf(tester),
      expectedSummary(
        tester,
        from: DateTime(2026, 9),
        to: DateTime(2026, 9, 24),
        days: 24,
        entries: 24,
        weighings: 10,
      ),
    );
    expect(tester.takeException(), isNull);
  });

  testWidgets('Kopieren puts the text for the AI on the clipboard', (
    tester,
  ) async {
    await pumpPage(tester);

    await tester.tap(find.byKey(DataExportPage.copyKey));
    await tester.pumpAndSettle();

    final text = clipboardText;
    expect(text, isNotNull);
    expect(text, contains(l10nOf(tester).dataExportAiPrompt));
    expect(find.text(l10nOf(tester).dataExportCopied), findsOneWidget);
    expect(sharer.shared, isEmpty);
    expect(tester.takeException(), isNull);
  });

  testWidgets('Teilen hands the text file to the share sheet', (tester) async {
    await pumpPage(tester);

    await tester.tap(find.byKey(DataExportPage.shareKey));
    await tester.pumpAndSettle();

    expect(sharer.shared, hasLength(1));
    expect(sharer.shared.single.map((file) => file.mimeType), ['text/plain']);
    expect(sharer.shared.single.single.name, endsWith('.txt'));
    expect(sharer.saved, isEmpty);
    expect(tester.takeException(), isNull);
  });

  testWidgets('Ernährungsberater shares a PDF and a table', (tester) async {
    await pumpPage(tester);

    await tester.tap(
      find.byKey(DataExportPurposeTile.keyOf(DataExportPurpose.advisor)),
    );
    await tester.pumpAndSettle();
    expect(find.byKey(DataExportPage.copyKey), findsNothing);
    await tester.tap(find.byKey(DataExportPage.shareKey));
    await tester.pumpAndSettle();

    expect(sharer.shared.single.map((file) => file.name.split('.').last), [
      'pdf',
      'xlsx',
    ]);
    expect(tester.takeException(), isNull);
  });

  testWidgets('Für mich shows Speichern and saves the PDF', (tester) async {
    await pumpPage(tester);

    await tester.tap(
      find.byKey(DataExportPurposeTile.keyOf(DataExportPurpose.self)),
    );
    await tester.pumpAndSettle();

    expect(find.byKey(DataExportPage.copyKey), findsNothing);
    expect(
      find.descendant(
        of: find.byKey(DataExportPage.shareKey),
        matching: find.text(l10nOf(tester).dataExportSave),
      ),
      findsOneWidget,
    );

    await tester.tap(find.byKey(DataExportPage.shareKey));
    await tester.pumpAndSettle();

    expect(sharer.shared, isEmpty);
    expect(sharer.saved.map((file) => file.mimeType), ['application/pdf']);
    expect(find.text(l10nOf(tester).dataExportSaved), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('a failing share sheet shows the failure message', (
    tester,
  ) async {
    sharer.shareError = Exception('no share sheet');
    await pumpPage(tester);

    await tester.tap(find.byKey(DataExportPage.shareKey));
    await tester.pumpAndSettle();

    expect(find.text(l10nOf(tester).dataExportShareFailed), findsOneWidget);
    expect(tester.takeException(), isNull);
  });
}
