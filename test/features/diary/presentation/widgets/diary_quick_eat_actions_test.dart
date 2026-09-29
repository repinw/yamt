import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';
import 'package:yamt/core/l10n/app_localizations_delegates.dart';
import 'package:yamt/core/theme/app_theme.dart';
import 'package:yamt/features/diary/presentation/diary_quick_eat_flow.dart';
import 'package:yamt/features/diary/presentation/diary_quick_entry_page.dart';
import 'package:yamt/features/diary/presentation/widgets/diary_meals_section_keys.dart';
import 'package:yamt/features/diary/presentation/widgets/diary_quick_eat_actions.dart';
import 'package:yamt/l10n/app_localizations.dart';

import '../../../../helpers/sheet_launcher.dart';
import '../../../calories/support/fake_calories_repositories.dart';
import '../../support/diary_quick_entry_test_support.dart';

void main() {
  Future<void> openSheet(WidgetTester tester) async {
    await tester.binding.setSurfaceSize(const Size(390, 844));
    addTearDown(() => tester.binding.setSurfaceSize(null));
    final calorieLog = FakeCalorieLogRepository();
    addTearDown(calorieLog.dispose);
    await tester.pumpWidget(
      ProviderScope(
        overrides: quickEntryOverrides(calorieLog),
        child: MaterialApp(
          theme: AppTheme.dark(),
          locale: const Locale('de'),
          localizationsDelegates: appLocalizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          home: const Scaffold(
            body: Center(child: SheetLauncher(actions: diaryQuickEatActions)),
          ),
        ),
      ),
    );
    await tester.tap(find.byKey(SheetLauncher.buttonKey));
    await tester.pumpAndSettle();
  }

  testWidgets('lists the five sources with the barcode first', (tester) async {
    await openSheet(tester);

    double topOf(DiaryQuickEatSource source) => tester
        .getTopLeft(find.byKey(DiaryMealsSectionKeys.quickEatSource(source)))
        .dy;
    final sources = [...DiaryQuickEatSource.values]
      ..sort((a, b) => topOf(a).compareTo(topOf(b)));
    expect(sources, [
      DiaryQuickEatSource.barcode,
      DiaryQuickEatSource.inventory,
      DiaryQuickEatSource.quickEntry,
      DiaryQuickEatSource.ai,
      DiaryQuickEatSource.manualSearch,
    ]);
    expect(find.text('ESSEN'), findsOneWidget);
  });

  testWidgets('the quick entry opens the quick entry page', (tester) async {
    await openSheet(tester);

    await tester.tap(
      find.byKey(
        DiaryMealsSectionKeys.quickEatSource(DiaryQuickEatSource.quickEntry),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.byType(DiaryQuickEntryPage), findsOneWidget);
    expect(find.text('Schnelleintrag'), findsOneWidget);
  });
}
