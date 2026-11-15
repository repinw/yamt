import 'package:material_ui/material_ui.dart';
import 'package:yamt/core/constants/app_graphit_constants.dart';
import 'package:yamt/core/constants/app_layout_constants.dart';
import 'package:yamt/core/theme/food_label_colors.dart';

/// The top row of the recipe editor: a close button and a [caption] at the
/// end, in small capitals.
class RecipeFlowTopBar extends StatelessWidget {
  /// Creates the row.
  const new({
    required this.onClose,
    required this.caption,
    required this.closeKey,
    super.key,
  });

  /// Closes the page; `null` turns the button off.
  final VoidCallback? onClose;

  /// The caption at the end.
  final String caption;

  /// Key of the close button.
  final Key closeKey;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(
        AppSpacing.sm,
        AppSpacing.sm,
        AppSpacing.xl,
        0,
      ),
      child: Row(
        children: [
          IconButton(
            key: closeKey,
            tooltip: MaterialLocalizations.of(context).closeButtonTooltip,
            onPressed: onClose,
            icon: const Icon(Icons.close_rounded),
          ),
          // A long caption wraps instead of running out of the row.
          Expanded(
            child: Text(
              caption.toUpperCase(),
              textAlign: TextAlign.end,
              style: Theme.of(context).textTheme.labelMedium?.copyWith(
                color: FoodLabelColors.of(context).muted,
                letterSpacing: AppGraphit.kickerTracking,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
