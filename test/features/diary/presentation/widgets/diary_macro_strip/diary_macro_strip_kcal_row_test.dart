import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';
import 'package:yamt/core/l10n/app_localizations_delegates.dart';
import 'package:yamt/features/diary/presentation/widgets/diary_macro_strip/diary_macro_strip_kcal_row.dart';
import 'package:yamt/features/diary/presentation/widgets/diary_segmented_progress_bar.dart';
import 'package:yamt/l10n/app_localizations.dart';

void main() {
  Future<void> pump(WidgetTester tester, {required bool countsPlanned}) {
    return tester.pumpWidget(
      MaterialApp(
        locale: const Locale('en'),
        localizationsDelegates: appLocalizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        home: Scaffold(
          body: DiaryMacroStripKcalRow(
            eaten: 1000,
            target: 2000,
            planned: 600,
            countsPlanned: countsPlanned,
            showTotal: false,
          ),
        ),
      ),
    );
  }

  testWidgets('counts the planned kcal only with "Nach Plan" on', (
    tester,
  ) async {
    await pump(tester, countsPlanned: true);

    expect(find.text('400 left'), findsOneWidget);
  });

  testWidgets('stripes the planned kcal also when they do not count', (
    tester,
  ) async {
    await pump(tester, countsPlanned: false);

    expect(find.text('1,000 left'), findsOneWidget);
    expect(find.byType(DiaryStripedSpan), findsWidgets);
  });
}
