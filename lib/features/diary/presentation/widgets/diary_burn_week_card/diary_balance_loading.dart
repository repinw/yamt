import 'package:material_ui/material_ui.dart';
import 'package:yamt/core/constants/app_budget_card_constants.dart';
import 'package:yamt/core/constants/app_layout_constants.dart';
import 'package:yamt/core/constants/app_sizes.dart';
import 'package:yamt/core/theme/food_label_colors.dart';

/// Loading state for the diary budget card.
class DiaryBalanceLoading extends StatelessWidget {
  /// Creates a loading card.
  const new({super.key});

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    final baseColor = colors.surfaceContainerHigh;
    final highlightColor = colors.surfaceBright;

    return DecoratedBox(
      decoration: BoxDecoration(
        color: FoodLabelColors.of(context).card,
        borderRadius: BorderRadius.circular(AppRadius.xl),
      ),
      child: _ShimmerSkeleton(
        baseColor: baseColor,
        highlightColor: highlightColor,
        child: const _DiaryDailyBalanceSkeleton(),
      ),
    );
  }
}

class _ShimmerSkeleton extends StatefulWidget {
  const new({
    required this.baseColor,
    required this.highlightColor,
    required this.child,
  });

  final Color baseColor;
  final Color highlightColor;
  final Widget child;

  @override
  State<_ShimmerSkeleton> createState() => _ShimmerSkeletonState();
}

class _ShimmerSkeletonState extends State<_ShimmerSkeleton>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1300),
    );
    _controller.repeat();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _controller,
      builder: (context, child) {
        final shaderOffset = boundsWidthMultiplier(_controller.value);

        return ShaderMask(
          blendMode: BlendMode.srcATop,
          shaderCallback: (bounds) {
            return LinearGradient(
              colors: [
                widget.baseColor,
                widget.highlightColor,
                widget.baseColor,
              ],
              stops: const [0.28, 0.5, 0.72],
            ).createShader(
              Rect.fromLTWH(
                bounds.left + (bounds.width * shaderOffset),
                bounds.top,
                bounds.width,
                bounds.height,
              ),
            );
          },
          child: child,
        );
      },
      child: widget.child,
    );
  }

  double boundsWidthMultiplier(double animationValue) {
    return -1 + (animationValue * 2);
  }
}

/// The budget card's shape while it loads: the toggle row, the kcal column
/// with its line and icon buttons, and the three macros.
class _DiaryDailyBalanceSkeleton extends StatelessWidget {
  const new();

  @override
  Widget build(BuildContext context) {
    return const Padding(
      padding: EdgeInsetsDirectional.fromSTEB(
        AppBudgetCard.padding,
        AppBudgetCard.topPadding,
        AppBudgetCard.padding,
        AppBudgetCard.padding,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        spacing: AppBudgetCard.sectionGap,
        children: [
          SizedBox(
            height: AppSizes.minTapTarget,
            child: Row(
              spacing: AppBudgetCard.dayTypeGap,
              children: [
                Flexible(
                  child: _SkeletonBlock(
                    width: 148,
                    height: AppBudgetCard.viewSwitch,
                  ),
                ),
                Spacer(),
                _SkeletonBlock(
                  width: AppBudgetCard.dayButton,
                  height: AppBudgetCard.dayButton,
                ),
                _SkeletonBlock(
                  width: AppBudgetCard.dayButton,
                  height: AppBudgetCard.dayButton,
                ),
              ],
            ),
          ),
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            spacing: AppBudgetCard.columnGap,
            children: [
              Expanded(
                flex: AppBudgetCard.kcalColumnFlex,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  spacing: AppSpacing.xs,
                  children: [
                    _SkeletonBlock(
                      width: 132,
                      height:
                          AppBudgetCard.bigNumber *
                          AppBudgetCard.bigNumberLineHeight,
                    ),
                    _SkeletonBlock(width: 96, height: 14),
                    _SkeletonBlock(height: AppBudgetCard.lineBar),
                    SizedBox(
                      height: AppSizes.minTapTarget,
                      child: Row(
                        spacing: AppSpacing.md,
                        children: [
                          Flexible(
                            child: _SkeletonBlock(
                              width: AppBudgetCard.dayButton,
                              height: AppBudgetCard.dayButton,
                            ),
                          ),
                          Flexible(
                            child: _SkeletonBlock(
                              width: AppBudgetCard.dayButton,
                              height: AppBudgetCard.dayButton,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              Expanded(
                flex: AppBudgetCard.macroColumnFlex,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  spacing: AppBudgetCard.macroGap,
                  children: [
                    _MacroRowSkeleton(),
                    _MacroRowSkeleton(),
                    _MacroRowSkeleton(),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _MacroRowSkeleton extends StatelessWidget {
  const new();

  @override
  Widget build(BuildContext context) {
    return const Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      spacing: AppSpacing.xs,
      children: [
        Row(
          children: [
            Flexible(child: _SkeletonBlock(width: 52, height: 14)),
            Spacer(),
            Flexible(
              child: _SkeletonBlock(
                width: 44,
                height: AppBudgetCard.macroValue,
              ),
            ),
          ],
        ),
        _SkeletonBlock(height: AppBudgetCard.macroLineBar),
      ],
    );
  }
}

class _SkeletonBlock extends StatelessWidget {
  const new({required this.height, this.width});

  final double? width;
  final double height;

  @override
  Widget build(BuildContext context) {
    // The shimmer paints over this block, so only its shape matters. It is
    // round like the budget card's lines and buttons.
    return SizedBox(
      width: width,
      height: height,
      child: DecoratedBox(
        decoration: ShapeDecoration(
          color: Theme.of(context).colorScheme.onSurface,
          shape: const StadiumBorder(),
        ),
      ),
    );
  }
}
