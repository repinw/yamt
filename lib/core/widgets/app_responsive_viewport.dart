import 'package:material_ui/material_ui.dart';
import 'package:yamt/core/constants/app_layout_constants.dart';
import 'package:yamt/core/constants/app_sizes.dart';

const _compactViewportWidthBreakpoint = 360.0;

/// Whether the effective logical viewport is tight enough for compact layout.
bool isCompactViewport(BuildContext context) {
  return MediaQuery.sizeOf(context).width < _compactViewportWidthBreakpoint;
}

/// Shared page horizontal padding that eases cramped display-size layouts.
double responsivePageHorizontalPadding(BuildContext context) {
  return isCompactViewport(context) ? AppSpacing.md : AppSpacing.xl;
}

/// Height of a tab's dock that sits on the home navigation bar.
const double homeShellDockHeight = AppSpacing.md * 2 + AppSizes.headerTool;

/// Bottom padding that keeps scrollable home-shell content above chrome.
/// A tab with a dock passes [hasDock], so its last row clears the dock too.
double homeShellPageBottomPadding(
  BuildContext context, {
  bool hasDock = false,
}) {
  return AppSizes.homeShellBottomBarClearance +
      AppSpacing.xxxxl +
      (hasDock ? homeShellDockHeight : 0) +
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
