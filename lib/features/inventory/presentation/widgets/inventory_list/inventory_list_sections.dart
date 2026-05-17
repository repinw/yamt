import 'package:flutter/material.dart';
import 'package:yamt/core/constants/app_layout_constants.dart';
import 'package:yamt/core/theme/app_theme_tokens.dart';
import 'package:yamt/core/widgets/app_ink_well.dart';
import 'package:yamt/core/widgets/app_responsive_viewport.dart';
import 'package:yamt/features/inventory/presentation/widgets/'
    'inventory_expand_indicator.dart';
import 'package:yamt/features/inventory/presentation/widgets/shared/'
    'inventory_segmented_button_frame.dart';
import 'package:yamt/l10n/app_localizations.dart';

/// Defines inventory mode toolbar.
class InventoryModeToolbar extends StatelessWidget {
  /// The inventory mode toolbar.
  const InventoryModeToolbar({required this.modeToggle, super.key});

  /// The mode toggle.
  final Widget modeToggle;

  @override
  Widget build(BuildContext context) {
    return InventorySegmentedButtonFrame(child: modeToggle);
  }
}

/// Defines inventory section header.
class InventorySectionHeader extends StatelessWidget {
  /// The inventory section header.
  const InventorySectionHeader({
    required this.title,
    super.key,
    this.subtitle,
    this.trailing,
  });

  /// The title.
  final String title;

  /// The subtitle.
  final String? subtitle;

  /// The trailing.
  final Widget? trailing;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    final titleContent = Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: Theme.of(context).textTheme.headlineSmall?.copyWith(
            color: colors.onSurface,
            fontWeight: FontWeight.w800,
          ),
        ),
        if (subtitle != null) ...[
          const SizedBox(height: AppSpacing.xxs),
          Text(
            subtitle!,
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
              color: colors.onSurfaceVariant,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ],
    );

    if (trailing == null) {
      return titleContent;
    }

    if (isCompactViewport(context)) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          titleContent,
          const SizedBox(height: AppSpacing.sm),
          Align(alignment: Alignment.centerLeft, child: trailing),
        ],
      );
    }

    return Row(
      crossAxisAlignment: subtitle == null
          ? CrossAxisAlignment.center
          : CrossAxisAlignment.start,
      children: [
        Expanded(child: titleContent),
        if (subtitle != null) const SizedBox(width: AppSpacing.md),
        trailing!,
      ],
    );
  }
}

/// Defines inventory filter button.
class InventoryFilterButton extends StatelessWidget {
  /// The inventory filter button.
  const InventoryFilterButton({
    required this.onPressed,
    super.key,
    this.enabled = true,
    this.tooltip,
  });

  /// The on pressed.
  final VoidCallback onPressed;

  /// The enabled.
  final bool enabled;

  /// The tooltip.
  final String? tooltip;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;

    return IconButton(
      onPressed: enabled ? onPressed : null,
      tooltip: tooltip ?? l10n.inventoryFilterAction,
      visualDensity: VisualDensity.compact,
      padding: EdgeInsets.zero,
      icon: const Icon(Icons.filter_list_rounded, size: 18),
    );
  }
}

/// Defines inventory filters sheet.
class InventoryFiltersSheet extends StatelessWidget {
  /// The inventory filters sheet.
  const InventoryFiltersSheet({
    required this.title,
    required this.subtitle,
    required this.actionLabel,
    required this.children,
    super.key,
  });

  /// The title.
  final String title;

  /// The subtitle.
  final String subtitle;

  /// The action label.
  final String actionLabel;

  /// The children.
  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    final mediaQuery = MediaQuery.of(context);
    final isCompact = mediaQuery.size.width < 640;
    final borderRadius = isCompact
        ? const BorderRadius.vertical(
            top: Radius.circular(AppRadius.xl + AppSpacing.xs),
          )
        : BorderRadius.circular(AppRadius.xl + AppSpacing.md);
    final outerPadding = EdgeInsets.fromLTRB(
      AppSpacing.sm,
      AppSpacing.md,
      AppSpacing.sm,
      isCompact ? 0 : AppSpacing.sm + mediaQuery.padding.bottom,
    );
    final footerPadding = EdgeInsets.fromLTRB(
      AppSpacing.lg,
      AppSpacing.lg,
      AppSpacing.lg,
      AppSpacing.lg + (isCompact ? mediaQuery.padding.bottom : 0),
    );

    return Padding(
      padding: outerPadding,
      child: Align(
        alignment: Alignment.bottomCenter,
        child: ConstrainedBox(
          constraints: BoxConstraints(
            maxWidth: 520,
            maxHeight: mediaQuery.size.height * (isCompact ? 0.92 : 0.84),
          ),
          child: DecoratedBox(
            decoration: AppInventoryEditorialSurfaces.liftedCardDecoration(
              colors,
              borderRadius: borderRadius,
              blurRadius: 28,
              shadowOffset: const Offset(0, 16),
            ),
            child: ClipRRect(
              borderRadius: borderRadius,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  if (isCompact)
                    Padding(
                      padding: const EdgeInsets.only(
                        top: AppSpacing.sm,
                        bottom: AppSpacing.xxs,
                      ),
                      child: DecoratedBox(
                        decoration: BoxDecoration(
                          color: colors.outlineVariant.withValues(alpha: 0.5),
                          borderRadius: BorderRadius.circular(AppRadius.lg),
                        ),
                        child: const SizedBox(width: 44, height: 5),
                      ),
                    ),
                  Padding(
                    padding: const EdgeInsets.fromLTRB(
                      AppSpacing.xxl,
                      AppSpacing.lg,
                      AppSpacing.lg,
                      AppSpacing.lg,
                    ),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                title,
                                style: Theme.of(context).textTheme.headlineSmall
                                    ?.copyWith(
                                      color: colors.onSurface,
                                      fontWeight: FontWeight.w800,
                                    ),
                              ),
                              const SizedBox(height: AppSpacing.xs),
                              Text(
                                subtitle,
                                style: Theme.of(context).textTheme.bodyMedium
                                    ?.copyWith(color: colors.onSurfaceVariant),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(width: AppSpacing.md),
                        IconButton(
                          onPressed: () => Navigator.of(context).pop(),
                          tooltip: MaterialLocalizations.of(
                            context,
                          ).closeButtonTooltip,
                          style: IconButton.styleFrom(
                            backgroundColor: colors.surfaceContainerLow,
                            foregroundColor: colors.onSurfaceVariant,
                          ),
                          icon: const Icon(Icons.close_rounded),
                        ),
                      ],
                    ),
                  ),
                  Flexible(
                    child: SingleChildScrollView(
                      padding: const EdgeInsets.fromLTRB(
                        AppSpacing.lg,
                        0,
                        AppSpacing.lg,
                        AppSpacing.lg,
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: children,
                      ),
                    ),
                  ),
                  DecoratedBox(
                    decoration: BoxDecoration(
                      color: colors.surfaceContainerLowest,
                      border: Border(
                        top: BorderSide(
                          color: colors.outlineVariant.withValues(alpha: 0.4),
                        ),
                      ),
                    ),
                    child: Padding(
                      padding: footerPadding,
                      child: _InventoryFiltersPrimaryButton(
                        label: actionLabel,
                        onPressed: () => Navigator.of(context).pop(),
                      ),
                    ),
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

/// Defines inventory filters section label.
class InventoryFiltersSectionLabel extends StatelessWidget {
  /// The inventory filters section label.
  const InventoryFiltersSectionLabel({required this.label, super.key});

  /// The label.
  final String label;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.xs),
      child: Text(
        label.toUpperCase(),
        style: Theme.of(context).textTheme.labelSmall?.copyWith(
          color: colors.onSurfaceVariant,
          fontWeight: FontWeight.w800,
          letterSpacing: 1.1,
        ),
      ),
    );
  }
}

/// Defines inventory sort option card.
class InventorySortOptionCard extends StatelessWidget {
  /// The inventory sort option card.
  const InventorySortOptionCard({
    required this.title,
    required this.icon,
    required this.isSelected,
    required this.enabled,
    required this.onSelect,
    super.key,
    this.directionLabel,
    this.onToggleDirection,
    this.directionButtonKey,
    this.sortDirectionAscending,
  });

  /// The title.
  final String title;

  /// The icon.
  final IconData icon;

  /// Whether selected.
  final bool isSelected;

  /// The enabled.
  final bool enabled;

  /// The on select.
  final VoidCallback onSelect;

  /// The direction label.
  final String? directionLabel;

  /// The on toggle direction.
  final VoidCallback? onToggleDirection;

  /// The direction button key.
  final Key? directionButtonKey;

  /// The sort direction ascending.
  final bool? sortDirectionAscending;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    final borderColor = isSelected
        ? colors.primary.withValues(alpha: 0.18)
        : Colors.transparent;
    final backgroundColor = isSelected
        ? Color.alphaBlend(
            colors.primary.withValues(alpha: 0.08),
            AppInventoryEditorialSurfaces.section(colors),
          )
        : Colors.transparent;
    final iconBackground = isSelected
        ? colors.primary.withValues(alpha: 0.14)
        : colors.surfaceContainerLow;
    final iconColor = isSelected ? colors.primary : colors.onSurfaceVariant;

    return MergeSemantics(
      child: Semantics(
        selected: isSelected,
        child: AppInkWell(
          onTap: enabled ? onSelect : null,
          borderRadius: BorderRadius.circular(AppRadius.xl),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 180),
            curve: Curves.easeOutCubic,
            decoration: BoxDecoration(
              color: backgroundColor,
              borderRadius: BorderRadius.circular(AppRadius.xl),
              border: Border.all(color: borderColor),
              boxShadow: isSelected
                  ? [
                      AppInventoryEditorialSurfaces.ambientBoxShadow(
                        colors,
                        blurRadius: 18,
                        offset: const Offset(0, 10),
                      ),
                    ]
                  : null,
            ),
            padding: const EdgeInsets.all(AppSpacing.xs),
            child: Row(
              children: [
                Expanded(
                  child: TextButton(
                    onPressed: enabled ? onSelect : null,
                    style: TextButton.styleFrom(
                      foregroundColor: Colors.transparent,
                      padding: const EdgeInsets.symmetric(
                        horizontal: AppSpacing.xs,
                        vertical: AppSpacing.sm,
                      ),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(AppRadius.xl),
                      ),
                    ),
                    child: Row(
                      children: [
                        DecoratedBox(
                          decoration: BoxDecoration(
                            color: iconBackground,
                            borderRadius: BorderRadius.circular(AppRadius.lg),
                          ),
                          child: Padding(
                            padding: const EdgeInsets.all(AppSpacing.sm),
                            child: Icon(icon, size: 18, color: iconColor),
                          ),
                        ),
                        const SizedBox(width: AppSpacing.md),
                        Expanded(
                          child: Text(
                            title,
                            style: Theme.of(context).textTheme.titleSmall
                                ?.copyWith(
                                  color: enabled
                                      ? colors.onSurface
                                      : colors.onSurface.withValues(alpha: 0.5),
                                  fontWeight: FontWeight.w700,
                                ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                if (isSelected && directionLabel != null) ...[
                  const SizedBox(width: AppSpacing.sm),
                  TextButton(
                    key: directionButtonKey,
                    onPressed: enabled ? onToggleDirection : null,
                    style: TextButton.styleFrom(
                      padding: const EdgeInsets.fromLTRB(
                        AppSpacing.sm,
                        AppSpacing.xs,
                        AppSpacing.xs,
                        AppSpacing.xs,
                      ),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(AppRadius.xl),
                      ),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        DecoratedBox(
                          decoration: BoxDecoration(
                            color: colors.primary.withValues(alpha: 0.12),
                            borderRadius: BorderRadius.circular(AppRadius.md),
                          ),
                          child: Padding(
                            padding: const EdgeInsets.symmetric(
                              horizontal: AppSpacing.sm,
                              vertical: AppSpacing.xs,
                            ),
                            child: Text(
                              directionLabel!,
                              style: Theme.of(context).textTheme.labelMedium
                                  ?.copyWith(
                                    color: colors.primary,
                                    fontWeight: FontWeight.w700,
                                  ),
                            ),
                          ),
                        ),
                        const SizedBox(width: AppSpacing.sm),
                        DecoratedBox(
                          decoration: BoxDecoration(
                            color: colors.surfaceContainerLowest,
                            shape: BoxShape.circle,
                            border: Border.all(
                              color: colors.primary.withValues(alpha: 0.16),
                            ),
                          ),
                          child: Padding(
                            padding: const EdgeInsets.all(AppSpacing.xs),
                            child: Icon(
                              sortDirectionAscending == true
                                  ? Icons.arrow_upward_rounded
                                  : Icons.arrow_downward_rounded,
                              size: 16,
                              color: colors.primary,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _InventoryFiltersPrimaryButton extends StatelessWidget {
  const _InventoryFiltersPrimaryButton({
    required this.label,
    required this.onPressed,
  });

  final String label;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;

    return DecoratedBox(
      decoration: BoxDecoration(
        gradient: AppInventoryEditorialSurfaces.soulGradient(colors),
        borderRadius: BorderRadius.circular(AppRadius.lg),
        boxShadow: [
          AppInventoryEditorialSurfaces.ambientBoxShadow(
            colors,
            blurRadius: 24,
            offset: const Offset(0, 12),
          ),
        ],
      ),
      child: SizedBox(
        width: double.infinity,
        child: TextButton(
          onPressed: onPressed,
          style: TextButton.styleFrom(
            padding: const EdgeInsets.symmetric(vertical: AppSpacing.xl),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(AppRadius.lg),
            ),
            foregroundColor: colors.onPrimary,
          ),
          child: Text(
            label,
            style: Theme.of(context).textTheme.titleSmall?.copyWith(
              color: colors.onPrimary,
              fontWeight: FontWeight.w800,
            ),
          ),
        ),
      ),
    );
  }
}

/// Defines inventory section expand button.
class InventorySectionExpandButton extends StatelessWidget {
  /// The inventory section expand button.
  const InventorySectionExpandButton({
    required this.isExpanded,
    required this.semanticLabel,
    required this.onPressed,
    super.key,
    this.rotationKey,
    this.enabled = true,
  });

  /// Whether expanded.
  final bool isExpanded;

  /// The semantic label.
  final String semanticLabel;

  /// The on pressed.
  final VoidCallback onPressed;

  /// The rotation key.
  final Key? rotationKey;

  /// The enabled.
  final bool enabled;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      button: true,
      enabled: enabled,
      expanded: isExpanded,
      label: semanticLabel,
      child: AppInkResponse(
        onTap: enabled ? onPressed : null,
        radius: 24,
        child: Padding(
          padding: const EdgeInsets.all(AppSpacing.xxs),
          child: InventoryExpandIndicator(
            isExpanded: isExpanded,
            enabled: enabled,
            rotationKey: rotationKey,
          ),
        ),
      ),
    );
  }
}

/// Defines inventory empty state.
class InventoryEmptyState extends StatelessWidget {
  /// The inventory empty state.
  const InventoryEmptyState({
    super.key,
    this.actionButton,
    this.message,
  });

  /// The action button.
  final Widget? actionButton;

  /// The message.
  final String? message;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    final l10n = AppLocalizations.of(context)!;
    final emptyStateMessage = message ?? l10n.inventoryEmptyState;
    final cardRadius = BorderRadius.circular(AppInventoryEditorial.cardRadius);

    return DecoratedBox(
      decoration: AppInventoryEditorialSurfaces.liftedCardDecoration(
        colors,
        borderRadius: cardRadius,
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.xxxl,
          vertical: AppSpacing.xxxxl,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (actionButton != null) ...[
              _InventoryEmptyStateHighlightedAction(child: actionButton!),
              const SizedBox(height: AppSpacing.xxl),
            ],
            Text(
              emptyStateMessage,
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.bodyMedium,
            ),
          ],
        ),
      ),
    );
  }
}

class _InventoryEmptyStateHighlightedAction extends StatelessWidget {
  const _InventoryEmptyStateHighlightedAction({required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    final isLightTheme = Theme.of(context).brightness == Brightness.light;
    final haloColor = isLightTheme
        ? colors.shadow.withValues(alpha: 0.08)
        : colors.primary.withValues(alpha: 0.12);
    final haloShadowColor = isLightTheme
        ? colors.shadow.withValues(alpha: 0.18)
        : colors.primary.withValues(alpha: 0.28);

    return SizedBox.square(
      key: const Key('inventory_empty_state_fab_highlight'),
      dimension: AppInventoryEditorial.emptyStateActionHighlightSize,
      child: Stack(
        alignment: Alignment.center,
        children: [
          DecoratedBox(
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: haloColor,
              boxShadow: [
                BoxShadow(
                  color: haloShadowColor,
                  blurRadius: isLightTheme
                      ? AppInventoryEditorial.emptyStateActionLightBlurRadius
                      : AppInventoryEditorial.emptyStateActionDarkBlurRadius,
                  spreadRadius: isLightTheme
                      ? AppInventoryEditorial.emptyStateActionLightSpreadRadius
                      : AppInventoryEditorial.emptyStateActionDarkSpreadRadius,
                ),
              ],
            ),
            child: const SizedBox.square(
              dimension: AppInventoryEditorial.emptyStateActionHaloSize,
            ),
          ),
          child,
        ],
      ),
    );
  }
}
