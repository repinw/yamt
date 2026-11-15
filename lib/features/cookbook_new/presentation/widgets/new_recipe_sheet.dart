import 'package:material_ui/material_ui.dart';
import 'package:yamt/core/constants/app_graphit_constants.dart';
import 'package:yamt/core/constants/app_layout_constants.dart';
import 'package:yamt/core/constants/app_sizes.dart';
import 'package:yamt/core/theme/food_label_colors.dart';
import 'package:yamt/core/widgets/app_ink_well.dart';
import 'package:yamt/features/cookbook_new/presentation/widgets/'
    'cookbook_section_title.dart';
import 'package:yamt/l10n/app_localizations.dart';

/// The ways to start a new recipe.
enum NewRecipeChoice {
  /// Scan pages of a cookbook or a note.
  scan,

  /// Paste ingredients and steps from the clipboard.
  paste,

  /// Type it line by line.
  type,

  /// Read it from a web page.
  link,

  /// Let the AI suggest one.
  ai,
}

/// "Neues Rezept": the ways to start a new recipe. Pops with the chosen
/// one.
class NewRecipeSheet extends StatelessWidget {
  /// Creates the sheet.
  const new({super.key});

  /// Key of the entry for [choice].
  static ValueKey<String> entryKey(NewRecipeChoice choice) =>
      ValueKey<String>('new-recipe-${choice.name}');

  /// Shows the sheet and returns the chosen way, or `null` when the cook
  /// closes it.
  static Future<NewRecipeChoice?> show(BuildContext context) =>
      showModalBottomSheet<NewRecipeChoice>(
        context: context,
        // Above the bottom navigation of the home tabs.
        useRootNavigator: true,
        isScrollControlled: true,
        showDragHandle: true,
        builder: (context) => const NewRecipeSheet(),
      );

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final rule = BorderSide(color: FoodLabelColors.of(context).rule);
    final entries = [
      (
        NewRecipeChoice.scan,
        Icons.document_scanner_outlined,
        l10n.cookbookNewRecipeScan,
        l10n.cookbookNewRecipeScanDescription,
      ),
      (
        NewRecipeChoice.paste,
        Icons.content_paste_rounded,
        l10n.cookbookNewRecipePaste,
        l10n.cookbookNewRecipePasteDescription,
      ),
      (
        NewRecipeChoice.type,
        Icons.edit_outlined,
        l10n.cookbookNewRecipeType,
        l10n.cookbookNewRecipeTypeDescription,
      ),
      (
        NewRecipeChoice.link,
        Icons.add_link_rounded,
        l10n.cookbookNewRecipeLink,
        l10n.cookbookNewRecipeLinkDescription,
      ),
      (
        NewRecipeChoice.ai,
        Icons.auto_awesome_rounded,
        l10n.aiChefIdeaTitle,
        l10n.cookbookNewRecipeAiDescription,
      ),
    ];

    return SafeArea(
      child: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(
          AppSpacing.xl,
          0,
          AppSpacing.xl,
          AppSpacing.xl,
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            CookbookSectionTitle(title: l10n.cookbookNewRecipeTitle),
            const SizedBox(height: AppSpacing.md),
            for (final (index, (choice, icon, title, description))
                in entries.indexed)
              DecoratedBox(
                decoration: BoxDecoration(
                  border: index == 0 ? null : Border(top: rule),
                ),
                child: _Entry(
                  key: entryKey(choice),
                  icon: icon,
                  title: title,
                  description: description,
                  onTap: () => Navigator.of(context).pop(choice),
                ),
              ),
          ],
        ),
      ),
    );
  }
}

class _Entry extends StatelessWidget {
  const new({
    required this.icon,
    required this.title,
    required this.description,
    required this.onTap,
    super.key,
  });

  final IconData icon;
  final String title;
  final String description;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final colors = FoodLabelColors.of(context);
    final textTheme = Theme.of(context).textTheme;
    return AppInkWell(
      onTap: onTap,
      child: ConstrainedBox(
        constraints: const BoxConstraints(minHeight: AppGraphit.toolButton),
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: AppSpacing.xs),
          child: Row(
            spacing: AppSpacing.lg,
            children: [
              Container(
                width: AppSizes.homeMenuIconTile,
                height: AppSizes.homeMenuIconTile,
                decoration: BoxDecoration(
                  color: colors.card,
                  borderRadius: BorderRadius.circular(AppRadius.md),
                ),
                child: Icon(icon, size: AppGraphit.toolIcon, color: colors.ink),
              ),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  spacing: AppSpacing.xxs,
                  children: [
                    Text(
                      title,
                      style: textTheme.titleSmall?.copyWith(
                        color: colors.ink,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    Text(
                      description,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: textTheme.bodySmall?.copyWith(color: colors.muted),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
