import 'package:material_ui/material_ui.dart';
import 'package:yamt/core/constants/app_food_label_constants.dart';
import 'package:yamt/core/constants/app_graphit_constants.dart';
import 'package:yamt/core/constants/app_layout_constants.dart';
import 'package:yamt/core/theme/food_label_colors.dart';
import 'package:yamt/core/widgets/app_ink_well.dart';
import 'package:yamt/features/cookbook_new/domain/cookbook_overview.dart';
import 'package:yamt/features/cookbook_new/presentation/widgets/'
    'cookbook_template_tile.dart';
import 'package:yamt/l10n/app_localizations.dart';

/// Horizontal strip of Vorlagen, led by the tile that combines a new one from
/// the Vorrat.
class CookbookTemplateStrip extends StatelessWidget {
  /// Creates the strip.
  const new({
    required this.templates,
    required this.horizontalPadding,
    required this.onCreate,
    required this.onOpen,
    super.key,
  });

  /// Key of the tile that combines a new Vorlage.
  static const createKey = ValueKey<String>('cookbook-new-template');

  /// The Vorlagen with their stock flags.
  final List<CookbookEntry> templates;

  /// Space before the first and after the last tile.
  final double horizontalPadding;

  /// Starts combining a new Vorlage from the Vorrat.
  final VoidCallback onCreate;

  /// Opens a Vorlage.
  final ValueChanged<CookbookEntry> onOpen;

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      padding: EdgeInsets.symmetric(horizontal: horizontalPadding),
      child: IntrinsicHeight(
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          spacing: AppSpacing.sm,
          children: [
            _CreateTile(key: createKey, onTap: onCreate),
            for (final entry in templates)
              CookbookTemplateTile(entry: entry, onOpen: () => onOpen(entry)),
          ],
        ),
      ),
    );
  }
}

class _CreateTile extends StatelessWidget {
  const new({required this.onTap, super.key});

  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final colors = FoodLabelColors.of(context);
    final textTheme = Theme.of(context).textTheme;
    final radius = BorderRadius.circular(AppRadius.md);

    return ConstrainedBox(
      constraints: const BoxConstraints(
        minHeight: AppGraphit.stripTileMinHeight,
      ),
      child: SizedBox(
        width: AppGraphit.stripStartTileWidth,
        child: AppInkWell(
          onTap: onTap,
          borderRadius: radius,
          child: DecoratedBox(
            decoration: BoxDecoration(
              borderRadius: radius,
              border: Border.all(
                color: colors.muted,
                width: AppFoodLabel.chipOutline,
              ),
            ),
            child: Padding(
              padding: const EdgeInsets.all(AppSpacing.md),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                spacing: AppSpacing.xs,
                children: [
                  CircleAvatar(
                    backgroundColor: colors.tile,
                    foregroundColor: colors.ink,
                    child: const Icon(Icons.add_rounded),
                  ),
                  Text(
                    l10n.cookbookNewTemplateTitle,
                    textAlign: TextAlign.center,
                    style: textTheme.titleSmall?.copyWith(
                      color: colors.ink,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  Text(
                    l10n.cookbookNewTemplateCaption,
                    textAlign: TextAlign.center,
                    style: textTheme.labelSmall?.copyWith(color: colors.muted),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
