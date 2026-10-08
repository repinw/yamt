import 'package:material_ui/material_ui.dart';
import 'package:yamt/core/constants/app_layout_constants.dart';
import 'package:yamt/core/theme/food_label_colors.dart';
import 'package:yamt/core/theme/graphit_text_styles.dart';

/// The top line of the "Gekocht" step: a close button and the [kicker].
class CookedMealHeader extends StatelessWidget {
  /// Creates the header.
  const new({required this.kicker, required this.onClose, super.key});

  /// Short name of the step, shown in capitals.
  final String kicker;

  /// Closes the step.
  final VoidCallback onClose;

  @override
  Widget build(BuildContext context) {
    final colors = FoodLabelColors.of(context);
    return Padding(
      padding: const EdgeInsets.fromLTRB(
        AppSpacing.xs,
        AppSpacing.sm,
        AppSpacing.xxl,
        0,
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          IconButton(
            tooltip: MaterialLocalizations.of(context).closeButtonTooltip,
            onPressed: onClose,
            icon: Icon(Icons.close_rounded, color: colors.ink),
          ),
          Text(kicker.toUpperCase(), style: context.graphitKickerStyle),
        ],
      ),
    );
  }
}
