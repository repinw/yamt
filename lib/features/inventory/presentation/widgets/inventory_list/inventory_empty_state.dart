import 'package:material_ui/material_ui.dart';
import 'package:yamt/core/constants/app_layout_constants.dart';
import 'package:yamt/l10n/app_localizations.dart';

/// Card shown when the Vorrat or the filtered list is empty.
class InventoryEmptyState extends StatelessWidget {
  /// The inventory empty state.
  const new({super.key, this.message});

  /// The message.
  final String? message;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    final l10n = AppLocalizations.of(context)!;
    final emptyStateMessage = message ?? l10n.inventoryEmptyState;
    final cardRadius = BorderRadius.circular(AppRadius.xl);

    return DecoratedBox(
      decoration: BoxDecoration(
        color: colors.surfaceContainerLow,
        borderRadius: cardRadius,
        border: Border.all(color: colors.outlineVariant),
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.xxxl,
          vertical: AppSpacing.xxxxl,
        ),
        child: Text(
          emptyStateMessage,
          textAlign: TextAlign.center,
          style: Theme.of(context).textTheme.bodyMedium,
        ),
      ),
    );
  }
}
