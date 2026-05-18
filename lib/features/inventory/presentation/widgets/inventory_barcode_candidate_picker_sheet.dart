import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:yamt/core/constants/app_layout_constants.dart';
import 'package:yamt/features/inventory/presentation/widgets/'
    'inventory_barcode_lookup_candidate.dart';
import 'package:yamt/features/inventory/presentation/widgets/'
    'inventory_product_candidate_widgets.dart';
import 'package:yamt/l10n/app_localizations.dart';

/// The inventory barcode candidate sheet key.
const inventoryBarcodeCandidateSheetKey = Key(
  'inventory_barcode_candidate_sheet',
);

/// Defines inventory barcode candidate picker sheet.
class InventoryBarcodeCandidatePickerSheet extends StatelessWidget {
  /// The inventory barcode candidate picker sheet.
  const InventoryBarcodeCandidatePickerSheet({
    required this.candidates,
    required this.onSelect,
    super.key,
    this.showActionButtons = true,
    this.eatOnly = false,
    this.onCreateManual,
  });

  /// The candidates.
  final List<InventoryBarcodeLookupCandidate> candidates;

  /// The on select.
  final void Function(
    InventoryBarcodeLookupCandidate candidate,
    InventoryBarcodeCandidateAction action,
  )
  onSelect;

  /// Whether candidate rows show explicit action buttons.
  final bool showActionButtons;

  /// Whether only eat action should be shown.
  final bool eatOnly;

  /// Called when user wants to create their own product.
  final VoidCallback? onCreateManual;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final colors = Theme.of(context).colorScheme;

    return SafeArea(
      child: DecoratedBox(
        key: inventoryBarcodeCandidateSheetKey,
        decoration: BoxDecoration(
          color: colors.surface,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
        ),
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: <Widget>[
              _BarcodeCandidatePickerHeader(
                title: l10n.inventoryManualAddCandidateTitle,
                subtitle: l10n.inventoryManualAddCandidateSubtitle,
              ),
              const SizedBox(height: AppSpacing.lg),
              ConstrainedBox(
                constraints: BoxConstraints(
                  maxHeight: MediaQuery.sizeOf(context).height * 0.6,
                ),
                child: ListView.separated(
                  shrinkWrap: true,
                  itemCount: candidates.length,
                  separatorBuilder: (_, _) =>
                      const SizedBox(height: AppSpacing.sm),
                  itemBuilder: (context, index) {
                    final candidate = candidates[index];
                    return _BarcodeCandidateTile(
                      candidate: candidate,
                      showActionButtons: showActionButtons,
                      eatOnly: eatOnly,
                      onSelect: onSelect,
                    );
                  },
                ),
              ),
              if (onCreateManual != null) ...[
                const SizedBox(height: AppSpacing.lg),
                OutlinedButton.icon(
                  key: const Key(
                    'inventory_barcode_candidate_create_manual_button',
                  ),
                  onPressed: onCreateManual,
                  icon: const Icon(Icons.edit_note_rounded),
                  label: Text(l10n.inventoryManualAddCreateOwnAction),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

class _BarcodeCandidatePickerHeader extends StatelessWidget {
  const _BarcodeCandidatePickerHeader({
    required this.title,
    required this.subtitle,
  });

  final String title;
  final String subtitle;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;

    return Row(
      children: <Widget>[
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              Text(
                title,
                style: Theme.of(
                  context,
                ).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w800),
              ),
              const SizedBox(height: AppSpacing.xxs * 2),
              Text(
                subtitle,
                style: Theme.of(
                  context,
                ).textTheme.bodySmall?.copyWith(color: colors.onSurfaceVariant),
              ),
            ],
          ),
        ),
        IconButton(
          onPressed: () => _close(context),
          icon: Icon(Icons.close, color: colors.onSurfaceVariant),
          style: IconButton.styleFrom(
            backgroundColor: colors.surfaceContainerHighest,
          ),
        ),
      ],
    );
  }

  void _close(BuildContext context) {
    final router = GoRouter.maybeOf(context);
    if (router != null) {
      router.pop();
      return;
    }
    Navigator.of(context).pop();
  }
}

class _BarcodeCandidateTile extends StatelessWidget {
  const _BarcodeCandidateTile({
    required this.candidate,
    required this.showActionButtons,
    required this.eatOnly,
    required this.onSelect,
  });

  final InventoryBarcodeLookupCandidate candidate;
  final bool showActionButtons;
  final bool eatOnly;
  final void Function(
    InventoryBarcodeLookupCandidate candidate,
    InventoryBarcodeCandidateAction action,
  )
  onSelect;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final sourceLabel =
        candidate.source == InventoryBarcodeLookupCandidateSource.learned
        ? l10n.inventoryManualAddCandidateSourceLearned
        : l10n.inventoryManualAddCandidateSourceOff;

    return InventoryProductCandidateTile(
      name: candidate.name,
      brand: candidate.brand,
      imageUrl: candidate.imageUrl,
      packageWeight: candidate.packageWeight,
      nutrition: candidate.nutrition,
      topLabel: sourceLabel,
      onTap: showActionButtons
          ? null
          : () => onSelect(
              candidate,
              InventoryBarcodeCandidateAction.addToInventory,
            ),
      trailing: showActionButtons
          ? InventoryProductCandidateActions(
              inventoryLabel: l10n.inventoryManualAddResultActionInventory,
              eatLabel: l10n.inventoryManualAddResultActionEat,
              inventoryButtonKey: Key(
                'inventory_barcode_candidate_store_button_'
                '${inventoryBarcodeCandidateWidgetKeySuffix(candidate)}',
              ),
              eatButtonKey: Key(
                'inventory_barcode_candidate_eat_button_'
                '${inventoryBarcodeCandidateWidgetKeySuffix(candidate)}',
              ),
              onInventory: () => onSelect(
                candidate,
                InventoryBarcodeCandidateAction.addToInventory,
              ),
              onEat: () => onSelect(
                candidate,
                InventoryBarcodeCandidateAction.eatNow,
              ),
              showInventoryAction: !eatOnly,
            )
          : null,
    );
  }
}
