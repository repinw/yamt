import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:yamt/features/diary/presentation/widgets/diary_burn_week_card/diary_balance_card_constants.dart';

/// Shared progress animation duration.
const diaryBalanceProgressAnimationDuration = Duration(milliseconds: 1000);

/// Shared progress animation curve.
const Curve diaryBalanceProgressAnimationCurve = Curves.easeOut;

/// Resolves progress width from layout constraints.
double diaryBalanceProgressWidth(BoxConstraints constraints) {
  if (constraints.hasBoundedWidth && constraints.maxWidth.isFinite) {
    return math.max<double>(0, constraints.maxWidth);
  }
  return diaryBalanceProgressFallbackWidth;
}

/// Converts kcal into a clamped progress ratio.
double diaryBalanceProgressRatioForKcal(double value, double maxKcal) {
  if (maxKcal <= 0) {
    return 0;
  }
  return (value / maxKcal).clamp(0.0, 1.0);
}

/// Resolves visible day-divider color for the current theme.
Color diaryBalanceProgressDividerColor(ColorScheme colors) {
  if (colors.brightness == Brightness.dark) {
    return colors.onSurface.withValues(alpha: 0.52);
  }
  return Colors.white.withValues(alpha: 0.9);
}
