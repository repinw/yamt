import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:material_ui/material_ui.dart';
import 'package:yamt/core/constants/app_layout_constants.dart';
import 'package:yamt/core/constants/app_sizes.dart';
import 'package:yamt/core/theme/app_plan_color_controller.dart';
import 'package:yamt/core/theme/food_label_colors.dart';
import 'package:yamt/core/widgets/app_color_picker.dart';
import 'package:yamt/l10n/app_localizations.dart';

/// Shows the plan color sheet. The app takes a new color when a slider is
/// let go; the sheet stays open so the user can keep adjusting.
Future<void> showSettingsPlanColorSheet(BuildContext context) {
  return showModalBottomSheet<void>(
    context: context,
    useRootNavigator: true,
    isScrollControlled: true,
    useSafeArea: true,
    showDragHandle: true,
    builder: (context) => const SettingsPlanColorSheet(),
  );
}

/// A free color picker for the plan color, with a preview swatch and a
/// button back to the default brown.
class SettingsPlanColorSheet extends ConsumerStatefulWidget {
  /// Creates the sheet content.
  const new({super.key});

  /// Key of the preview swatch.
  static const previewKey = ValueKey<String>('settings-plan-color-preview');

  /// Key of the reset button.
  static const resetKey = ValueKey<String>('settings-plan-color-reset');

  @override
  ConsumerState<SettingsPlanColorSheet> createState() =>
      _SettingsPlanColorSheetState();
}

class _SettingsPlanColorSheetState
    extends ConsumerState<SettingsPlanColorSheet> {
  // The color shown in the sheet, set on the first build. The sheet keeps
  // it itself instead of reading the theme, which fades to a new plan color
  // over a moment and would drag the sliders along.
  Color? _shown;

  // Counts resets, so the picker starts over at the default color.
  var _resets = 0;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final color = _shown ??= FoodLabelColors.of(context).plan;

    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(
        AppSpacing.xl,
        0,
        AppSpacing.xl,
        AppSpacing.xxl,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        spacing: AppSpacing.lg,
        children: [
          Row(
            spacing: AppSpacing.lg,
            children: [
              SizedBox.square(
                key: SettingsPlanColorSheet.previewKey,
                dimension: AppSizes.colorPickerPreview,
                child: DecoratedBox(
                  decoration: BoxDecoration(
                    color: color,
                    shape: BoxShape.circle,
                  ),
                ),
              ),
              Expanded(
                child: Text(
                  l10n.settingsPlanColorTitle,
                  style: Theme.of(context).textTheme.titleLarge
                      ?.copyWith(fontWeight: FontWeight.w800),
                ),
              ),
            ],
          ),
          AppColorPicker(
            key: ValueKey(_resets),
            color: color,
            onChanged: (color) => setState(() => _shown = color),
            onChangeEnd: (color) => unawaited(
              ref.read(appPlanColorControllerProvider.notifier).select(color),
            ),
          ),
          Align(
            alignment: AlignmentDirectional.centerStart,
            child: TextButton.icon(
              key: SettingsPlanColorSheet.resetKey,
              onPressed: () {
                final brightness = Theme.of(context).brightness;
                setState(() {
                  _shown = brightness == Brightness.dark
                      ? FoodLabelColors.dark.plan
                      : FoodLabelColors.light.plan;
                  _resets++;
                });
                unawaited(
                  ref.read(appPlanColorControllerProvider.notifier).reset(),
                );
              },
              icon: const Icon(Icons.restart_alt_rounded),
              label: Text(l10n.settingsPlanColorReset),
            ),
          ),
        ],
      ),
    );
  }
}
