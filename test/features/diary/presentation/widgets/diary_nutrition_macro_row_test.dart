import 'package:flutter_test/flutter_test.dart';
import 'package:intl/intl.dart';
import 'package:material_ui/material_ui.dart';
import 'package:yamt/core/l10n/app_localizations_delegates.dart';
import 'package:yamt/features/diary/presentation/widgets/diary_nutrition_bars/diary_nutrition_macro_row.dart';
import 'package:yamt/features/diary/presentation/widgets/diary_segmented_progress_bar.dart';
import 'package:yamt/l10n/app_localizations.dart';

void main() {
  group('DiaryNutritionMacroRow', () {
    final numberFormat = NumberFormat.decimalPattern('en');

    Future<void> pumpRow(
      WidgetTester tester, {
      required String label,
      required double current,
      required double target,
      bool showTotal = true,
    }) async {
      await tester.pumpWidget(
        MaterialApp(
          localizationsDelegates: appLocalizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          home: Scaffold(
            body: Center(
              child: SizedBox(
                width: 350,
                child: DiaryNutritionMacroRow(
                  label: label,
                  current: current,
                  target: target,
                  color: Colors.green,
                  numberFormat: numberFormat,
                  showTotal: showTotal,
                ),
              ),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();
    }

    testWidgets('renders remaining grams when intake is under target', (
      tester,
    ) async {
      await pumpRow(tester, label: 'Protein', current: 45, target: 100);

      // 100 - 45 = 55g remaining
      expect(find.text('55'), findsOneWidget);
      expect(find.text('g left'), findsOneWidget);
      expect(find.text('Protein'), findsOneWidget);
      expect(
        find.textContaining('45 / 100 g', findRichText: true),
        findsOneWidget,
      );
    });

    testWidgets('renders 0g remaining when intake equals target', (
      tester,
    ) async {
      await pumpRow(tester, label: 'Carbs', current: 150, target: 150);

      expect(find.text('0'), findsOneWidget);
      expect(find.text('Carbs'), findsOneWidget);
      expect(
        find.textContaining('150 / 150 g', findRichText: true),
        findsOneWidget,
      );
    });

    testWidgets('renders plus indicator (+Xg) when intake exceeds target', (
      tester,
    ) async {
      await pumpRow(tester, label: 'Fat', current: 85, target: 70);

      // 85 - 70 = +15g overage
      expect(find.text('+15'), findsOneWidget);
      expect(find.text('g over'), findsOneWidget);
      expect(find.text('Fat'), findsOneWidget);
      expect(
        find.textContaining('85 / 70 g', findRichText: true),
        findsOneWidget,
      );
    });

    double barOverflow(WidgetTester tester) => tester
        .widget<DiarySegmentedProgressBar>(
          find.byType(DiarySegmentedProgressBar),
        )
        .overflow;

    testWidgets('stripes the overage share of the bar', (tester) async {
      await pumpRow(tester, label: 'Fat', current: 85, target: 70);

      expect(barOverflow(tester), closeTo(15 / 85, 0.0001));
    });

    testWidgets('stripes protein beyond its target like the other macros', (
      tester,
    ) async {
      await pumpRow(tester, label: 'Protein', current: 120, target: 100);

      expect(find.text('+20'), findsOneWidget);
      expect(barOverflow(tester), closeTo(20 / 120, 0.0001));
    });

    testWidgets('handles zero target safely without division by zero', (
      tester,
    ) async {
      await pumpRow(tester, label: 'Protein', current: 0, target: 0);

      expect(find.text('0'), findsOneWidget);
      expect(
        find.textContaining('0 / 0 g', findRichText: true),
        findsOneWidget,
      );
      expect(tester.takeException(), isNull);
    });

    testWidgets('hides eaten and target when totals are off', (tester) async {
      await pumpRow(
        tester,
        label: 'Protein',
        current: 45,
        target: 100,
        showTotal: false,
      );

      expect(find.text('55'), findsOneWidget);
      expect(
        find.textContaining('45 / 100 g', findRichText: true),
        findsNothing,
      );
    });
  });
}
