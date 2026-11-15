import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:material_ui/material_ui.dart';
import 'package:yamt/core/constants/app_food_label_constants.dart';
import 'package:yamt/core/constants/app_graphit_constants.dart';
import 'package:yamt/core/constants/app_layout_constants.dart';
import 'package:yamt/core/theme/food_label_colors.dart';
import 'package:yamt/core/widgets/app_snack_bar.dart';
import 'package:yamt/features/cookbook_new/presentation/recipe_link_flow.dart';
import 'package:yamt/l10n/app_localizations.dart';

/// Says that the page at [recipeUrl] could not be read and how the cook
/// gets the recipe in anyway. "Nochmal versuchen" reads the page again and,
/// when that works, opens its import review with the typed [name] and
/// [portions]; the saved recipe replaces the editor.
class RecipeLinkFailedCard extends ConsumerStatefulWidget {
  /// Creates the card for [recipeUrl].
  const new({
    required this.recipeUrl,
    required this.name,
    required this.portions,
    super.key,
  });

  /// Key of the card.
  static const cardKey = ValueKey<String>('recipe-link-failed');

  /// Key of "Nochmal versuchen".
  static const retryKey = ValueKey<String>('recipe-link-retry');

  /// The link of the page that could not be read.
  final String recipeUrl;

  /// The name typed so far; empty when there is none.
  final String name;

  /// The portion count the cook set; `null` when untouched, so the draft's
  /// default does not replace the page's servings.
  final int? portions;

  @override
  ConsumerState<RecipeLinkFailedCard> createState() =>
      _RecipeLinkFailedCardState();
}

class _RecipeLinkFailedCardState extends ConsumerState<RecipeLinkFailedCard> {
  var _isRetrying = false;

  Future<void> _retry() async {
    final l10n = AppLocalizations.of(context)!;
    final messenger = ScaffoldMessenger.of(context);
    setState(() => _isRetrying = true);
    final imported = await RecipeLinkFlow.retry(
      context,
      ref,
      widget.recipeUrl,
      name: widget.name,
      portions: widget.portions,
    );
    if (!mounted) return;
    setState(() => _isRetrying = false);
    if (!imported) {
      messenger.showAppSnackBar(
        l10n.preparedMealTemplateRecipeImportFailedMessage,
        tone: AppSnackBarTone.error,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final colors = FoodLabelColors.of(context);
    final textTheme = Theme.of(context).textTheme;

    return Padding(
      padding: const EdgeInsets.fromLTRB(
        AppSpacing.xl,
        AppSpacing.lg,
        AppSpacing.xl,
        0,
      ),
      child: Semantics(
        key: RecipeLinkFailedCard.cardKey,
        container: true,
        liveRegion: true,
        child: DecoratedBox(
          decoration: BoxDecoration(
            color: colors.card,
            border: Border.all(
              color: colors.ink,
              width: AppFoodLabel.chipOutline,
            ),
          ),
          child: Padding(
            padding: const EdgeInsets.all(AppSpacing.lg),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              spacing: AppSpacing.md,
              children: [
                Text(
                  l10n.recipeLinkFailedTitle,
                  style: textTheme.titleMedium?.copyWith(
                    color: colors.ink,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                Text(
                  l10n.recipeLinkFailedHint,
                  style: textTheme.bodySmall?.copyWith(
                    color: colors.muted,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                FilledButton(
                  key: RecipeLinkFailedCard.retryKey,
                  onPressed: _isRetrying ? null : _retry,
                  style: FilledButton.styleFrom(
                    backgroundColor: colors.paper,
                    foregroundColor: colors.ink,
                    minimumSize: const Size(0, AppGraphit.buttonHeight),
                  ),
                  child: _isRetrying
                      ? SizedBox.square(
                          dimension: AppGraphit.toolIcon,
                          child: CircularProgressIndicator(
                            strokeWidth: AppGraphit.highlightUnderline,
                            color: colors.ink,
                          ),
                        )
                      : Text(l10n.recipeLinkRetry),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
