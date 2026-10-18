import 'package:intl/intl.dart';
import 'package:material_ui/material_ui.dart';
import 'package:yamt/core/constants/app_layout_constants.dart';
import 'package:yamt/core/theme/food_label_colors.dart';
import 'package:yamt/features/progress/domain/progress_weight_list.dart';
import 'package:yamt/features/progress/presentation/models/progress_weighing_action.dart';
import 'package:yamt/l10n/app_localizations.dart';

/// The sheet of a Health [weighing] that this device cannot change: one of
/// another app, or one this app saved on another device. It ignores the
/// weighing or counts it again, and opens Health for weighings of other
/// apps. Pops the [ProgressWeighingAction].
class ProgressWeighingInfoSheet extends StatelessWidget {
  /// Creates the sheet.
  const new({required this.weighing, super.key});

  /// Key of the ignore or count again button.
  static const ignoreKey = ValueKey<String>('progress-weighing-ignore');

  /// Key of the button that opens Health.
  static const openHealthKey = ValueKey<String>(
    'progress-weighing-open-health',
  );

  /// The weighing, with its Health sample.
  final ProgressWeighing weighing;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final locale = Localizations.localeOf(context).toLanguageTag();
    final textTheme = Theme.of(context).textTheme;
    final muted = FoodLabelColors.of(context).muted;
    final sample = weighing.sample!;
    final ownWeighing = sample.isFromThisApp;
    final at = sample.recordedAt.toLocal();
    void pop(ProgressWeighingAction action) =>
        Navigator.of(context).pop<ProgressWeighingAction>(action);
    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(
          AppSpacing.lg,
          0,
          AppSpacing.lg,
          AppSpacing.lg,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          spacing: AppSpacing.md,
          children: [
            Text(
              ownWeighing
                  ? l10n.progressWeightsSourceManual
                  : sample.sourcePackageName ?? l10n.progressWeightsSourceScale,
              style: textTheme.titleMedium,
            ),
            Text(
              DateFormat.yMEd(locale).add_Hm().format(at),
              style: textTheme.bodyMedium?.copyWith(color: muted),
            ),
            Text(
              l10n.settingsProfileSummaryWeightValue(
                NumberFormat('0.0', locale).format(weighing.weightKg),
              ),
              style: textTheme.headlineSmall?.copyWith(
                fontWeight: FontWeight.w700,
              ),
            ),
            if (ownWeighing)
              Text(
                l10n.progressWeighingOtherDevice,
                style: textTheme.bodySmall?.copyWith(color: muted),
              ),
            Row(
              spacing: AppSpacing.md,
              children: [
                Expanded(
                  child: OutlinedButton(
                    key: ignoreKey,
                    onPressed: () =>
                        pop(ProgressWeighingIgnore(ignored: !sample.isIgnored)),
                    child: Text(
                      sample.isIgnored
                          ? l10n.progressWeighingCount
                          : l10n.progressWeighingIgnore,
                    ),
                  ),
                ),
                if (!ownWeighing)
                  Expanded(
                    child: FilledButton(
                      key: openHealthKey,
                      onPressed: () => pop(const ProgressWeighingOpenHealth()),
                      child: Text(l10n.progressWeighingOpenHealth),
                    ),
                  ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
