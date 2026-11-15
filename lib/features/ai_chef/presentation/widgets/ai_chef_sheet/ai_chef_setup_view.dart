import 'package:material_ui/material_ui.dart';
import 'package:yamt/core/constants/app_graphit_constants.dart';
import 'package:yamt/core/constants/app_layout_constants.dart';
import 'package:yamt/core/theme/food_label_colors.dart';
import 'package:yamt/core/widgets/app_switch_list_tile.dart';
import 'package:yamt/l10n/app_localizations.dart';

/// "Worauf hast du Lust?": whether the Vorrat counts, the cook's wishes, and
/// "Rezept vorschlagen".
class AiChefSetupView extends StatelessWidget {
  /// Creates setup view.
  const new({
    required this.wishesController,
    required this.includeInventory,
    required this.onIncludeInventoryChanged,
    required this.onGenerate,
    super.key,
  });

  /// Key of the Vorrat switch.
  static const inventoryKey = ValueKey<String>('ai-chef-inventory');

  /// Key of the wishes field.
  static const wishesKey = ValueKey<String>('ai-chef-wishes');

  /// Key of "Rezept vorschlagen".
  static const generateKey = ValueKey<String>('ai-chef-generate');

  /// Text controller for free-form wishes.
  final TextEditingController wishesController;

  /// Whether active inventory should be sent to the AI.
  final bool includeInventory;

  /// Called when inventory option changes.
  final ValueChanged<bool> onIncludeInventoryChanged;

  /// Called when generation starts.
  final VoidCallback onGenerate;

  @override
  Widget build(BuildContext context) {
    final colors = FoodLabelColors.of(context);
    final textTheme = Theme.of(context).textTheme;
    final l10n = AppLocalizations.of(context)!;

    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(
          l10n.aiChefSetupTitle,
          style: textTheme.titleLarge?.copyWith(
            color: colors.ink,
            fontWeight: FontWeight.w800,
          ),
        ),
        const SizedBox(height: AppSpacing.sm),
        AppSwitchListTile(
          key: inventoryKey,
          value: includeInventory,
          onChanged: onIncludeInventoryChanged,
          contentPadding: EdgeInsets.zero,
          title: Text(l10n.aiChefUseInventoryTitle),
          subtitle: Text(l10n.aiChefUseInventorySubtitle),
        ),
        const SizedBox(height: AppSpacing.md),
        TextField(
          key: wishesKey,
          controller: wishesController,
          minLines: 1,
          maxLines: 3,
          textCapitalization: TextCapitalization.sentences,
          decoration: InputDecoration(
            labelText: l10n.aiChefWishesLabel,
            hintText: l10n.aiChefWishesHint,
            hintMaxLines: 2,
          ),
        ),
        const SizedBox(height: AppSpacing.xl),
        FilledButton(
          key: generateKey,
          onPressed: onGenerate,
          style: FilledButton.styleFrom(
            backgroundColor: colors.accent,
            foregroundColor: colors.onAccent,
            minimumSize: const Size.fromHeight(AppGraphit.buttonHeight),
          ),
          child: Text(
            l10n.aiChefGenerateAction,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ),
      ],
    );
  }
}
