import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:material_ui/material_ui.dart';
import 'package:yamt/core/constants/app_layout_constants.dart';
import 'package:yamt/core/constants/app_sizes.dart';
import 'package:yamt/core/theme/app_accent.dart';
import 'package:yamt/core/theme/app_accent_controller.dart';
import 'package:yamt/core/theme/food_label_colors.dart';
import 'package:yamt/core/widgets/app_ink_well.dart';
import 'package:yamt/l10n/app_localizations.dart';

/// Shows the accent color sheet. A tap on a swatch recolors the app at once;
/// the sheet stays open so the user can try the next color.
Future<void> showSettingsAccentSheet(BuildContext context) {
  return showModalBottomSheet<void>(
    context: context,
    useRootNavigator: true,
    isScrollControlled: true,
    useSafeArea: true,
    showDragHandle: true,
    builder: (context) => const SettingsAccentSheet(),
  );
}

/// Name of [accent] in the user's language.
String settingsAccentLabel(AppLocalizations l10n, AppAccent accent) {
  return switch (accent) {
    AppAccent.lime => l10n.settingsAccentLime,
    AppAccent.pink => l10n.settingsAccentPink,
    AppAccent.violet => l10n.settingsAccentViolet,
    AppAccent.cyan => l10n.settingsAccentCyan,
    AppAccent.emerald => l10n.settingsAccentEmerald,
  };
}

/// Round swatches for every accent, the current one with a check mark.
class SettingsAccentSheet extends ConsumerWidget {
  /// Creates the sheet content.
  const new({super.key});

  /// Key of the swatch for [accent].
  static Key swatchKey(AppAccent accent) =>
      Key('settings_accent_swatch_${accent.name}');

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context)!;
    final current = ref.watch(appAccentControllerProvider);

    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(
        AppSpacing.xl,
        0,
        AppSpacing.xl,
        AppSpacing.xxl,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Padding(
            padding: const EdgeInsets.only(bottom: AppSpacing.lg),
            child: Text(
              l10n.settingsAccentTitle,
              style: Theme.of(context).textTheme.titleLarge
                  ?.copyWith(fontWeight: FontWeight.w800),
            ),
          ),
          Wrap(
            spacing: AppSpacing.lg,
            runSpacing: AppSpacing.md,
            children: [
              for (final accent in AppAccent.values)
                _AccentSwatch(
                  key: swatchKey(accent),
                  accent: accent,
                  label: settingsAccentLabel(l10n, accent),
                  isSelected: accent == current,
                  onTap: () => unawaited(
                    ref
                        .read(appAccentControllerProvider.notifier)
                        .select(accent),
                  ),
                ),
            ],
          ),
        ],
      ),
    );
  }
}

class _AccentSwatch extends StatelessWidget {
  const new({
    required this.accent,
    required this.label,
    required this.isSelected,
    required this.onTap,
    super.key,
  });

  final AppAccent accent;
  final String label;
  final bool isSelected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colors = FoodLabelColors.of(context);
    final fill = accent.tonesFor(theme.brightness).fill;

    return Semantics(
      button: true,
      selected: isSelected,
      child: AppInkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(AppRadius.md),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          spacing: AppSpacing.xs,
          children: [
            SizedBox.square(
              dimension: AppSizes.minTapTarget,
              child: DecoratedBox(
                decoration: BoxDecoration(color: fill, shape: BoxShape.circle),
                // The selected swatch is the theme's accent, so the theme's
                // text-on-accent color reads on it.
                child: isSelected
                    ? Icon(Icons.check_rounded, color: colors.onAccent)
                    : null,
              ),
            ),
            Text(
              label,
              style: theme.textTheme.labelMedium?.copyWith(
                color: isSelected ? colors.ink : colors.muted,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
