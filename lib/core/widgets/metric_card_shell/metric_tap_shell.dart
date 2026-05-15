import 'package:flutter/material.dart';
import 'package:yamt/core/widgets/app_ink_well.dart';

/// Tap shell for compact metric cards.
class MetricTapShell extends StatelessWidget {
  /// Creates a tappable metric shell.
  const MetricTapShell({
    required this.onTap,
    required this.child,
    super.key,
  });

  /// Called when the card is tapped.
  final VoidCallback onTap;

  /// Card content.
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      borderRadius: BorderRadius.circular(24),
      child: AppInkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(24),
        child: child,
      ),
    );
  }
}
