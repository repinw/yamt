import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:material_ui/material_ui.dart';
import 'package:yamt/core/l10n/app_localizations_delegates.dart';
import 'package:yamt/core/theme/app_fonts.dart';
import 'package:yamt/core/widgets/home_shell_menu_scope.dart';
import 'package:yamt/features/diary/domain/diary_calendar_bounds.dart';
import 'package:yamt/features/diary/presentation/diary_calendar_controller.dart';
import 'package:yamt/features/diary/presentation/widgets/diary_home_shell_top_chrome.dart';
import 'package:yamt/features/shoppinglist/presentation/controllers/shopping_open_count.dart';
import 'package:yamt/l10n/app_localizations.dart';

import '../../../../helpers/app_font_test_utils.dart';

class _FixedCalendarController extends DiaryCalendarController {
  new(this.today, this.day);

  final DateTime today;
  final DateTime day;

  @override
  DiaryCalendarState build() =>
      DiaryCalendarState(today: today, selectedDay: day);
}

void main() {
  setUpAll(() async {
    await initializeDateFormatting('de');
    await loadAppFonts();
  });

  final today = DateTime(2026, 11, 21);

  for (final width in [360.0, 412.0]) {
    for (final (name, day) in [
      ('today, with Einkauf', today),
      ('yesterday, with Heute', DateTime(2026, 11, 20)),
    ]) {
      testWidgets('the diary top chrome is 68 dp high at text scale 1.0: '
          '${width}px, $name', (tester) async {
        tester.view.physicalSize = Size(width, 800);
        tester.view.devicePixelRatio = 1;
        addTearDown(tester.view.reset);
        await tester.pumpWidget(
          ProviderScope(
            overrides: [
              diaryCalendarControllerProvider.overrideWith(
                () => _FixedCalendarController(today, day),
              ),
              diaryCalendarBoundsProvider.overrideWithValue(
                DiaryCalendarBounds.resolve(today: today),
              ),
              openShoppingListCountProvider.overrideWithValue(
                const AsyncData(3),
              ),
            ],
            child: MaterialApp(
              theme: ThemeData(fontFamily: AppFonts.sans),
              locale: const Locale('de'),
              localizationsDelegates: appLocalizationsDelegates,
              supportedLocales: AppLocalizations.supportedLocales,
              home: HomeShellMenuScope(
                openMenu: () {},
                child: const Scaffold(
                  body: Column(
                    children: [
                      DiaryHomeShellTopChrome(),
                      Expanded(child: SizedBox()),
                    ],
                  ),
                ),
              ),
            ),
          ),
        );
        await tester.pumpAndSettle();

        expect(tester.takeException(), isNull);
        expect(find.text('Menü'), findsOneWidget);
        expect(
          find.text(name.contains('Einkauf') ? 'Einkauf' : 'Heute'),
          findsOneWidget,
        );
        expect(tester.getSize(find.byType(DiaryHomeShellTopChrome)).height, 68);
      });
    }
  }
}
