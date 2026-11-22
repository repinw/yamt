import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';
import 'package:yamt/core/l10n/app_localizations_delegates.dart';
import 'package:yamt/core/preferences/app_preferences.dart';
import 'package:yamt/core/theme/app_theme.dart';
import 'package:yamt/features/auth/data/auth_service.dart';
import 'package:yamt/features/diary/domain/diary_dashboard_tiles.dart';
import 'package:yamt/features/diary/presentation/controllers/diary_dashboard_layout_controller.dart';
import 'package:yamt/features/diary/presentation/widgets/diary_dashboard/diary_dashboard_keys.dart';
import 'package:yamt/features/diary/presentation/widgets/diary_dashboard/diary_dashboard_tile.dart';
import 'package:yamt/features/diary/presentation/widgets/diary_dashboard/diary_dashboard_tile_sheet.dart';
import 'package:yamt/features/diary/presentation/widgets/diary_dashboard/tiles/diary_weight_tile.dart';
import 'package:yamt/l10n/app_localizations.dart';

import '../../../../../helpers/memory_app_preferences.dart';

/// Opens the menu of the weight tile on [theme], with the weight tile shown.
Future<void> _openSheet(WidgetTester tester, ThemeData theme) async {
  await tester.pumpWidget(
    ProviderScope(
      overrides: [
        appPreferencesProvider.overrideWithValue(MemoryAppPreferences()),
        authStateChangesProvider.overrideWithValue(const AsyncData(null)),
      ],
      child: MaterialApp(
        theme: theme,
        localizationsDelegates: appLocalizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        home: const Scaffold(),
      ),
    ),
  );
  // The default layout hides the weight tile (T1); show it first.
  final container = ProviderScope.containerOf(
    tester.element(find.byType(Scaffold)),
  );
  // Keeps the layout alive between the change and the sheet.
  final keep = container.listen(
    diaryDashboardLayoutControllerProvider,
    (_, _) {},
  );
  addTearDown(keep.close);
  await container
      .read(diaryDashboardLayoutControllerProvider.notifier)
      .show(DiaryTileIds.weight);
  unawaited(
    showDiaryDashboardTileSheet(
      tester.element(find.byType(Scaffold)),
      diaryWeightTile,
    ),
  );
  await tester.pumpAndSettle();
}

Finder _chip(DiaryTileMode mode) =>
    find.byKey(DiaryDashboardKeys.mode(mode.id));

/// Color of the text that the [RichText] under [finder] paints; an icon
/// paints its glyph this way too.
Color? _paintedColor(WidgetTester tester, Finder finder) => tester
    .widget<RichText>(
      find.descendant(of: finder, matching: find.byType(RichText)),
    )
    .text
    .style
    ?.color;

/// Fill of the chip of [mode].
Color? _fill(WidgetTester tester, DiaryTileMode mode) {
  final ink = tester.widget<Ink>(
    find.descendant(of: _chip(mode), matching: find.byType(Ink)),
  );
  return (ink.decoration! as ShapeDecoration).color;
}

void main() {
  for (final theme in <ThemeData>[AppTheme.light(), AppTheme.dark()]) {
    testWidgets('mode icons take the label color in ${theme.brightness.name}', (
      tester,
    ) async {
      await _openSheet(tester, theme);
      // A shown tile starts in its first mode.
      final [selected, unselected] = diaryWeightTile.modes;
      expect(tester.widget<ChoiceChip>(_chip(selected)).selected, isTrue);
      expect(tester.widget<ChoiceChip>(_chip(unselected)).selected, isFalse);

      for (final mode in [selected, unselected]) {
        final icon = _paintedColor(
          tester,
          find.descendant(of: _chip(mode), matching: find.byIcon(mode.icon)),
        );
        final label = _paintedColor(
          tester,
          find.descendant(of: _chip(mode), matching: find.byType(Text)),
        );

        expect(icon, label, reason: 'icon of mode ${mode.id}');
        expect(icon, isNot(_fill(tester, mode)));
      }
    });
  }
}
