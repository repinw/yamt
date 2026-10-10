import 'package:material_ui/material_ui.dart';
import 'package:yamt/core/constants/app_graphit_constants.dart';
import 'package:yamt/core/constants/app_layout_constants.dart';
import 'package:yamt/core/theme/food_label_colors.dart';

/// The top row of a page that leads through a recipe step by step: a back
/// or close button, a [title] in the middle, and a [caption] at the end,
/// both in small capitals.
class RecipeFlowTopBar extends StatelessWidget {
  /// Creates the row.
  const new({
    required this.onBack,
    required this.title,
    required this.caption,
    this.closes = false,
    this.backKey,
    super.key,
  });

  /// Goes back; `null` turns the button off.
  final VoidCallback? onBack;

  /// The caption in the middle.
  final String title;

  /// The caption at the end.
  final String caption;

  /// Whether the button closes the page instead of going one step back.
  final bool closes;

  /// Key of the back button.
  final Key? backKey;

  @override
  Widget build(BuildContext context) {
    final colors = FoodLabelColors.of(context);
    final materialL10n = MaterialLocalizations.of(context);
    final style = Theme.of(context).textTheme.labelMedium?.copyWith(
      color: colors.muted,
      letterSpacing: AppGraphit.kickerTracking,
    );
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
            key: backKey,
            tooltip: closes
                ? materialL10n.closeButtonTooltip
                : materialL10n.backButtonTooltip,
            onPressed: onBack,
            icon: closes
                ? const Icon(Icons.close_rounded)
                : const BackButtonIcon(),
          ),
          Expanded(
            child: Text(
              title.toUpperCase(),
              textAlign: TextAlign.center,
              style: style,
            ),
          ),
          Text(caption.toUpperCase(), style: style),
        ],
      ),
    );
  }
}
