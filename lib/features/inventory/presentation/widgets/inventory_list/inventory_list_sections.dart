import 'package:flutter/material.dart';
import 'package:yamt/core/constants/app_ui_constants.dart';
import 'package:yamt/features/inventory/presentation/widgets/'
    'inventory_expand_indicator.dart';
import 'package:yamt/features/inventory/presentation/widgets/inventory_list/'
    'inventory_segmented_button_frame.dart';
import 'package:yamt/l10n/app_localizations.dart';

class InventoryModeToolbar extends StatelessWidget {
  const InventoryModeToolbar({super.key, required this.modeToggle});

  final Widget modeToggle;

  @override
  Widget build(BuildContext context) {
    return InventorySegmentedButtonFrame(child: modeToggle);
  }
}

class InventorySectionHeader extends StatelessWidget {
  const InventorySectionHeader({
    super.key,
    required this.title,
    this.subtitle,
    this.trailing,
  });

  final String title;
  final String? subtitle;
  final Widget? trailing;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;

    return Row(
      crossAxisAlignment: subtitle == null
          ? CrossAxisAlignment.center
          : CrossAxisAlignment.start,
      children: [
        Expanded(
          child: Column(
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
          ),
        ),
        ...?(trailing == null
            ? null
            : <Widget>[
                if (subtitle != null) const SizedBox(width: AppSpacing.md),
                trailing!,
              ]),
      ],
    );
  }
}

class InventoryFilterButton extends StatelessWidget {
  const InventoryFilterButton({
    super.key,
    required this.onPressed,
    this.enabled = true,
    this.tooltip,
  });

  final VoidCallback onPressed;
  final bool enabled;
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

class InventoryFiltersSheet extends StatelessWidget {
  const InventoryFiltersSheet({
    super.key,
    required this.title,
    required this.subtitle,
    required this.actionLabel,
    required this.children,
  });

  final String title;
  final String subtitle;
  final String actionLabel;
  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    final mediaQuery = MediaQuery.of(context);
    final isCompact = mediaQuery.size.width < 640;
    final borderRadius = isCompact
        ? BorderRadius.vertical(
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

class InventoryFiltersSectionLabel extends StatelessWidget {
  const InventoryFiltersSectionLabel({super.key, required this.label});

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

class InventorySortOptionCard extends StatelessWidget {
  const InventorySortOptionCard({
    super.key,
    required this.title,
    required this.icon,
    required this.isSelected,
    required this.enabled,
    required this.onSelect,
    this.directionLabel,
    this.onToggleDirection,
    this.directionButtonKey,
    this.sortDirectionAscending,
  });

  final String title;
  final IconData icon;
  final bool isSelected;
  final bool enabled;
  final VoidCallback onSelect;
  final String? directionLabel;
  final VoidCallback? onToggleDirection;
  final Key? directionButtonKey;
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
        child: InkWell(
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

class InventorySectionExpandButton extends StatelessWidget {
  const InventorySectionExpandButton({
    super.key,
    required this.isExpanded,
    required this.semanticLabel,
    required this.onPressed,
    this.rotationKey,
    this.enabled = true,
  });

  final bool isExpanded;
  final String semanticLabel;
  final VoidCallback onPressed;
  final Key? rotationKey;
  final bool enabled;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      button: true,
      enabled: enabled,
      expanded: isExpanded,
      label: semanticLabel,
      child: InkResponse(
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

class InventoryEmptyState extends StatelessWidget {
  const InventoryEmptyState({
    super.key,
    required this.actionButton,
    this.message,
  });

  final Widget actionButton;
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
            _InventoryEmptyStateHighlightedAction(child: actionButton),
            const SizedBox(height: AppSpacing.xxl),
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
