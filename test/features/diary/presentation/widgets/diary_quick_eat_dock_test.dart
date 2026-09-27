import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';
import 'package:yamt/core/l10n/app_localizations_delegates.dart';
import 'package:yamt/core/provider/clock_provider.dart';
import 'package:yamt/core/theme/app_theme.dart';
import 'package:yamt/features/diary/presentation/diary_quick_eat_flow.dart';
import 'package:yamt/features/diary/presentation/widgets/diary_meals_section_keys.dart';
import 'package:yamt/features/diary/presentation/widgets/diary_quick_eat_dock.dart';
import 'package:yamt/l10n/app_localizations.dart';

void main() {
  Future<void> pumpDock(WidgetTester tester, {required ThemeData theme}) async {
    await tester.binding.setSurfaceSize(const Size(390, 844));
    addTearDown(() => tester.binding.setSurfaceSize(null));
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          clockProvider.overrideWithValue(() => DateTime(2026, 4, 27)),
        ],
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

  testWidgets('shows four equal tools, each with its word', (tester) async {
    await pumpDock(tester, theme: AppTheme.dark());

    for (final source in DiaryQuickEatSource.values) {
      expect(
        find.byKey(DiaryMealsSectionKeys.quickEatSource(source)),
        findsOneWidget,
      );
    }
    for (final word in ['VORRAT', 'SUCHE', 'KI', 'BARCODE']) {
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

  testWidgets('fits its declared height in light mode', (tester) async {
    await pumpDock(tester, theme: AppTheme.light());

    expect(
      tester.getSize(find.byType(DiaryQuickEatDock)).height,
      diaryQuickEatDockHeight,
    );
    expect(tester.takeException(), isNull);
  });
}
