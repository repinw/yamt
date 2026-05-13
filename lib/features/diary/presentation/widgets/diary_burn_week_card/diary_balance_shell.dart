import 'package:flutter/material.dart';
import 'package:yamt/core/constants/app_layout_constants.dart';
import 'package:yamt/features/diary/presentation/widgets/diary_burn_week_card/diary_balance_card_constants.dart';

/// Outer shell for diary Burn Week card states.
class DiaryBalanceShell extends StatelessWidget {
  /// Creates a Burn Week card shell.
  const DiaryBalanceShell({
    required this.child,
    this.framed = true,
    super.key,
  });

  /// Shell content.
  final Widget child;

  /// Whether to draw the full card frame.
  final bool framed;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    if (!framed) {
      return child;
    }

    return DecoratedBox(
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF111827) : const Color(0xFFEEF2EF),
        borderRadius: BorderRadius.circular(diaryBalanceCardRadius),
        border: Border.all(
          color: isDark ? const Color(0xFF1F2937) : const Color(0xFFDDE6E0),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: isDark ? 0.34 : 0.1),
            blurRadius: isDark ? 26 : 18,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.xxl),
        child: child,
      ),
    );
  }
}
