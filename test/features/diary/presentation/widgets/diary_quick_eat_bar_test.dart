import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';
import 'package:yamt/core/l10n/app_localizations_delegates.dart';
import 'package:yamt/features/diary/presentation/diary_quick_eat_flow.dart';
import 'package:yamt/features/diary/presentation/widgets/diary_meals_section_keys.dart';
import 'package:yamt/features/diary/presentation/widgets/diary_quick_eat_bar.dart';
import 'package:yamt/l10n/app_localizations.dart';

void main() {
  Future<List<DiaryQuickEatSource>> pumpBar(
    WidgetTester tester, {
    required bool expanded,
  }) async {
    final selected = <DiaryQuickEatSource>[];
    await tester.pumpWidget(
      MaterialApp(
        locale: const Locale('de'),
        localizationsDelegates: appLocalizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        home: Scaffold(
          body: DiaryQuickEatBar(expanded: expanded, onSelected: selected.add),
        ),
      ),
    );
    await tester.pumpAndSettle();
    return selected;
  }

  testWidgets('expanded bar shows emoji with labels', (tester) async {
    await pumpBar(tester, expanded: true);

    for (final label in ['Vorrat', 'Suche', 'KI', 'Barcode']) {
      expect(find.text(label), findsOneWidget);
    }
    expect(find.byIcon(Icons.inventory_2_rounded), findsOneWidget);
    expect(find.text('𝄃𝄂𝄀𝄁𝄃𝄂𝄂𝄃'), findsOneWidget);
    expect(
      tester
          .getSize(
            find.byKey(
              DiaryMealsSectionKeys.quickEatSource(DiaryQuickEatSource.ai),
            ),
          )
          .height,
      88,
    );
  });

  testWidgets('compact bar shows emoji only', (tester) async {
    await pumpBar(tester, expanded: false);

    expect(find.text('Vorrat'), findsNothing);
    expect(find.text('🔍'), findsOneWidget);
    expect(
      tester
          .getSize(
            find.byKey(
              DiaryMealsSectionKeys.quickEatSource(DiaryQuickEatSource.ai),
            ),
          )
          .height,
      44,
    );
  });

  testWidgets('tapping a button reports its source', (tester) async {
    final selected = await pumpBar(tester, expanded: false);

    await tester.tap(
      find.byKey(
        DiaryMealsSectionKeys.quickEatSource(DiaryQuickEatSource.barcode),
      ),
    );

    expect(selected, [DiaryQuickEatSource.barcode]);
  });
}
