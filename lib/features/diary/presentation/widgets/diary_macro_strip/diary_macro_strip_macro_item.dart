import 'package:intl/intl.dart';
import 'package:material_ui/material_ui.dart';
import 'package:yamt/core/constants/app_layout_constants.dart';
import 'package:yamt/features/diary/presentation/widgets/diary_macro_strip/diary_macro_strip_amount_text.dart';
import 'package:yamt/features/diary/presentation/widgets/diary_segmented_progress_bar.dart';
import 'package:yamt/l10n/app_localizations.dart';

/// One macro of the macro strip: letter, amount, and segmented bar.
class DiaryMacroStripMacroItem extends StatelessWidget {
  /// Creates the widget.
  const new({
    required this.letter,
    required this.current,
    required this.target,
    required this.color,
    required this.showTotal,
    super.key,
  });

  /// Short macro label, e.g. "P".
  final String letter;

  /// Amount eaten.
  final double current;

  /// Target amount.
  final double target;

  /// Accent color of the macro.
  final Color color;

  /// Whether eaten and target are shown instead of what is left.
  final bool showTotal;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colors = theme.colorScheme;
    final format = NumberFormat.decimalPattern(
      Localizations.localeOf(context).toLanguageTag(),
    );
    final labelStyle = theme.textTheme.labelSmall?.copyWith(
      color: colors.onSurfaceVariant,
      fontWeight: FontWeight.w700,
    );

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Row(
          children: [
            Text(letter, style: labelStyle),
            const Spacer(),
            DiaryMacroStripAmountText(
              current: current,
              target: target,
              suffix: AppLocalizations.of(context)!.caloriesUnitGram,
              showTotal: showTotal,
              format: format,
              style: labelStyle,
            ),
          ],
        ),
        const SizedBox(height: AppSpacing.xxs),
        DiarySegmentedProgressBar(
          progress: target <= 0 ? 0 : current / target,
          color: color,
          trackColor: colors.surfaceContainerHighest,
          isDark: colors.brightness == Brightness.dark,
          height: 4,
        ),
      ],
    );
  }
}
