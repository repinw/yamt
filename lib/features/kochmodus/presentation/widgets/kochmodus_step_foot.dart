import 'package:material_ui/material_ui.dart';
import 'package:yamt/core/constants/app_graphit_constants.dart';
import 'package:yamt/core/constants/app_layout_constants.dart';
import 'package:yamt/core/theme/food_label_colors.dart';

/// The foot of a cooking step under a rule: switches, hints and the
/// buttons, stacked, above the system bar.
class KochmodusStepFoot extends StatelessWidget {
  /// Creates the foot with [children] from top to bottom.
  const new({required this.children, super.key});

  /// The content, such as "Später" above the main button.
  final List<Widget> children;

  /// The style of the main button of a step and of a cooking sheet: full
  /// width in the accent color.
  static ButtonStyle mainButtonStyle(BuildContext context) {
    final colors = FoodLabelColors.of(context);
    return FilledButton.styleFrom(
      backgroundColor: colors.accent,
      foregroundColor: colors.onAccent,
      minimumSize: const Size.fromHeight(AppGraphit.buttonHeight),
    );
  }

  @override
  Widget build(BuildContext context) => DecoratedBox(
    decoration: BoxDecoration(
      border: Border(top: BorderSide(color: FoodLabelColors.of(context).rule)),
    ),
    child: SafeArea(
      top: false,
      child: Padding(
        padding: AppInsets.page,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          spacing: AppSpacing.sm,
          children: children,
        ),
      ),
    ),
  );
}
