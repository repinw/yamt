import 'package:material_ui/material_ui.dart';
import 'package:yamt/core/constants/app_layout_constants.dart';
import 'package:yamt/core/constants/app_sizes.dart';
import 'package:yamt/core/theme/food_label_colors.dart';
import 'package:yamt/core/widgets/app_ink_well.dart';
import 'package:yamt/core/widgets/home_action_entry.dart';
import 'package:yamt/features/home/presentation/widgets/home_menu_section.dart';
import 'package:yamt/l10n/app_localizations.dart';

/// Actions of the current tab, shown at the bottom right behind the slid
/// page, where the thumb reaches them: the counterpart of the side menu on
/// the left.
class HomeActionPanel extends StatelessWidget {
  /// Creates the panel with [sections].
  const new({
    required this.sections,
    required this.onClose,
    this.highlightedKey,
    this.onUsed,
    super.key,
  });

  /// Key of the close button.
  static const closeButtonKey = ValueKey<String>('home-actions-close');

  /// The actions, grouped by section.
  final List<HomeActionSection> sections;

  /// Closes the panel.
  final VoidCallback onClose;

  /// Key of the most used action, drawn on the lime accent.
  final Key? highlightedKey;

  /// Called with an action when it is tapped, before it runs.
  final ValueChanged<HomeActionEntry>? onUsed;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final colors = Theme.of(context).colorScheme;

    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(
          AppSpacing.xl,
          AppSpacing.xl,
          AppSpacing.md,
          AppSpacing.xl,
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            // The actions sit at the bottom right, where the thumb is; a
            // long list scrolls up from there.
            Expanded(
              child: FractionallySizedBox(
                widthFactor: AppSizes.homeActionPanelContentWidth,
                alignment: Alignment.bottomRight,
                child: Align(
                  alignment: Alignment.bottomLeft,
                  child: SingleChildScrollView(
                    reverse: true,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        for (final section in sections)
                          HomeMenuSection(
                            title: section.title,
                            entries: [
                              for (final entry in section.entries)
                                _ActionEntry(
                                  entry: entry,
                                  isHighlighted:
                                      entry.key != null &&
                                      entry.key == highlightedKey,
                                  onTap: () {
                                    onUsed?.call(entry);
                                    onClose();
                                    entry.onSelected();
                                  },
                                ),
                            ],
                          ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
            IconButton.filled(
              key: closeButtonKey,
              tooltip: l10n.homeMenuClose,
              onPressed: onClose,
              style: IconButton.styleFrom(
                backgroundColor: colors.surfaceContainerHighest,
                foregroundColor: colors.onSurface,
              ),
              icon: const Icon(Icons.close_rounded),
            ),
          ],
        ),
      ),
    );
  }
}

/// One action: an icon tile, its name, and one line on what it does. The
/// most used action gets a lime tile.
class _ActionEntry extends StatelessWidget {
  const new({
    required this.entry,
    required this.isHighlighted,
    required this.onTap,
  });

  final HomeActionEntry entry;
  final bool isHighlighted;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colors = theme.colorScheme;
    final labelColors = FoodLabelColors.of(context);
    return AppInkWell(
      key: entry.key,
      onTap: onTap,
      borderRadius: BorderRadius.circular(AppRadius.md),
      child: ConstrainedBox(
        constraints: const BoxConstraints(minHeight: AppSizes.minTapTarget),
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: AppSpacing.xs),
          child: Row(
            children: [
              Container(
                width: AppSizes.homeMenuIconTile,
                height: AppSizes.homeMenuIconTile,
                decoration: BoxDecoration(
                  color: isHighlighted
                      ? labelColors.accent
                      : colors.surfaceContainerHighest,
                  borderRadius: BorderRadius.circular(AppRadius.sm),
                ),
                child: IconTheme.merge(
                  data: IconThemeData(
                    size: AppSizes.homeMenuIcon,
                    color: isHighlighted
                        ? labelColors.onAccent
                        : colors.onSurface,
                  ),
                  child: entry.leading,
                ),
              ),
              const SizedBox(width: AppSpacing.md),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      entry.title,
                      style: theme.textTheme.titleSmall?.copyWith(
                        fontWeight: FontWeight.w700,
                      ),
                    ),
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
