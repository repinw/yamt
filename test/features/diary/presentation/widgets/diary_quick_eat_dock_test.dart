import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';
import 'package:yamt/core/l10n/app_localizations_delegates.dart';
import 'package:yamt/core/theme/app_theme.dart';
import 'package:yamt/core/theme/food_label_colors.dart';
import 'package:yamt/features/diary/presentation/diary_quick_eat_flow.dart';
import 'package:yamt/features/diary/presentation/diary_quick_entry_page.dart';
import 'package:yamt/features/diary/presentation/widgets/diary_meals_section_keys.dart';
import 'package:yamt/features/diary/presentation/widgets/diary_quick_eat_dock.dart';
import 'package:yamt/l10n/app_localizations.dart';

import '../../../calories/support/fake_calories_repositories.dart';
import '../../support/diary_quick_entry_test_support.dart';

void main() {
  Future<void> pumpDock(WidgetTester tester, {required ThemeData theme}) async {
    await tester.binding.setSurfaceSize(const Size(390, 844));
    addTearDown(() => tester.binding.setSurfaceSize(null));
    final calorieLog = FakeCalorieLogRepository();
    addTearDown(calorieLog.dispose);
    await tester.pumpWidget(
      ProviderScope(
        overrides: quickEntryOverrides(calorieLog),
        child: MaterialApp(
          theme: theme,
          locale: const Locale('de'),
          localizationsDelegates: appLocalizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          home: const Scaffold(
            body: Align(
              alignment: Alignment.bottomCenter,
              child: DiaryQuickEatDock(),
            ),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();
  }

  testWidgets('shows five equal tools, each with its word', (tester) async {
    await pumpDock(tester, theme: AppTheme.dark());

    for (final source in DiaryQuickEatSource.values) {
      expect(
        find.byKey(DiaryMealsSectionKeys.quickEatSource(source)),
        findsOneWidget,
      );
    }
    for (final word in ['VORRAT', 'SUCHE', 'KI', 'BARCODE', 'SCHNELL']) {
      expect(find.text(word), findsOneWidget);
    }
    final widths = {
      for (final source in DiaryQuickEatSource.values)
        tester
            .getSize(find.byKey(DiaryMealsSectionKeys.quickEatSource(source)))
            .width,
    };
    expect(widths, hasLength(1));
  });

  testWidgets('orders the tools and puts the barcode on the lime accent', (
    tester,
  ) async {
    await pumpDock(tester, theme: AppTheme.dark());

    double leftOf(DiaryQuickEatSource source) => tester
        .getTopLeft(find.byKey(DiaryMealsSectionKeys.quickEatSource(source)))
        .dx;
    final sources = [...DiaryQuickEatSource.values]
      ..sort((a, b) => leftOf(a).compareTo(leftOf(b)));
    expect(sources, [
      DiaryQuickEatSource.inventory,
      DiaryQuickEatSource.quickEntry,
      DiaryQuickEatSource.ai,
      DiaryQuickEatSource.manualSearch,
      DiaryQuickEatSource.barcode,
    ]);

    Color? surfaceOf(DiaryQuickEatSource source) => tester
        .widget<Material>(
          find
              .descendant(
                of: find.byKey(DiaryMealsSectionKeys.quickEatSource(source)),
                matching: find.byType(Material),
              )
              .first,
        )
        .color;
    final context = tester.element(find.byType(DiaryQuickEatDock));
    final accent = FoodLabelColors.of(context).accent;
    expect(surfaceOf(DiaryQuickEatSource.barcode), accent);
    expect(surfaceOf(DiaryQuickEatSource.quickEntry), isNot(accent));
  });

  testWidgets('the quick tool opens the quick entry page', (tester) async {
    await pumpDock(tester, theme: AppTheme.dark());

    await tester.tap(
      find.byKey(
        DiaryMealsSectionKeys.quickEatSource(DiaryQuickEatSource.quickEntry),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.byType(DiaryQuickEntryPage), findsOneWidget);
    expect(find.text('Schnelleintrag'), findsOneWidget);
  });

  testWidgets('fits its declared height in light mode', (tester) async {
    await pumpDock(tester, theme: AppTheme.light());

    expect(
      tester.getSize(find.byType(DiaryQuickEatDock)).height,
      diaryQuickEatDockHeight,
    );
    expect(tester.takeException(), isNull);
  });
}
