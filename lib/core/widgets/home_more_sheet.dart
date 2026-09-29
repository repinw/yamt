import 'package:material_ui/material_ui.dart';
import 'package:yamt/core/constants/app_food_label_constants.dart';
import 'package:yamt/core/constants/app_layout_constants.dart';
import 'package:yamt/core/constants/app_sizes.dart';
import 'package:yamt/core/widgets/app_ink_well.dart';

/// One entry of the Mehr sheet: an action with a title and a one-line
/// description of what it does.
@immutable
class HomeMoreEntry {
  /// Creates a Mehr sheet entry.
  const new({
    required this.title,
    required this.description,
    required this.onSelected,
    this.icon,
    this.symbol,
    this.key,
  }) : assert(icon != null || symbol != null, 'Needs an icon or a symbol.');

  /// Icon in front of the title.
  final IconData? icon;

  /// Drawn symbol in front of the title, such as a barcode, used instead of
  /// [icon].
  final Widget? symbol;

  /// The symbol in front of the title, sized and colored by the icon theme.
  Widget get leading => symbol ?? Icon(icon);

  /// Name of the action.
  final String title;

  /// One line that says what the action does.
  final String description;

  /// Called after the sheet or the action panel closed.
  final VoidCallback onSelected;

  /// Key of the entry's tile, for tests.
  final Key? key;
}

/// Titled group of Mehr sheet entries.
@immutable
class HomeMoreSection {
  /// Creates a Mehr sheet section.
  const new({required this.title, required this.entries});

  /// Small title above the entries.
  final String title;

  /// Entries of the section.
  final List<HomeMoreEntry> entries;
}

/// Shows the Mehr sheet, the one menu pattern of the app.
Future<void> showHomeMoreSheet(
  BuildContext context, {
  required List<HomeMoreSection> sections,
}) {
  return showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    useSafeArea: true,
    showDragHandle: true,
    builder: (context) => HomeMoreSheet(sections: sections),
  );
}

/// Content of the Mehr sheet: sections of entries, each with a title and a
/// description.
class HomeMoreSheet extends StatelessWidget {
  /// Creates the Mehr sheet content.
  const new({required this.sections, super.key});

  /// Sections from top to bottom.
  final List<HomeMoreSection> sections;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final kickerStyle = theme.textTheme.labelSmall?.copyWith(
      color: theme.colorScheme.onSurfaceVariant,
      letterSpacing: AppFoodLabel.brandTracking,
    );

    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(
        AppSpacing.xl,
        0,
        AppSpacing.xl,
        AppSpacing.xxxl,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          for (final section in sections) ...[
            Padding(
              padding: const EdgeInsets.only(
                top: AppSpacing.md,
                bottom: AppSpacing.xs,
              ),
              child: Text(section.title.toUpperCase(), style: kickerStyle),
            ),
            for (final entry in section.entries) _HomeMoreEntryTile(entry),
          ],
        ],
      ),
    );
  }
}

class _HomeMoreEntryTile extends StatelessWidget {
  const new(this.entry);

  final HomeMoreEntry entry;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colors = theme.colorScheme;

    return AppInkWell(
      key: entry.key,
      borderRadius: BorderRadius.circular(AppRadius.md),
      onTap: () {
        Navigator.of(context).pop();
        entry.onSelected();
      },
      child: ConstrainedBox(
        constraints: const BoxConstraints(minHeight: AppSizes.minTapTarget),
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: AppSpacing.xs),
          child: Row(
            children: [
              SizedBox.square(
                dimension: AppSizes.moreEntryIconTile,
                child: DecoratedBox(
                  decoration: BoxDecoration(
                    color: colors.secondaryContainer,
                    borderRadius: BorderRadius.circular(AppRadius.md),
                  ),
                  child: IconTheme.merge(
                    data: IconThemeData(color: colors.onSecondaryContainer),
                    child: entry.leading,
                  ),
                ),
              ),
              const SizedBox(width: AppSpacing.md),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(entry.title, style: theme.textTheme.titleSmall),
                    Text(
                      entry.description,
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: colors.onSurfaceVariant,
                      ),
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
