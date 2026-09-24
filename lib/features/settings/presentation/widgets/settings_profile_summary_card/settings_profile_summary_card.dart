import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:material_ui/material_ui.dart';
import 'package:yamt/core/constants/app_layout_constants.dart';
import 'package:yamt/core/constants/app_sizes.dart';
import 'package:yamt/features/settings/presentation/controllers/profile_summary_controller.dart';
import 'package:yamt/features/settings/presentation/widgets/settings_macro_goals_sheet/settings_macro_goals_sheet.dart';
import 'package:yamt/features/settings/presentation/widgets/settings_profile_summary_card/settings_profile_summary_sections.dart';
import 'package:yamt/features/settings/presentation/widgets/settings_tiles/settings_tiles.dart';
import 'package:yamt/l10n/app_localizations.dart';

/// Profile card of the side menu: name, body data, and current goals, with a
/// button that opens the macro settings.
class SettingsProfileSummaryCard extends ConsumerWidget {
  /// Creates the profile summary card.
  const new({super.key});

  /// Stable key of the button that opens the macro settings.
  static const editMacrosButtonKey = ValueKey<String>(
    'settings-profile-summary-edit-macros-button',
  );

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context)!;
    final summary = ref.watch(profileSummaryControllerProvider);

    return SettingsCard(
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.lg),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            summary.when(
              // Weight data arrives after the goals; keep them on screen.
              skipLoadingOnReload: true,
              data: (state) => SettingsProfileSummarySections(state: state),
              loading: () => const Center(
                child: SizedBox.square(
                  dimension: AppSizes.inlineProgressIndicator,
                  child: CircularProgressIndicator(
                    strokeWidth: AppSizes.progressStrokeWidth,
                  ),
                ),
              ),
              error: (_, _) => Text(
                l10n.settingsProfileSummaryLoadFailed,
                style: Theme.of(context).textTheme.bodyMedium
                    ?.copyWith(color: Theme.of(context).colorScheme.error),
              ),
            ),
            const SizedBox(height: AppSpacing.lg),
            FilledButton.tonalIcon(
              key: editMacrosButtonKey,
              onPressed: () => unawaited(showSettingsMacroGoalsSheet(context)),
              icon: const Icon(Icons.pie_chart_outline_rounded),
              label: Text(l10n.settingsProfileSummaryEditMacrosAction),
            ),
          ],
        ),
      ),
    );
  }
}
