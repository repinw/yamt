import 'package:material_ui/material_ui.dart';
import 'package:yamt/core/constants/app_food_label_constants.dart';
import 'package:yamt/core/constants/app_layout_constants.dart';

/// Loading state for the diary Burn Week card.
class DiaryBalanceLoading extends StatelessWidget {
  /// Creates a loading card.
  const new({super.key});

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    final baseColor = colors.surfaceContainerHigh;
    final highlightColor = colors.surfaceBright;

    return _ShimmerSkeleton(
      baseColor: baseColor,
      highlightColor: highlightColor,
      child: const _DiaryDailyBalanceSkeleton(),
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

class _DiaryDailyBalanceSkeleton extends StatelessWidget {
  const new();

  @override
  Widget build(BuildContext context) {
    return const Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _SkeletonBlock(width: 96, height: 12),
        SizedBox(height: AppSpacing.xs),
        _SkeletonBlock(width: 160, height: 56),
        SizedBox(height: AppSpacing.lg),
        _SkeletonBlock(height: AppFoodLabel.rulerTicks + AppFoodLabel.kcalBar),
        SizedBox(height: AppSpacing.xl),
        _MacroRowSkeleton(),
        SizedBox(height: AppSpacing.sm),
        _MacroRowSkeleton(),
        SizedBox(height: AppSpacing.sm),
        _MacroRowSkeleton(),
      ],
    );
  }
}

class _MacroRowSkeleton extends StatelessWidget {
  const new();

  @override
  Widget build(BuildContext context) {
    return const Row(
      spacing: AppSpacing.md,
      children: [
        _SkeletonBlock(width: AppFoodLabel.macroLabelColumn, height: 16),
        Expanded(child: _SkeletonBlock(height: AppFoodLabel.macroBar)),
        _SkeletonBlock(width: AppFoodLabel.macroValueColumn, height: 22),
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
    return Container(
      width: width,
      height: height,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(height / 2),
      ),
    );
  }
}
