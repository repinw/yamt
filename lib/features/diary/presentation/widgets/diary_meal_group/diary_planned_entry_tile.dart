import 'package:material_ui/material_ui.dart';
import 'package:yamt/core/constants/app_food_label_constants.dart';
import 'package:yamt/core/constants/app_graphit_constants.dart';
import 'package:yamt/core/constants/app_layout_constants.dart';
import 'package:yamt/core/theme/app_fonts.dart';
import 'package:yamt/core/theme/food_label_colors.dart';
import 'package:yamt/features/diary/domain/diary_meal_section.dart';
import 'package:yamt/features/diary/presentation/widgets/diary_meal_group/diary_meal_entry_tile.dart';
import 'package:yamt/features/diary/presentation/widgets/diary_meals_section_keys.dart';
import 'package:yamt/l10n/app_localizations.dart';

/// One plan: a faded food row in a dashed frame, so it reads as not eaten
/// yet, with a check button once its day has come.
class DiaryPlannedEntryTile extends StatelessWidget {
  /// Creates the row for [plan].
  const new({
    required this.plan,
    required this.onTap,
    this.onAccept,
    this.isShort = false,
    super.key,
  });

  /// Plan to display.
  final DiaryMealEntry plan;

  /// Called when the row is tapped.
  final VoidCallback onTap;

  /// Eats the plan as planned. Without it, the row has no check button.
  final VoidCallback? onAccept;

  /// Whether the Vorrat cannot cover the plan in full.
  final bool isShort;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return CustomPaint(
      key: DiaryMealsSectionKeys.plannedEntryTile(plan.id),
      foregroundPainter: _DashedFramePainter(
        Theme.of(context).colorScheme.outlineVariant,
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: AppSpacing.xs),
        child: Row(
          children: [
            Expanded(
              // One node, so a screen reader names the row a plan.
              child: MergeSemantics(
                child: Semantics(
                  label: l10n.diaryPlanSemanticsLabel,
                  child: Opacity(
                    opacity: AppGraphit.pendingRowOpacity,
                    child: DiaryMealEntryTile(
                      entry: plan,
                      onTap: onTap,
                      tag: plan.isPreparedMeal
                          ? const _MealPrepTag()
                          : isShort
                          ? const _ShortTag()
                          : null,
                    ),
                  ),
                ),
              ),
            ),
            if (onAccept case final accept?)
              IconButton.filledTonal(
                key: DiaryMealsSectionKeys.planAcceptButton(plan.id),
                tooltip: l10n.diaryPlanAcceptAction,
                onPressed: accept,
                icon: const Icon(Icons.check_rounded),
              ),
          ],
        ),
      ),
    );
  }
}

/// Marks a plan that eats portions of a prepared meal.
class _MealPrepTag extends StatelessWidget {
  const new();

  @override
  Widget build(BuildContext context) {
    final color = FoodLabelColors.of(context).accentText;
    return DecoratedBox(
      decoration: BoxDecoration(
        border: Border.all(color: color),
        borderRadius: BorderRadius.circular(AppRadius.xs),
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: AppSpacing.xs),
        child: Text(
          AppLocalizations.of(context)!.diaryPlanMealPrepTag.toUpperCase(),
          style: Theme.of(context).textTheme.labelSmall?.copyWith(
            fontFamily: AppFonts.mono,
            color: color,
            fontWeight: FontWeight.w700,
          ),
        ),
      ),
    );
  }
}

/// Marks a plan that the Vorrat cannot cover in full.
class _ShortTag extends StatelessWidget {
  const new();

  @override
  Widget build(BuildContext context) {
    return Text(
      AppLocalizations.of(context)!.diaryPlanShortTag,
      key: DiaryMealsSectionKeys.planShortTag,
      style: Theme.of(context).textTheme.labelSmall?.copyWith(
        color: FoodLabelColors.of(context).low,
        fontWeight: FontWeight.w700,
      ),
    );
  }
}

class _DashedFramePainter extends CustomPainter {
  const new(this.color);

  final Color color;

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = AppGraphit.dashedFrameWidth;
    final frame = Path()
      ..addRRect(
        // Inside the row, so the frames of two rows never touch.
        RRect.fromRectAndRadius(
          (Offset.zero & size).deflate(AppGraphit.dashedFrameWidth / 2),
          const Radius.circular(AppRadius.md),
        ),
      );
    for (final metric in frame.computeMetrics()) {
      for (var d = 0.0; d < metric.length; d += AppFoodLabel.dash * 2) {
        canvas.drawPath(metric.extractPath(d, d + AppFoodLabel.dash), paint);
      }
    }
  }

  @override
  bool shouldRepaint(_DashedFramePainter oldDelegate) =>
      oldDelegate.color != color;
}
