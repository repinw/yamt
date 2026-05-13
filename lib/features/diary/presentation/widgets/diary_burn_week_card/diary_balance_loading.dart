import 'dart:async';

import 'package:flutter/material.dart';
import 'package:yamt/core/constants/app_layout_constants.dart';
import 'package:yamt/features/diary/presentation/widgets/diary_burn_week_card/diary_balance_card_constants.dart';
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
      child: _DiaryBalanceSkeleton(
        baseColor: baseColor,
        highlightColor: highlightColor,
      ),
    );
  }
}

class _DiaryBalanceSkeleton extends StatefulWidget {
  const _DiaryBalanceSkeleton({
    required this.baseColor,
    required this.highlightColor,
  });

  final Color baseColor;
  final Color highlightColor;

  @override
  State<_DiaryBalanceSkeleton> createState() => _DiaryBalanceSkeletonState();
}

class _DiaryBalanceSkeletonState extends State<_DiaryBalanceSkeleton>
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
      child: const Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          SizedBox(
            height: diaryBalanceProgressAreaHeight,
            child: Align(
              child: _SkeletonBlock(height: diaryBalanceProgressHeight),
            ),
          ),
          SizedBox(height: AppSpacing.md),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              _SkeletonBlock(width: 52, height: 14),
              _SkeletonBlock(width: 86, height: 14),
            ],
          ),
          SizedBox(height: AppSpacing.xxl),
          Row(
            children: [
              Expanded(
                child: _SkeletonBlock(height: diaryBalanceStatTileHeight),
              ),
              SizedBox(width: AppSpacing.md),
              Expanded(
                child: _SkeletonBlock(height: diaryBalanceStatTileHeight),
              ),
            ],
          ),
        ],
      ),
    );
  }

  double boundsWidthMultiplier(double animationValue) {
    return -1 + (animationValue * 2);
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
