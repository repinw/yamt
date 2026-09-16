import 'package:flutter/material.dart';
import 'package:yamt/core/constants/app_layout_constants.dart';
import 'package:yamt/l10n/app_localizations.dart';

/// Loading state for the diary inventory food picker.
class DiaryInventoryFoodPickerLoading extends StatelessWidget {
  /// Creates a loading state.
  const DiaryInventoryFoodPickerLoading({super.key});

  @override
  Widget build(BuildContext context) {
    return const SizedBox(
      height: 180,
      child: Center(child: CircularProgressIndicator()),
    );
  }
}

/// Error state for the diary inventory food picker.
class DiaryInventoryFoodPickerError extends StatelessWidget {
  /// Creates an error state.
  const DiaryInventoryFoodPickerError({required this.onRetry, super.key});

  /// Retries loading picker data.
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;

    return SizedBox(
      height: 180,
      child: Center(
        child: Padding(
          padding: AppInsets.card,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                l10n.inventoryLoadFailed,
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: AppSpacing.md),
              TextButton.icon(
                onPressed: onRetry,
                icon: const Icon(Icons.refresh_rounded),
                label: Text(l10n.inventoryRetryAction),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
