import 'package:flutter/foundation.dart';
import 'package:material_ui/material_ui.dart';
import 'package:yamt/core/constants/app_layout_constants.dart';
import 'package:yamt/core/constants/app_sizes.dart';
import 'package:yamt/core/widgets/app_responsive_viewport.dart';
import 'package:yamt/features/diary/presentation/widgets/diary_macro_strip/diary_macro_strip.dart';
import 'package:yamt/features/diary/presentation/widgets/diary_macro_strip/diary_macro_strip_stage.dart';

/// Space the strip adds around its kcal row: top padding plus the bottom
/// border. The kcal row's own bottom spacing is part of the row.
const double diaryMacroStripKcalRowInset = AppSpacing.xs + 1;

/// Opaque [DiaryMacroStrip] below the top bar that reveals the kcal bar and
/// then the macro bars as their daily card counterparts scroll away.
class DiaryMacroStripOverlay extends StatelessWidget {
  /// Creates the strip overlay.
  const new({
    required this.selectedDay,
    required this.stage,
    this.kcalRowKey,
    super.key,
  });

  /// Key of the kcal row, used to measure how much of the page it covers.
  final Key? kcalRowKey;

  /// Selected diary day.
  final DateTime selectedDay;

  /// Current reveal stage.
  final ValueListenable<DiaryMacroStripStage> stage;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;

    return IgnorePointer(
      child: ValueListenableBuilder<DiaryMacroStripStage>(
        valueListenable: stage,
        builder: (context, stage, _) => DecoratedBox(
          decoration: BoxDecoration(
            color: colors.surface,
            border: stage == DiaryMacroStripStage.hidden
                ? null
                : Border(bottom: BorderSide(color: colors.outlineVariant)),
          ),
          child: Padding(
            padding: EdgeInsets.symmetric(
              horizontal: responsivePageHorizontalPadding(context),
            ),
            child: Center(
              child: ConstrainedBox(
                constraints: const BoxConstraints(
                  maxWidth: AppSizes.narrowContentMaxWidth,
                ),
                child: Padding(
                  padding: EdgeInsets.symmetric(
                    vertical: stage == DiaryMacroStripStage.hidden
                        ? 0
                        : AppSpacing.xs,
                  ),
                  child: DiaryMacroStrip(
                    selectedDay: selectedDay,
                    showKcal: stage != DiaryMacroStripStage.hidden,
                    showMacros: stage == DiaryMacroStripStage.full,
                    kcalRowKey: kcalRowKey,
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
