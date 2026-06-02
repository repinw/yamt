import 'package:flutter/material.dart';
import 'package:yamt/core/constants/app_layout_constants.dart';
import 'package:yamt/core/widgets/app_selection_list_tiles.dart';
import 'package:yamt/l10n/app_localizations.dart';

/// Lets the user configure AI recipe generation.
class AiChefSetupView extends StatelessWidget {
  /// Creates setup view.
  const AiChefSetupView({
    required this.wishesController,
    required this.includeInventory,
    required this.onIncludeInventoryChanged,
    required this.onGenerate,
    required this.onClose,
    super.key,
  });

  /// Text controller for free-form wishes.
  final TextEditingController wishesController;

  /// Whether active inventory should be sent to the AI.
  final bool includeInventory;

  /// Called when inventory option changes.
  final ValueChanged<bool> onIncludeInventoryChanged;

  /// Called when generation starts.
  final VoidCallback onGenerate;

  /// Called when user closes the dialog.
  final VoidCallback onClose;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colors = theme.colorScheme;
    final l10n = AppLocalizations.of(context)!;

    return Padding(
      padding: const EdgeInsets.all(AppSpacing.xl),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            l10n.aiChefSetupTitle,
            textAlign: TextAlign.center,
            style: theme.textTheme.titleLarge?.copyWith(
              fontWeight: FontWeight.w900,
              color: colors.onSurface,
            ),
          ),
          const SizedBox(height: AppSpacing.sm),
          Text(
            l10n.aiChefSetupSubtitle,
            textAlign: TextAlign.center,
            style: theme.textTheme.bodyMedium?.copyWith(
              color: colors.onSurfaceVariant,
            ),
          ),
          const SizedBox(height: AppSpacing.xl),
          AppCheckboxListTile(
            value: includeInventory,
            onChanged: (value) {
              onIncludeInventoryChanged(value ?? false);
            },
            contentPadding: EdgeInsets.zero,
            title: Text(l10n.aiChefUseInventoryTitle),
            subtitle: Text(l10n.aiChefUseInventorySubtitle),
          ),
          const SizedBox(height: AppSpacing.md),
          TextField(
            controller: wishesController,
            minLines: 2,
            maxLines: 4,
            textInputAction: TextInputAction.newline,
            decoration: InputDecoration(
              labelText: l10n.aiChefWishesLabel,
              hintText: l10n.aiChefWishesHint,
              alignLabelWithHint: true,
              border: const OutlineInputBorder(),
            ),
          ),
          const SizedBox(height: AppSpacing.xl),
          Row(
            children: [
              Expanded(
                child: OutlinedButton(
                  onPressed: onClose,
                  child: Text(l10n.aiChefCloseAction),
                ),
              ),
              const SizedBox(width: AppSpacing.md),
              Expanded(
                child: FilledButton.icon(
                  onPressed: onGenerate,
                  icon: const Icon(Icons.auto_awesome_rounded),
                  label: Text(l10n.aiChefGenerateAction),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
