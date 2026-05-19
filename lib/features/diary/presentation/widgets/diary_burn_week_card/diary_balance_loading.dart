import 'dart:async';

import 'package:flutter/material.dart';
import 'package:yamt/core/constants/app_layout_constants.dart';
import 'package:yamt/features/diary/presentation/widgets/diary_burn_week_card/diary_balance_shell.dart';

/// Loading state for the diary Burn Week card.
class DiaryBalanceLoading extends StatelessWidget {
  /// Creates a loading card.
  const DiaryBalanceLoading({super.key});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final baseColor = isDark
        ? const Color(0xFF1F2937)
        : const Color(0xFFDDE6E0);
    final highlightColor = isDark
        ? const Color(0xFF374151)
        : const Color(0xFFF8FAFC);

    return DiaryBalanceShell(
      child: _ShimmerSkeleton(
        baseColor: baseColor,
        highlightColor: highlightColor,
        child: const _DiaryDailyBalanceSkeleton(),
      ),
    );
  }
}

class _ShimmerSkeleton extends StatefulWidget {
  const _ShimmerSkeleton({
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
    unawaited(_controller.repeat());
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
  const _DiaryDailyBalanceSkeleton();

  @override
  Widget build(BuildContext context) {
    return const Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              child: _DailyMetricSkeleton(
                crossAxisAlignment: CrossAxisAlignment.start,
                labelWidth: 54,
                valueWidth: 96,
                subtitleWidth: 76,
              ),
            ),
            SizedBox(width: AppSpacing.xl),
            Expanded(
              child: _DailyMetricSkeleton(
                crossAxisAlignment: CrossAxisAlignment.end,
                labelWidth: 84,
                valueWidth: 118,
                subtitleWidth: 82,
              ),
            ),
          ],
        ),
        SizedBox(height: AppSpacing.md),
        _DailyProgressSkeleton(),
        SizedBox(height: AppSpacing.xl),
        _MacroBarsSkeleton(),
      ],
    );
  }
}

class _DailyMetricSkeleton extends StatelessWidget {
  const _DailyMetricSkeleton({
    required this.crossAxisAlignment,
    required this.labelWidth,
    required this.valueWidth,
    required this.subtitleWidth,
  });

  final CrossAxisAlignment crossAxisAlignment;
  final double labelWidth;
  final double valueWidth;
  final double subtitleWidth;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: crossAxisAlignment,
      children: [
        _SkeletonBlock(width: labelWidth, height: 12),
        const SizedBox(height: AppSpacing.sm),
        _SkeletonBlock(width: valueWidth, height: 34),
        const SizedBox(height: AppSpacing.xs),
        _SkeletonBlock(width: subtitleWidth, height: 12),
      ],
    );
  }
}

class _DailyProgressSkeleton extends StatelessWidget {
  const _DailyProgressSkeleton();

  @override
  Widget build(BuildContext context) {
    return const Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _SkeletonBlock(height: 10),
      ],
    );
  }
}

class _MacroBarsSkeleton extends StatelessWidget {
  const _MacroBarsSkeleton();

  @override
  Widget build(BuildContext context) {
    return const Row(
      children: [
        Expanded(child: _MacroBarSkeleton()),
        SizedBox(width: AppSpacing.xl),
        Expanded(child: _MacroBarSkeleton()),
        SizedBox(width: AppSpacing.xl),
        Expanded(child: _MacroBarSkeleton()),
      ],
    );
  }
}

class _MacroBarSkeleton extends StatelessWidget {
  const _MacroBarSkeleton();

  @override
  Widget build(BuildContext context) {
    return const Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _SkeletonBlock(width: 48, height: 12),
        SizedBox(height: AppSpacing.xs),
        _SkeletonBlock(height: 8),
        SizedBox(height: AppSpacing.xs),
        _SkeletonBlock(width: 64, height: 12),
      ],
    );
  }
}

class _SkeletonBlock extends StatelessWidget {
  const _SkeletonBlock({required this.height, this.width});

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
