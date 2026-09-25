import 'dart:async' show unawaited;

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:material_ui/material_ui.dart';
import 'package:yamt/core/constants/app_food_label_constants.dart';
import 'package:yamt/core/constants/app_layout_constants.dart';
import 'package:yamt/core/constants/app_sizes.dart';
import 'package:yamt/core/domain/local_day_window.dart';
import 'package:yamt/core/theme/app_fonts.dart';
import 'package:yamt/core/theme/food_label_colors.dart';
import 'package:yamt/core/widgets/food_label_dashed_line.dart';
import 'package:yamt/features/diary/presentation/diary_calendar_controller.dart';
import 'package:yamt/features/diary/presentation/diary_quick_eat_flow.dart';
import 'package:yamt/features/diary/presentation/widgets/diary_meals_section_keys.dart';
import 'package:yamt/l10n/app_localizations.dart';

/// Height of the dock, so pages can scroll their content above it.
const double diaryQuickEatDockHeight =
    AppFoodLabel.outline +
    AppSpacing.md * 2 +
    AppFoodLabel.buttonShadow +
    AppSizes.primaryActionHeight;

/// Quick-eat buttons docked at the bottom of the diary: square buttons for
/// the inventory, search, and AI, and a lime barcode button on the right.
///
/// They log food to the selected diary day.
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

    return ColoredBox(
      color: colors.paper,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          FoodLabelDashedLine(color: colors.ink),
          Padding(
            padding: const EdgeInsets.fromLTRB(
              AppSpacing.xl,
              AppSpacing.md,
              AppSpacing.xl + AppFoodLabel.buttonShadow,
              AppSpacing.md + AppFoodLabel.buttonShadow,
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              spacing: AppSpacing.xs,
              children: [
                Row(
                  mainAxisSize: MainAxisSize.min,
                  spacing: AppSpacing.xs,
                  children: [
                    _SquareButton(
                      source: DiaryQuickEatSource.inventory,
                      // Same icon as the inventory tab of the home bar.
                      icon: Icons.inventory_2_outlined,
                      tooltip: l10n.diaryQuickEatSourceInventory,
                      onPressed: open,
                    ),
                    _SquareButton(
                      source: DiaryQuickEatSource.manualSearch,
                      icon: Icons.search_outlined,
                      tooltip: l10n.diaryQuickEatSourceManualSearch,
                      onPressed: open,
                    ),
                    _SquareButton(
                      source: DiaryQuickEatSource.ai,
                      icon: Icons.auto_awesome_outlined,
                      tooltip: l10n.diaryQuickEatSourceAi,
                      onPressed: open,
                    ),
                  ],
                ),
                Flexible(
                  child: _BarcodeButton(
                    label: l10n.diaryQuickEatSourceBarcode,
                    onPressed: () => open(DiaryQuickEatSource.barcode),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

/// Lime button with a hard shadow, like the eat page's confirm button, as
/// wide as its label.
class _BarcodeButton extends StatelessWidget {
  const new({required this.label, required this.onPressed});

  final String label;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    final colors = FoodLabelColors.of(context);
    final textTheme = Theme.of(context).textTheme;

    return DecoratedBox(
      decoration: BoxDecoration(
        boxShadow: [
          BoxShadow(
            color: colors.ink,
            offset: const Offset(
              AppFoodLabel.buttonShadow,
              AppFoodLabel.buttonShadow,
            ),
          ),
        ],
      ),
      child: FilledButton.icon(
        key: DiaryMealsSectionKeys.quickEatSource(DiaryQuickEatSource.barcode),
        onPressed: onPressed,
        icon: _BarcodeIcon(color: colors.onAccent),
        label: Text(
          label,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: textTheme.titleMedium?.copyWith(
            fontFamily: AppFonts.display,
            fontWeight: FontWeight.w800,
            color: colors.onAccent,
          ),
        ),
        style: FilledButton.styleFrom(
          minimumSize: const Size(0, AppSizes.primaryActionHeight),
          backgroundColor: colors.accent,
          foregroundColor: colors.onAccent,
          padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg),
          shape: RoundedRectangleBorder(
            side: BorderSide(color: colors.ink, width: AppFoodLabel.outline),
          ),
        ),
      ),
    );
  }
}

/// Square framed icon button of the dock.
class _SquareButton extends StatelessWidget {
  const new({
    required this.source,
    required this.icon,
    required this.tooltip,
    required this.onPressed,
  });

  final DiaryQuickEatSource source;
  final IconData icon;
  final String tooltip;
  final ValueChanged<DiaryQuickEatSource> onPressed;

  @override
  Widget build(BuildContext context) {
    final colors = FoodLabelColors.of(context);

    return IconButton(
      key: DiaryMealsSectionKeys.quickEatSource(source),
      tooltip: tooltip,
      onPressed: () => onPressed(source),
      icon: Icon(icon, color: colors.ink),
      style: IconButton.styleFrom(
        fixedSize: const Size.square(AppSizes.primaryActionHeight),
        backgroundColor: colors.card,
        shape: RoundedRectangleBorder(
          side: BorderSide(color: colors.ink, width: AppFoodLabel.outline),
        ),
      ),
    );
  }
}

/// Small barcode: vertical bars of different widths, sized like an icon.
class _BarcodeIcon extends StatelessWidget {
  const new({required this.color});

  final Color color;

  @override
  Widget build(BuildContext context) {
    final size = IconTheme.of(context).size ?? AppSizes.barcodeIcon;
    return CustomPaint(
      size: Size(size, size * AppSizes.barcodeIconAspect),
      painter: _BarcodePainter(color),
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
