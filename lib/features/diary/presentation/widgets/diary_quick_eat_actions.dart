import 'dart:async' show unawaited;

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:material_ui/material_ui.dart';
import 'package:yamt/core/domain/local_day_window.dart';
import 'package:yamt/core/widgets/barcode_icon.dart';
import 'package:yamt/core/widgets/home_action_entry.dart';
import 'package:yamt/features/diary/presentation/diary_calendar_controller.dart';
import 'package:yamt/features/diary/presentation/diary_quick_eat_flow.dart';
import 'package:yamt/features/diary/presentation/widgets/diary_meals_section_keys.dart';
import 'package:yamt/l10n/app_localizations.dart';

/// The ways to log food to the selected diary day: barcode, Vorrat, quick
/// entry, AI, and search. The barcode, the fastest way to log a packaged
/// food, comes first. A future day hides the product search, which saves
/// no plans yet.
List<HomeActionSection> diaryQuickEatActions(
  BuildContext context,
  WidgetRef ref,
) {
  final l10n = AppLocalizations.of(context)!;
  final selectedDay = normalizeLocalDay(
    ref.watch(
      diaryCalendarControllerProvider.select((state) => state.selectedDay),
    ),
  );
  // The product search saves no plans yet, so a future day hides it.
  final canSearch = !ref.watch(
    diaryCalendarControllerProvider.select(
      (state) => state.isFutureDay(selectedDay),
    ),
  );

  HomeActionEntry entry(
    DiaryQuickEatSource source,
    Widget symbol,
    String title,
    String description,
  ) {
    return HomeActionEntry(
      key: DiaryMealsSectionKeys.quickEatSource(source),
      symbol: symbol,
      title: title,
      description: description,
      onSelected: () => unawaited(
        DiaryQuickEatFlow.openSource(
          context: context,
          source: source,
          selectedDay: selectedDay,
        ),
      ),
    );
  }

  return [
    HomeActionSection(
      title: l10n.homeActionEat,
      entries: [
        if (canSearch)
          entry(
            DiaryQuickEatSource.barcode,
            const BarcodeIcon(),
            l10n.diaryQuickEatSourceBarcode,
            l10n.diaryQuickEatBarcodeDescription,
          ),
        entry(
          DiaryQuickEatSource.inventory,
          const Icon(Icons.inventory_2_rounded),
          l10n.diaryQuickEatInventoryTitle,
          l10n.diaryQuickEatInventoryDescription,
        ),
        entry(
          DiaryQuickEatSource.quickEntry,
          const Icon(Icons.bolt_rounded),
          l10n.diaryQuickEatSourceQuickEntry,
          l10n.diaryQuickEatQuickEntryDescription,
        ),
        if (canSearch)
          entry(
            DiaryQuickEatSource.ai,
            const Icon(Icons.auto_awesome_rounded),
            l10n.diaryQuickEatSourceAi,
            l10n.diaryQuickEatAiDescription,
          ),
        if (canSearch)
          entry(
            DiaryQuickEatSource.manualSearch,
            const Icon(Icons.search_rounded),
            l10n.diaryQuickEatSourceManualSearch,
            l10n.diaryQuickEatSearchDescription,
          ),
      ],
    ),
  ];
}
