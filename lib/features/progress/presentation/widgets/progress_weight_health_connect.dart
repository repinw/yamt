import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:material_ui/material_ui.dart';
import 'package:yamt/core/constants/app_layout_constants.dart';
import 'package:yamt/core/theme/food_label_colors.dart';
import 'package:yamt/features/health/application/health_connection_controller.dart';
import 'package:yamt/features/health/domain/health_connection_models.dart';
import 'package:yamt/features/progress/presentation/controllers/progress_weight_health_hint_controller.dart';
import 'package:yamt/features/progress/presentation/progress_weight_health_connect_flow.dart';
import 'package:yamt/l10n/app_localizations.dart';

/// Whether Health could be connected but is not yet.
bool _canConnect(WidgetRef ref) {
  final state = ref
      .watch(healthConnectionControllerProvider)
      .value
      ?.accessState;
  return switch (state) {
    HealthDataAccessState.installRequired ||
    HealthDataAccessState.permissionRequired ||
    HealthDataAccessState.historyRequired => true,
    _ => false,
  };
}

/// The card that offers to take the scale's weights from Health, until the
/// user dismisses it.
class ProgressWeightHealthCard extends ConsumerWidget {
  /// Creates the card.
  const new({super.key});

  /// Stable key of the card.
  static const cardKey = ValueKey<String>('progress-weights-health-card');

  /// Stable key of the dismiss button.
  static const dismissKey = ValueKey<String>('progress-weights-health-dismiss');

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    if (!_canConnect(ref) ||
        !ref.watch(progressWeightHealthHintControllerProvider)) {
      return const SizedBox.shrink();
    }
    final l10n = AppLocalizations.of(context)!;
    final colors = FoodLabelColors.of(context);
    final textTheme = Theme.of(context).textTheme;
    return Container(
      key: cardKey,
      padding: AppInsets.card,
      color: colors.card,
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              spacing: AppSpacing.xs,
              children: [
                Text(
                  l10n.progressWeightsHealthTitle,
                  style: textTheme.titleSmall?.copyWith(
                    fontWeight: FontWeight.w700,
                  ),
                ),
                Text(
                  l10n.progressWeightsHealthBody,
                  style: textTheme.bodySmall?.copyWith(color: colors.muted),
                ),
                FilledButton(
                  onPressed: () =>
                      unawaited(connectProgressWeightHealth(context, ref)),
                  child: Text(l10n.progressWeightsHealthConnect),
                ),
              ],
            ),
          ),
          IconButton(
            key: dismissKey,
            tooltip: l10n.progressWeightsHealthDismiss,
            onPressed: () => unawaited(
              ref
                  .read(progressWeightHealthHintControllerProvider.notifier)
                  .dismiss(),
            ),
            icon: const Icon(Icons.close_rounded),
          ),
        ],
      ),
    );
  }
}

/// The small header icon that connects Health once the card is dismissed.
class ProgressWeightHealthButton extends ConsumerWidget {
  /// Creates the button.
  const new({super.key});

  /// Stable key of the button.
  static const buttonKey = ValueKey<String>('progress-weights-health-icon');

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    if (!_canConnect(ref) ||
        ref.watch(progressWeightHealthHintControllerProvider)) {
      return const SizedBox.shrink();
    }
    return IconButton(
      key: buttonKey,
      tooltip: AppLocalizations.of(context)!.progressWeightsHealthConnect,
      onPressed: () => unawaited(connectProgressWeightHealth(context, ref)),
      icon: const Icon(Icons.favorite_border_rounded),
    );
  }
}
