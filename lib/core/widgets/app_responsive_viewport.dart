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

/// Bottom padding that keeps scrollable home-shell content above chrome.
double homeShellPageBottomPadding(BuildContext context) {
  return AppSizes.homeShellBottomBarClearance +
      AppSpacing.xxxxl +
      MediaQuery.paddingOf(context).bottom;
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
