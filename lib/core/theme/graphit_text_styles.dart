import 'package:material_ui/material_ui.dart';
import 'package:yamt/core/constants/app_graphit_constants.dart';
import 'package:yamt/core/theme/food_label_colors.dart';

/// Text styles of the Graphit language.
///
/// Weight does the separation: 800 for names and numbers, 600 to 700 for
/// actions and 400 for text.
extension GraphitTextStyles on BuildContext {
  /// Small uppercase caption above a title or a number.
  ///
  /// Callers pass the text in upper case.
  TextStyle? get graphitKickerStyle {
    final colors = FoodLabelColors.of(this);
    return Theme.of(this).textTheme.labelSmall?.copyWith(
      color: colors.muted,
      fontWeight: FontWeight.w600,
      letterSpacing: AppGraphit.kickerTracking,
    );
  }

  /// Display style for names and numbers, built on [base].
  TextStyle? graphitDisplayStyle(TextStyle? base, {Color? color}) {
    final colors = FoodLabelColors.of(this);
    return base?.copyWith(
      fontWeight: FontWeight.w800,
      color: color ?? colors.ink,
      height: AppGraphit.displayLineHeight,
    );
  }
}
