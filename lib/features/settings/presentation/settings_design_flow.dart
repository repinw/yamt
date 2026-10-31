import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:material_ui/material_ui.dart';
import 'package:yamt/core/theme/app_custom_colors_controller.dart';
import 'package:yamt/core/theme/app_design_controller.dart';
import 'package:yamt/features/settings/presentation/widgets/settings_custom_colors/settings_custom_base_dialog.dart';

/// Switches the app to [design]. The first switch to "Individuell" asks
/// whether the own colors start as a copy of the light or the dark design;
/// a cancel keeps the current design.
Future<void> selectSettingsDesignFlow(
  BuildContext context,
  WidgetRef ref,
  AppDesign design,
) async {
  if (design == AppDesign.custom &&
      ref.read(appCustomColorsControllerProvider) == null) {
    final base = await showSettingsCustomBaseDialog(context);
    if (base == null || !context.mounted) {
      return;
    }
    await ref.read(appCustomColorsControllerProvider.notifier).start(base);
    if (!context.mounted) {
      return;
    }
  }
  await ref.read(appDesignControllerProvider.notifier).select(design);
}
