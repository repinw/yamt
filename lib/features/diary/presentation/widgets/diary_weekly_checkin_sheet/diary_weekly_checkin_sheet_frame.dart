import 'package:material_ui/material_ui.dart';
import 'package:yamt/core/constants/app_graphit_constants.dart';
import 'package:yamt/core/constants/app_layout_constants.dart';
import 'package:yamt/core/theme/food_label_colors.dart';
import 'package:yamt/core/theme/graphit_text_styles.dart';
import 'package:yamt/l10n/app_localizations.dart';

/// Number of steps of the weekly check-in.
const diaryWeeklyCheckInStepCount = 3;

/// Top bar, scrolling body, and bottom dock of one check-in step.
class DiaryWeeklyCheckInSheetFrame extends StatelessWidget {
  /// Creates the frame of one step.
  const new({
    required this.kicker,
    required this.stepIndex,
    required this.children,
    required this.dock,
    this.onBack,
    this.onClose,
    super.key,
  });

  /// Run and dates above the step segments.
  final String kicker;

  /// Index of the step, starting at 0.
  final int stepIndex;

  /// Content of the step.
  final List<Widget> children;

  /// Buttons at the bottom.
  final List<Widget> dock;

  /// Goes one step back. Shows a back button when set.
  final VoidCallback? onBack;

  /// Closes the sheet. Shows a close button when set and [onBack] is not.
  final VoidCallback? onClose;

  @override
  Widget build(BuildContext context) {
    final colors = FoodLabelColors.of(context);
    final l10n = AppLocalizations.of(context)!;
    final onBack = this.onBack;
    final onClose = this.onClose;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(
            AppSpacing.lg,
            AppSpacing.md,
            AppSpacing.sm,
            AppSpacing.sm,
          ),
          child: Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      kicker.toUpperCase(),
                      style: context.graphitKickerStyle,
                    ),
                    const SizedBox(height: AppSpacing.xs),
                    _StepSegments(active: stepIndex),
                  ],
                ),
              ),
              if (onBack != null)
                IconButton(
                  tooltip: l10n.diaryCheckInBack,
                  onPressed: onBack,
                  icon: const Icon(Icons.arrow_back_rounded),
                )
              else if (onClose != null)
                IconButton(
                  tooltip: l10n.diaryCheckInClose,
                  onPressed: onClose,
                  icon: const Icon(Icons.close_rounded),
                ),
            ],
          ),
        ),
        Expanded(
          child: ListView(
            padding: const EdgeInsets.fromLTRB(
              AppSpacing.lg,
              AppSpacing.sm,
              AppSpacing.lg,
              AppSpacing.lg,
            ),
            children: children,
          ),
        ),
        DecoratedBox(
          decoration: BoxDecoration(
            border: Border(top: BorderSide(color: colors.rule)),
          ),
          child: SafeArea(
            top: false,
            child: Padding(
              padding: const EdgeInsets.all(AppSpacing.md),
              child: Row(
                children: [
                  for (final (index, button) in dock.indexed) ...[
                    if (index > 0) const SizedBox(width: AppSpacing.sm),
                    Expanded(child: button),
                  ],
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }
}

class _StepSegments extends StatelessWidget {
  const new({required this.active});

  final int active;

  @override
  Widget build(BuildContext context) {
    final colors = FoodLabelColors.of(context);
    return Row(
      children: [
        for (var index = 0; index < diaryWeeklyCheckInStepCount; index++) ...[
          if (index > 0) const SizedBox(width: AppGraphit.progressSegmentGap),
          Container(
            width: AppGraphit.progressSegmentWidth,
            height: AppGraphit.progressSegmentHeight,
            color: index <= active ? colors.ink : colors.rule,
          ),
        ],
      ],
    );
  }
}

/// Title and an optional muted line under it.
class DiaryWeeklyCheckInHeading extends StatelessWidget {
  /// Creates the heading of a step.
  const new({required this.title, this.subtitle, super.key});

  /// Title of the step.
  final String title;

  /// Line under the title.
  final String? subtitle;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final subtitle = this.subtitle;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: context.graphitDisplayStyle(theme.textTheme.headlineSmall),
        ),
        if (subtitle != null) ...[
          const SizedBox(height: AppSpacing.xs),
          Text(
            subtitle,
            style: theme.textTheme.bodyMedium?.copyWith(
              color: FoodLabelColors.of(context).muted,
            ),
          ),
        ],
      ],
    );
  }
}
