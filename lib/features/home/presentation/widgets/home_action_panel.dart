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
///
/// A header tool on the right opens it [fromTop]: the actions then hang
/// from the top right, under the tool that opened them.
class HomeActionPanel extends StatelessWidget {
  /// Creates the panel with [sections].
  const new({
    required this.sections,
    required this.onClose,
    this.highlightedKey,
    this.onUsed,
    this.fromTop = false,
    super.key,
  });

  /// Key of the close button.
  static const closeButtonKey = ValueKey<String>('home-actions-close');

  /// The actions, grouped by section.
  final List<HomeActionSection> sections;

  /// Closes the panel.
  final VoidCallback onClose;

  /// Key of the action drawn on the lime accent: the most used one, or the
  /// current choice of a header tool.
  final Key? highlightedKey;

  /// Called with an action when it is tapped, before it runs.
  final ValueChanged<HomeActionEntry>? onUsed;

  /// Whether the close button sits at the top right with the actions below
  /// it, instead of at the bottom right below the actions.
  final bool fromTop;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final colors = Theme.of(context).colorScheme;
    final closeButton = IconButton.filled(
      key: closeButtonKey,
      tooltip: l10n.homeMenuClose,
      onPressed: onClose,
      style: IconButton.styleFrom(
        backgroundColor: colors.surfaceContainerHighest,
        foregroundColor: colors.onSurface,
      ),
      icon: const Icon(Icons.close_rounded),
    );
    // The actions sit next to the button that opened them; a long list
    // scrolls away from there.
    final actions = Expanded(
      child: FractionallySizedBox(
        widthFactor: AppSizes.homeActionPanelContentWidth,
        alignment: fromTop ? Alignment.topRight : Alignment.bottomRight,
        child: Align(
          alignment: fromTop ? Alignment.topLeft : Alignment.bottomLeft,
          child: SingleChildScrollView(
            reverse: !fromTop,
            child: _ActionSections(
              sections: sections,
              highlightedKey: highlightedKey,
              onTap: _run,
            ),
          ),
        ),
      ),
    );

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
          children: fromTop
              ? [closeButton, const SizedBox(height: AppSpacing.xl), actions]
              : [actions, closeButton],
        ),
      ),
    );
  }

  /// Counts [entry], closes the panel, and runs the action.
  void _run(HomeActionEntry entry) {
    onUsed?.call(entry);
    onClose();
    entry.onSelected();
  }
}

/// The sections of the panel with their actions.
class _ActionSections extends StatelessWidget {
  const new({
    required this.sections,
    required this.highlightedKey,
    required this.onTap,
  });

  final List<HomeActionSection> sections;
  final Key? highlightedKey;
  final ValueChanged<HomeActionEntry> onTap;

  @override
  Widget build(BuildContext context) {
    return Column(
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
                      entry.key != null && entry.key == highlightedKey,
                  onTap: () => onTap(entry),
                ),
            ],
          ),
      ],
    );
  }
}

/// One action: an icon tile, its name, and one line on what it does. The
/// highlighted action gets a lime tile.
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
    final symbolColor = isHighlighted ? labelColors.onAccent : colors.onSurface;
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
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  color: isHighlighted
                      ? labelColors.accent
                      : colors.surfaceContainerHighest,
                  borderRadius: BorderRadius.circular(AppRadius.sm),
                ),
                child: IconTheme.merge(
                  data: IconThemeData(
                    size: AppSizes.homeMenuIcon,
                    color: symbolColor,
                  ),
                  // A text symbol takes the size and color of an icon.
                  child: DefaultTextStyle.merge(
                    style: theme.textTheme.titleMedium?.copyWith(
                      color: symbolColor,
                      fontSize: AppSizes.homeMenuIcon,
                      height: 1,
                    ),
                    child: entry.leading,
                  ),
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
