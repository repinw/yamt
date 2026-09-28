import 'package:material_ui/material_ui.dart';
import 'package:yamt/core/constants/app_graphit_constants.dart';
import 'package:yamt/core/theme/food_label_colors.dart';

/// Stable finder key for cookflow phase progress.
const Key cookingFlowProgressIndicatorKey = ValueKey<String>(
  'cookflow_progress_indicator',
);

/// Step progress of the cooking flow: one square segment per phase.
///
/// Finished and current segments are ink, the rest use the rule color. The
/// segments are square because they show state; nothing here is tapped.
class CookingFlowProgressIndicator extends StatelessWidget {
  /// Creates progress indicator.
  const new({
    required this.activeIndex,
    required this.semanticLabel,
    this.count = 4,
    super.key = cookingFlowProgressIndicatorKey,
  });

  /// Active zero-based phase index.
  final int activeIndex;

  /// Total segments.
  final int count;

  /// Localized accessibility label.
  final String semanticLabel;

  @override
  Widget build(BuildContext context) {
    final colors = FoodLabelColors.of(context);

    return Semantics(
      label: semanticLabel,
      child: Row(
        mainAxisSize: MainAxisSize.min,
        spacing: AppGraphit.progressSegmentGap,
        children: <Widget>[
          for (var index = 0; index < count; index++)
            AnimatedContainer(
              duration: AppGraphit.stateChange,
              curve: Curves.easeOutCubic,
              width: AppGraphit.progressSegmentWidth,
              height: AppGraphit.progressSegmentHeight,
              color: index <= activeIndex ? colors.ink : colors.rule,
            ),
        ],
      ),
    );
  }
}
