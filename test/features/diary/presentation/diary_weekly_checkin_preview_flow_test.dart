import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';
import 'package:yamt/core/l10n/app_localizations_delegates.dart';
import 'package:yamt/core/provider/clock_provider.dart';
import 'package:yamt/features/calories/application/calorie_weekly_checkin_demo_data.dart';
import 'package:yamt/features/calories/domain/macro_goal_settings.dart';
import 'package:yamt/features/diary/application/diary_weekly_checkin_provider.dart';
import 'package:yamt/features/diary/presentation/diary_weekly_checkin_preview_flow.dart';
import 'package:yamt/features/diary/presentation/widgets/diary_weekly_checkin_preview_tiles.dart';
import 'package:yamt/features/diary/presentation/widgets/'
    'diary_weekly_checkin_sheet/diary_weekly_checkin_sheet_keys.dart';
import 'package:yamt/l10n/app_localizations.dart';

final _today = DateTime(2026, 9, 30);

Future<void> _pumpTiles(WidgetTester tester) async {
  tester.view
    ..physicalSize = const Size(1080, 2400)
    ..devicePixelRatio = 3;
  addTearDown(tester.view.reset);
  await tester.pumpWidget(
    ProviderScope(
      overrides: [
        clockProvider.overrideWithValue(() => _today),
        diaryWeeklyCheckInPreviewDataProvider.overrideWith(
          (ref) async => calorieWeeklyCheckInDemoData(today: _today),
        ),
        diaryWeeklyCheckInPreviewPlanProvider.overrideWith(
          (ref) async => calorieWeeklyCheckInDemoPlan(
            today: _today,
            macroSettings: const MacroGoalSettings(),
            profile: null,
          ),
        ),
      ],
      child: const MaterialApp(
        locale: Locale('en'),
        localizationsDelegates: appLocalizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        home: Scaffold(body: DiaryWeeklyCheckInPreviewTiles()),
      ),
    ),
  );
}

void main() {
  testWidgets('the preview opens the check-in and saves nothing', (
    tester,
  ) async {
    await _pumpTiles(tester);

    await tester.tap(
      find.byKey(
        DiaryWeeklyCheckInPreviewTiles.tileKey(
          DiaryWeeklyCheckInPreviewKind.checkIn,
        ),
      ),
    );
    await tester.pumpAndSettle();
    expect(find.text('Week done'), findsOneWidget);

    await tester.tap(find.byKey(DiaryWeeklyCheckInSheetKeys.laterButton));
    await tester.pumpAndSettle();

    expect(
      find.text('Preview: later, 0 training days, nothing saved'),
      findsOneWidget,
    );
  });

  testWidgets('the missing data preview shows the blocked check-in', (
    tester,
  ) async {
    await _pumpTiles(tester);

    await tester.tap(
      find.byKey(
        DiaryWeeklyCheckInPreviewTiles.tileKey(
          DiaryWeeklyCheckInPreviewKind.missingData,
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('Check-in needs data'), findsOneWidget);
    expect(
      find.byKey(DiaryWeeklyCheckInSheetKeys.trackMissingWeightButton),
      findsOneWidget,
    );
  });

  testWidgets('the goal reached preview shows the congratulations', (
    tester,
  ) async {
    await _pumpTiles(tester);

    await tester.tap(
      find.byKey(
        DiaryWeeklyCheckInPreviewTiles.tileKey(
          DiaryWeeklyCheckInPreviewKind.goalReached,
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('Congratulations!'), findsOneWidget);
  });
}
