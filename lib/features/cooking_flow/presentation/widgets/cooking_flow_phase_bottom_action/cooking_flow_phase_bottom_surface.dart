import 'package:material_ui/material_ui.dart';
import 'package:yamt/core/constants/app_layout_constants.dart';
import 'package:yamt/core/theme/food_label_colors.dart';
import 'package:yamt/core/widgets/app_responsive_viewport.dart';

/// Paper bar with a top rule that holds the bottom actions of a phase.
class CookingFlowPhaseBottomSurface extends StatelessWidget {
  /// Creates the bar.
  const new({required this.child, super.key});

  /// Actions of the bar.
  final Widget child;

  @override
  Widget build(BuildContext context) {
    final colors = FoodLabelColors.of(context);
    final horizontalInset = responsivePageHorizontalPadding(context);

    return DecoratedBox(
      decoration: BoxDecoration(
        color: colors.paper,
        border: Border(top: BorderSide(color: colors.rule)),
      ),
      child: SafeArea(
        top: false,
        child: Padding(
          padding: EdgeInsets.fromLTRB(
            horizontalInset,
            AppSpacing.md,
            horizontalInset,
            AppSpacing.md,
          ),
          child: child,
        ),
      ),
    );
  }
}
