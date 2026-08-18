import 'dart:async';

import 'package:flutter/material.dart';
import 'package:yamt/core/constants/app_layout_constants.dart';
import 'package:yamt/core/widgets/app_haptic_feedback.dart';

/// Interactive horizontal radio-tuner dial wheel for numeric selection.
class HorizontalDialWheel extends StatefulWidget {
  /// Creates horizontal dial wheel.
  const HorizontalDialWheel({
    required this.value,
    required this.minValue,
    required this.maxValue,
    required this.onChanged,
    this.step = 1,
    this.majorInterval = 5,
    this.itemWidth = 16.0,
    this.height = 68.0,
    super.key,
  });

  /// Currently selected value.
  final int value;

  /// Minimum value.
  final int minValue;

  /// Maximum value.
  final int maxValue;

  /// Step size.
  final int step;

  /// Interval between labeled major ticks.
  final int majorInterval;

  /// Width per tick item in logical pixels.
  final double itemWidth;

  /// Height of the dial wheel component.
  final double height;

  /// Callback when user selects a new value.
  final ValueChanged<int> onChanged;

  @override
  State<HorizontalDialWheel> createState() => _HorizontalDialWheelState();
}

class _HorizontalDialWheelState extends State<HorizontalDialWheel> {
  late final ScrollController _scrollController;
  late int _currentValue;
  bool _isUserScrolling = false;
  double _lastViewportWidth = 0;

  int get _itemCount =>
      ((widget.maxValue - widget.minValue) ~/ widget.step) + 1;

  @override
  void initState() {
    super.initState();
    _currentValue = widget.value.clamp(widget.minValue, widget.maxValue);
    _scrollController = ScrollController();
  }

  @override
  void didUpdateWidget(HorizontalDialWheel oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.value != _currentValue && !_isUserScrolling) {
      _currentValue = widget.value.clamp(widget.minValue, widget.maxValue);
      _scrollToValue(_currentValue, animate: true);
    }
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  void _scrollToValue(int value, {required bool animate}) {
    if (!_scrollController.hasClients) return;
    final index = (value - widget.minValue) ~/ widget.step;
    final target = index * widget.itemWidth;
    if (animate) {
      unawaited(
        _scrollController.animateTo(
          target,
          duration: const Duration(milliseconds: 200),
          curve: Curves.easeOutCubic,
        ),
      );
    } else {
      _scrollController.jumpTo(target);
    }
  }

  bool _onScrollNotification(ScrollNotification notification) {
    if (notification is ScrollStartNotification) {
      _isUserScrolling = true;
    } else if (notification is ScrollUpdateNotification) {
      final index = (_scrollController.offset / widget.itemWidth).round();
      final clampedIndex = index.clamp(0, _itemCount - 1);
      final newValue = widget.minValue + clampedIndex * widget.step;
      if (newValue != _currentValue) {
        _currentValue = newValue;
        AppHapticFeedback.selectionClick();
        widget.onChanged(newValue);
      }
    } else if (notification is ScrollEndNotification) {
      _isUserScrolling = false;
      final index = (_scrollController.offset / widget.itemWidth).round();
      final clampedIndex = index.clamp(0, _itemCount - 1);
      final target = clampedIndex * widget.itemWidth;
      if ((_scrollController.offset - target).abs() > 0.5) {
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (mounted && _scrollController.hasClients) {
            unawaited(
              _scrollController.animateTo(
                target,
                duration: const Duration(milliseconds: 150),
                curve: Curves.easeOutCubic,
              ),
            );
          }
        });
      }
    }
    return false;
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final bgColor = colorScheme.surfaceContainerHighest.withValues(alpha: 0.35);

    return LayoutBuilder(
      builder: (context, constraints) {
        final viewportWidth = constraints.maxWidth;
        if (viewportWidth > 0 && viewportWidth != _lastViewportWidth) {
          _lastViewportWidth = viewportWidth;
          WidgetsBinding.instance.addPostFrameCallback((_) {
            if (mounted) {
              _scrollToValue(_currentValue, animate: false);
            }
          });
        }

        final sidePadding = (viewportWidth - widget.itemWidth) / 2;

        return Container(
          height: widget.height,
          decoration: BoxDecoration(
            color: bgColor,
            borderRadius: BorderRadius.circular(AppRadius.md),
            border: Border.all(
              color: colorScheme.outlineVariant.withValues(alpha: 0.5),
            ),
          ),
          clipBehavior: Clip.antiAlias,
          child: Stack(
            alignment: Alignment.center,
            children: [
              _DialRuler(
                scrollController: _scrollController,
                itemCount: _itemCount,
                itemWidth: widget.itemWidth,
                minValue: widget.minValue,
                step: widget.step,
                majorInterval: widget.majorInterval,
                sidePadding: sidePadding > 0 ? sidePadding : 0,
                onScrollNotification: _onScrollNotification,
              ),
              const _DialCenterNeedle(),
              _DialEdgeFades(backgroundColor: bgColor),
            ],
          ),
        );
      },
    );
  }
}

class _DialRuler extends StatelessWidget {
  const _DialRuler({
    required this.scrollController,
    required this.itemCount,
    required this.itemWidth,
    required this.minValue,
    required this.step,
    required this.majorInterval,
    required this.sidePadding,
    required this.onScrollNotification,
  });

  final ScrollController scrollController;
  final int itemCount;
  final double itemWidth;
  final int minValue;
  final int step;
  final int majorInterval;
  final double sidePadding;
  final NotificationListenerCallback<ScrollNotification> onScrollNotification;

  @override
  Widget build(BuildContext context) {
    return NotificationListener<ScrollNotification>(
      onNotification: onScrollNotification,
      child: ListView.builder(
        controller: scrollController,
        scrollDirection: Axis.horizontal,
        physics: const BouncingScrollPhysics(),
        padding: EdgeInsets.symmetric(horizontal: sidePadding),
        itemCount: itemCount,
        itemExtent: itemWidth,
        itemBuilder: (context, index) {
          final tickValue = minValue + index * step;
          final isMajor = tickValue % majorInterval == 0;
          return _DialTickItem(
            value: tickValue,
            isMajor: isMajor,
            width: itemWidth,
          );
        },
      ),
    );
  }
}

class _DialTickItem extends StatelessWidget {
  const _DialTickItem({
    required this.value,
    required this.isMajor,
    required this.width,
  });

  final int value;
  final bool isMajor;
  final double width;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return SizedBox(
      width: width,
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            width: isMajor ? 2.0 : 1.2,
            height: isMajor ? 18.0 : 10.0,
            decoration: BoxDecoration(
              color: isMajor
                  ? colorScheme.onSurfaceVariant
                  : colorScheme.outlineVariant,
              borderRadius: BorderRadius.circular(AppRadius.xs),
            ),
          ),
          const SizedBox(height: AppSpacing.xxs),
          SizedBox(
            height: 14,
            child: isMajor
                ? Text(
                    '$value',
                    style: TextStyle(
                      fontSize: AppFontSizes.labelSmall,
                      height: 1.1,
                      fontWeight: FontWeight.w600,
                      color: colorScheme.onSurfaceVariant,
                    ),
                  )
                : null,
          ),
        ],
      ),
    );
  }
}

class _DialCenterNeedle extends StatelessWidget {
  const _DialCenterNeedle();

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return IgnorePointer(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            width: 8,
            height: 4,
            decoration: BoxDecoration(
              color: colorScheme.primary,
              borderRadius: const BorderRadius.vertical(
                bottom: Radius.circular(AppRadius.xs),
              ),
            ),
          ),
          Container(
            width: 3,
            height: 32,
            decoration: BoxDecoration(
              color: colorScheme.primary,
              borderRadius: BorderRadius.circular(AppRadius.xs),
              boxShadow: [
                BoxShadow(
                  color: colorScheme.primary.withValues(alpha: 0.35),
                  blurRadius: 4,
                  spreadRadius: 1,
                ),
              ],
            ),
          ),
          const SizedBox(height: 14),
        ],
      ),
    );
  }
}

class _DialEdgeFades extends StatelessWidget {
  const _DialEdgeFades({required this.backgroundColor});

  final Color backgroundColor;

  @override
  Widget build(BuildContext context) {
    final transparent = backgroundColor.withValues(alpha: 0);

    return IgnorePointer(
      child: Row(
        children: [
          Container(
            width: 48,
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [backgroundColor, transparent],
              ),
            ),
          ),
          const Spacer(),
          Container(
            width: 48,
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [transparent, backgroundColor],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
