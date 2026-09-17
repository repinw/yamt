import 'package:material_ui/material_ui.dart';
import 'package:yamt/core/widgets/app_responsive_viewport.dart';

const _compactHomeChromeTextScaleThreshold = 1.15;

double _effectiveTextScale(
  BuildContext context, {
  double referenceFontSize = 14,
}) {
  return MediaQuery.textScalerOf(context).scale(referenceFontSize) /
      referenceFontSize;
}

/// Whether shared home chrome should switch to its compact layout.
bool shouldUseCompactHomeChrome(BuildContext context) {
  return isCompactViewport(context) ||
      _effectiveTextScale(context) > _compactHomeChromeTextScaleThreshold;
}

/// Tabs shown in the shared home shell.
enum HomeTabType {
  /// Inventory.
  inventory,

  /// Diary.
  diary,

  /// Cookbook.
  cookbook,

  /// Progress.
  progress,
}
