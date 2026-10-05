import 'package:material_ui/material_ui.dart';
import 'package:yamt/core/constants/app_food_label_constants.dart';
import 'package:yamt/core/constants/app_graphit_constants.dart';
import 'package:yamt/core/constants/app_layout_constants.dart';
import 'package:yamt/features/diary/domain/diary_meal_section.dart';
import 'package:yamt/features/diary/presentation/widgets/diary_meal_group/diary_meal_entry_tile.dart';
import 'package:yamt/features/diary/presentation/widgets/diary_meals_section_keys.dart';
import 'package:yamt/l10n/app_localizations.dart';

/// One plan: a faded food row in a dashed frame, so it reads as not eaten
/// yet.
class DiaryPlannedEntryTile extends StatelessWidget {
  /// Creates the row for [plan].
  const new({required this.plan, required this.onTap, super.key});

  /// Plan to display.
  final DiaryMealEntry plan;

  /// Called when the row is tapped.
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    // One node, so a screen reader names the row a plan and its tap a delete.
    return MergeSemantics(
      key: DiaryMealsSectionKeys.plannedEntryTile(plan.id),
      child: Semantics(
        label: l10n.diaryPlanSemanticsLabel,
        onTapHint: l10n.diaryPlanDeleteAction,
        child: CustomPaint(
          foregroundPainter: _DashedFramePainter(
            Theme.of(context).colorScheme.outlineVariant,
          ),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: AppSpacing.xs),
            child: Opacity(
              opacity: AppGraphit.pendingRowOpacity,
              child: DiaryMealEntryTile(entry: plan, onTap: onTap),
            ),
          ),
        ),
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
        RRect.fromRectAndRadius(
          Offset.zero & size,
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
