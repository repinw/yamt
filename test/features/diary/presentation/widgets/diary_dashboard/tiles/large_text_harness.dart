import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/misc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';
import 'package:yamt/core/constants/app_dashboard_constants.dart';
import 'package:yamt/core/l10n/app_localizations_delegates.dart';
import 'package:yamt/features/diary/domain/diary_dashboard_layout.dart';
import 'package:yamt/features/diary/presentation/widgets/diary_dashboard/diary_dashboard_grid_block.dart';
import 'package:yamt/l10n/app_localizations.dart';

/// Grid widths of phones 320, 343, and 411 dp wide, less the page's side
/// padding: the narrow phones where large text strains the tiles.
const largeTextGridWidths = [288.0, 311.0, 379.0];

/// The system text scale of the people who set their text largest.
const largeTextScale = 2.0;

/// Key of the frame the tile content gets.
const largeTextSlotKey = ValueKey<String>('large-text-slot');

/// Sizes that a tile of [size] may grow from: every smaller size of
/// [sizes].
List<DiaryTileSize> growSlots(DiaryTileSize size, List<DiaryTileSize> sizes) =>
    [
      for (final other in sizes)
        if (other != size &&
            other.columns <= size.columns &&
            other.rows! <= size.rows!)
          other,
    ];

/// Pumps [child] in the frame of a tile of [slot] on a grid [gridWidth]
/// wide at text scale [textScale], in [locale].
///
/// A tile that resizes slides to its new size, so for a while the content of
/// the new size draws in the frame of the old one: pass the old size as
/// [slot] to see that moment.
///
/// With [boldText], the system's Bold Text setting is on.
///
/// With [overrides], the page sits in a fresh [ProviderScope].
Future<void> pumpInTileSlot(
  WidgetTester tester, {
  required Widget child,
  required DiaryTileSize slot,
  required double gridWidth,
  double textScale = largeTextScale,
  bool boldText = false,
  String locale = 'de',
  List<Override>? overrides,
}) async {
  final textScaler = TextScaler.linear(textScale);
  final metrics = DiaryDashboardMetrics.of(gridWidth, textScaler);
  Widget app = MaterialApp(
    locale: Locale(locale),
    localizationsDelegates: appLocalizationsDelegates,
    supportedLocales: AppLocalizations.supportedLocales,
    builder: (context, page) => MediaQuery(
      data: MediaQuery.of(context)
          .copyWith(textScaler: textScaler, boldText: boldText),
      child: page!,
    ),
    home: Scaffold(
      body: Center(
        child: SizedBox(
          key: largeTextSlotKey,
          width: metrics.width(slot.columns) - 2 * AppDashboard.tilePadding,
          height: metrics.height(slot.rows!) - 2 * AppDashboard.tilePadding,
          child: child,
        ),
      ),
    ),
  );
  if (overrides != null) {
    app = ProviderScope(key: UniqueKey(), overrides: overrides, child: app);
  }
  await tester.pumpWidget(app);
  await tester.pumpAndSettle();
}

/// How many of [texts] show on the page as a whole text.
int shownCount(Iterable<String> texts) =>
    texts.where((text) => find.text(text).evaluate().isNotEmpty).length;
