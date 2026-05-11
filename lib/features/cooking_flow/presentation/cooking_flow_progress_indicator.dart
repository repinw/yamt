import 'package:flutter/material.dart';
import 'package:smooth_page_indicator/smooth_page_indicator.dart';
import 'package:yamt/core/theme/app_theme_tokens.dart';

/// Stable finder key for cookflow phase progress.
const Key cookingFlowProgressIndicatorKey = ValueKey<String>(
  'cookflow_progress_indicator',
);

/// Dot progress indicator for cookflow phases.
class CookingFlowProgressIndicator extends StatelessWidget {
  /// Creates progress indicator.
  const CookingFlowProgressIndicator({
    required this.activeIndex,
    required this.semanticLabel,
    this.count = 4,
    super.key = cookingFlowProgressIndicatorKey,
  });

  /// Active zero-based phase index.
  final int activeIndex;

  /// Total indicator dots.
  final int count;

  /// Localized accessibility label.
  final String semanticLabel;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;

    return Semantics(
      label: semanticLabel,
      child: AnimatedSmoothIndicator(
        activeIndex: activeIndex,
        count: count,
        duration: const Duration(milliseconds: 240),
        curve: Curves.easeOutCubic,
        effect: ExpandingDotsEffect(
          expansionFactor: 3.2,
          dotWidth: 7,
          dotHeight: 7,
          spacing: 5,
          radius: 7,
          activeDotColor: AppSeedColors.orange,
          dotColor: colors.outlineVariant,
        ),
      ),
    );
  }
}
