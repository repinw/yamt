import 'dart:async' show unawaited;

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:material_ui/material_ui.dart';
import 'package:yamt/core/constants/app_layout_constants.dart';
import 'package:yamt/core/constants/app_sizes.dart';
import 'package:yamt/core/domain/local_day_window.dart';
import 'package:yamt/core/theme/food_label_colors.dart';
import 'package:yamt/core/widgets/home_dock_tool.dart';
import 'package:yamt/features/diary/presentation/diary_calendar_controller.dart';
import 'package:yamt/features/diary/presentation/diary_quick_eat_flow.dart';
import 'package:yamt/features/diary/presentation/widgets/diary_meals_section_keys.dart';
import 'package:yamt/l10n/app_localizations.dart';

/// Height of the dock, so pages can scroll their content above it.
const double diaryQuickEatDockHeight = AppSpacing.md * 2 + AppSizes.headerTool;

/// Quick-eat tools docked at the bottom of the diary: five equal tonal
/// tools for the inventory, search, AI, barcode, and a quick entry, each
/// with its word.
///
/// They log food to the selected diary day. The dock carries no lime: on the
/// diary, lime marks the calories left.
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
              source: DiaryQuickEatSource.manualSearch,
              symbol: const Icon(Icons.search_rounded),
              label: l10n.diaryQuickEatSourceManualSearch,
              onPressed: open,
            ),
            _DockTool(
              source: DiaryQuickEatSource.ai,
              symbol: const Icon(Icons.auto_awesome_rounded),
              label: l10n.diaryQuickEatSourceAi,
              onPressed: open,
            ),
            _DockTool(
              source: DiaryQuickEatSource.barcode,
              symbol: const _BarcodeIcon(),
              label: l10n.diaryQuickEatSourceBarcode,
              onPressed: open,
            ),
            _DockTool(
              source: DiaryQuickEatSource.quickEntry,
              symbol: const Icon(Icons.bolt_rounded),
              label: l10n.diaryQuickEatSourceQuickEntry,
              onPressed: open,
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
  });

  final DiaryQuickEatSource source;
  final Widget symbol;
  final String label;
  final ValueChanged<DiaryQuickEatSource> onPressed;

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: HomeDockTool(
        key: DiaryMealsSectionKeys.quickEatSource(source),
        symbol: symbol,
        label: label,
        onPressed: () => onPressed(source),
      ),
    );
  }
}

/// Small barcode: vertical bars of different widths, sized and colored like
/// an icon.
class _BarcodeIcon extends StatelessWidget {
  const new();

  @override
  Widget build(BuildContext context) {
    final iconTheme = IconTheme.of(context);
    final size = iconTheme.size ?? AppSizes.barcodeIcon;
    // A square box like an icon's, so the word under it lines up with the
    // words of the other tools.
    return SizedBox.square(
      dimension: size,
      child: Center(
        child: CustomPaint(
          size: Size(size, size * AppSizes.barcodeIconAspect),
          painter: _BarcodePainter(
            iconTheme.color ?? Theme.of(context).colorScheme.onSurface,
          ),
        ),
      ),
    );
  }
}

class _BarcodePainter extends CustomPainter {
  const new(this.color);

  final Color color;

  /// Left edge and width of each bar, in 24ths of the icon width.
  static const _bars = [
    (2.0, 2.0),
    (5.5, 1.0),
    (8.0, 2.5),
    (12.5, 1.0),
    (15.0, 2.0),
    (18.5, 1.0),
    (20.5, 1.5),
  ];

  @override
  void paint(Canvas canvas, Size size) {
    final unit = size.width / 24;
    final paint = Paint()..color = color;
    for (final (left, width) in _bars) {
      canvas.drawRect(
        Rect.fromLTWH(left * unit, 0, width * unit, size.height),
        paint,
      );
    }
  }

  @override
  bool shouldRepaint(_BarcodePainter oldDelegate) => oldDelegate.color != color;
}
