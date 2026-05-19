import 'package:flutter/material.dart';
import 'package:yamt/core/constants/app_layout_constants.dart';
import 'package:yamt/core/theme/app_theme_tokens.dart';
import 'package:yamt/l10n/app_localizations.dart';

/// Error state card for the cookbook page.
class MealTemplatesErrorState extends StatelessWidget {
  /// Creates the error state widget.
  const MealTemplatesErrorState({
    required this.onRetry,
    super.key,
  });

  /// Action when retry is pressed.
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    final l10n = AppLocalizations.of(context)!;
    final borderRadius = BorderRadius.circular(AppEditorial.cardRadius);

    return Center(
      child: Padding(
        padding: AppInsets.pageLarge,
        child: DecoratedBox(
          decoration: AppEditorialSurfaces.liftedCardDecoration(
            colors,
            borderRadius: borderRadius,
          ),
          child: Padding(
            padding: const EdgeInsets.symmetric(
              horizontal: AppSpacing.xl,
              vertical: AppSpacing.xxl,
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: <Widget>[
                Icon(
                  Icons.wifi_tethering_error_rounded,
                  color: colors.error,
                  size: 48,
                ),
                const SizedBox(height: AppSpacing.lg),
                Text(
                  l10n.preparedMealTemplatesLoadFailed,
                  textAlign: TextAlign.center,
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        color: colors.onSurfaceVariant,
                        height: 1.5,
                      ),
                ),
                const SizedBox(height: AppSpacing.xl),
                FilledButton.icon(
                  onPressed: onRetry,
                  icon: const Icon(Icons.refresh),
                  label: Text(l10n.inventoryRetryAction),
                  style: FilledButton.styleFrom(
                    backgroundColor: colors.error,
                    foregroundColor: colors.onError,
                    padding: const EdgeInsets.symmetric(
                      horizontal: AppSpacing.lg,
                      vertical: AppSpacing.md,
                    ),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(AppRadius.lg),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
