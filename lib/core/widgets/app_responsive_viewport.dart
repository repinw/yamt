import 'package:flutter/material.dart';
import 'package:yamt/core/constants/app_ui_constants.dart';

const _compactViewportWidthBreakpoint = 360.0;

/// Whether the effective logical viewport is tight enough for compact layout.
bool isCompactViewport(BuildContext context) {
  return MediaQuery.sizeOf(context).width < _compactViewportWidthBreakpoint;
}

/// Shared page horizontal padding that eases cramped display-size layouts.
double responsivePageHorizontalPadding(BuildContext context) {
  return isCompactViewport(context) ? AppSpacing.md : AppSpacing.xl;
}

/// Shared page/list padding for scrollable screens.
EdgeInsets responsivePagePadding(
  BuildContext context, {
  required double top,
  required double bottom,
}) {
  final horizontal = responsivePageHorizontalPadding(context);
  return EdgeInsets.fromLTRB(horizontal, top, horizontal, bottom);
}

/// Shared card padding for compact and regular layouts.
EdgeInsets responsiveCardPadding(
  BuildContext context, {
  double compact = AppSpacing.lg,
  double regular = AppSpacing.xl,
}) {
  final inset = isCompactViewport(context) ? compact : regular;
  return EdgeInsets.all(inset);
}

/// Adds app-level responsive adjustments for dense mobile layouts.
class AppResponsiveViewport extends StatelessWidget {
  /// Creates the responsive viewport wrapper.
  const AppResponsiveViewport({required this.child, super.key});

  /// The wrapped subtree.
  final Widget child;

  @override
  Widget build(BuildContext context) {
    final wrappedChild = Builder(
      builder: (context) {
        final theme = Theme.of(context);
        if (!isCompactViewport(context)) {
          return child;
        }
        return Theme(
          data: theme.copyWith(visualDensity: VisualDensity.compact),
          child: child,
        );
      },
    );

    return MediaQuery.withClampedTextScaling(
      maxScaleFactor: 1.2,
      child: wrappedChild,
    );
  }
}
