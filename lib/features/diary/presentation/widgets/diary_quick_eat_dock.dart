import 'dart:async' show unawaited;

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:material_ui/material_ui.dart';
import 'package:yamt/core/constants/app_layout_constants.dart';
import 'package:yamt/core/constants/app_sizes.dart';
import 'package:yamt/core/domain/local_day_window.dart';
import 'package:yamt/core/theme/food_label_colors.dart';
import 'package:yamt/core/widgets/barcode_icon.dart';
import 'package:yamt/core/widgets/home_dock_tool.dart';
import 'package:yamt/features/diary/presentation/diary_calendar_controller.dart';
import 'package:yamt/features/diary/presentation/diary_quick_eat_flow.dart';
import 'package:yamt/features/diary/presentation/widgets/diary_meals_section_keys.dart';
import 'package:yamt/l10n/app_localizations.dart';

/// Height of the dock, so pages can scroll their content above it.
const double diaryQuickEatDockHeight = AppSpacing.md * 2 + AppSizes.headerTool;

/// Quick-eat tools docked at the bottom of the diary: five equal tools for
/// the inventory, a quick entry, AI, search, and the barcode, each with its
/// word.
///
/// They log food to the selected diary day. The barcode, the fastest way to
/// log a packaged food, sits last on the lime accent; the others are tonal.
class DiaryQuickEatDock extends ConsumerWidget {
  /// Creates the dock.
  const new({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context)!;
    final colors = FoodLabelColors.of(context);
    final selectedDay = ref.watch(
      diaryCalendarControllerProvider.select((state) => state.selectedDay),
    );
    void open(DiaryQuickEatSource source) => unawaited(
      DiaryQuickEatFlow.openSource(
        context: context,
        source: source,
        selectedDay: normalizeLocalDay(selectedDay),
      ),
    );

    return DecoratedBox(
      decoration: BoxDecoration(
        color: colors.paper,
        border: Border(top: BorderSide(color: colors.rule)),
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.xl,
          vertical: AppSpacing.md,
        ),
        child: Row(
          spacing: AppSpacing.xs,
          children: [
            _DockTool(
              source: DiaryQuickEatSource.inventory,
              // Same icon as the inventory tab of the home bar.
              symbol: const Icon(Icons.inventory_2_rounded),
              label: l10n.diaryQuickEatSourceInventory,
              onPressed: open,
            ),
            _DockTool(
              source: DiaryQuickEatSource.quickEntry,
              symbol: const Icon(Icons.bolt_rounded),
              label: l10n.diaryQuickEatSourceQuickEntry,
              onPressed: open,
            ),
            _DockTool(
              source: DiaryQuickEatSource.ai,
              symbol: const Icon(Icons.auto_awesome_rounded),
              label: l10n.diaryQuickEatSourceAi,
              onPressed: open,
            ),
            _DockTool(
              source: DiaryQuickEatSource.manualSearch,
              symbol: const Icon(Icons.search_rounded),
              label: l10n.diaryQuickEatSourceManualSearch,
              onPressed: open,
            ),
            _DockTool(
              source: DiaryQuickEatSource.barcode,
              symbol: const BarcodeIcon(),
              label: l10n.diaryQuickEatSourceBarcode,
              onPressed: open,
              isAccent: true,
            ),
          ],
        ),
      ),
    );
  }
}

/// Tool of the dock for one quick-eat source.
class _DockTool extends StatelessWidget {
  const new({
    required this.source,
    required this.symbol,
    required this.label,
    required this.onPressed,
    this.isAccent = false,
  });

  final DiaryQuickEatSource source;
  final Widget symbol;
  final String label;
  final ValueChanged<DiaryQuickEatSource> onPressed;
  final bool isAccent;

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: HomeDockTool(
        key: DiaryMealsSectionKeys.quickEatSource(source),
        symbol: symbol,
        label: label,
        onPressed: () => onPressed(source),
        isAccent: isAccent,
      ),
    );
  }
}
