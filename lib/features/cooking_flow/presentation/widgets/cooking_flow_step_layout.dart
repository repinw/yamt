import 'package:material_ui/material_ui.dart';
import 'package:yamt/core/constants/app_layout_constants.dart';
import 'package:yamt/core/theme/food_label_colors.dart';
import 'package:yamt/core/theme/graphit_text_styles.dart';
import 'package:yamt/core/widgets/app_responsive_viewport.dart';

const _cookflowMaxContentWidth = 560.0;

/// Shared layout wrapper for Cookflow step screens.
class CookingFlowStepLayout extends StatelessWidget {
  /// Creates shared Cookflow step layout.
  const new({
    required this.title,
    required this.subtitle,
    required this.children,
    this.bottomPinnedChild,
    this.bottomPinnedChildHeight = 0,
    super.key,
  });

  /// Step title.
  final String title;

  /// Step subtitle.
  final String subtitle;

  /// Step content widgets shown under title.
  final List<Widget> children;

  /// Optional child pinned above the cookflow action bar.
  final Widget? bottomPinnedChild;

  /// Space reserved for the pinned child inside scroll content.
  final double bottomPinnedChildHeight;

  @override
  Widget build(BuildContext context) {
    final colors = FoodLabelColors.of(context);
    final textTheme = Theme.of(context).textTheme;
    final bottomPadding =
        homeShellPageBottomPadding(context) + bottomPinnedChildHeight;
    final scrollView = SingleChildScrollView(
      padding: responsivePagePadding(
        context,
        top: AppSpacing.xl,
        bottom: bottomPadding,
      ),
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: _cookflowMaxContentWidth),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              Text(
                title,
                style: context.graphitDisplayStyle(textTheme.headlineMedium),
              ),
              const SizedBox(height: AppSpacing.md),
              Text(
                subtitle,
                style: textTheme.bodyMedium?.copyWith(color: colors.muted),
              ),
              const SizedBox(height: AppSpacing.xxxl),
              ...children,
            ],
          ),
        ),
      ),
    );

    if (bottomPinnedChild == null) {
      return scrollView;
    }

    return Stack(
      children: <Widget>[
        Positioned.fill(child: scrollView),
        Align(
          alignment: Alignment.bottomCenter,
          child: Padding(
            padding: EdgeInsets.fromLTRB(
              responsivePageHorizontalPadding(context),
              0,
              responsivePageHorizontalPadding(context),
              AppSpacing.lg + MediaQuery.viewInsetsOf(context).bottom,
            ),
            child: ConstrainedBox(
              constraints: const BoxConstraints(
                maxWidth: _cookflowMaxContentWidth,
              ),
              child: bottomPinnedChild,
            ),
          ),
        ),
      ],
    );
  }
}
