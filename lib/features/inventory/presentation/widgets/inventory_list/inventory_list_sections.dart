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
    required this.children,
  });

  final String title;
  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    final bottomSheetFabClearance =
        AppInventoryEditorial.contextFabSize + AppSpacing.xxxxl + AppSpacing.xl;

    return SafeArea(
      top: false,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(
          AppSpacing.xl,
          AppSpacing.lg,
          AppSpacing.xl,
          0,
        ),
        child: Padding(
          padding: EdgeInsets.only(bottom: bottomSheetFabClearance),
          child: DecoratedBox(
            decoration: AppInventoryEditorialSurfaces.liftedCardDecoration(
              colors,
              borderRadius: BorderRadius.circular(
                AppInventoryEditorial.cardRadius,
              ),
            ),
            child: Padding(
              padding: const EdgeInsets.all(AppSpacing.xl),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(title, style: Theme.of(context).textTheme.titleLarge),
                  const SizedBox(height: AppSpacing.lg),
                  ...children,
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class InventoryFilterRadioOption<T> extends StatelessWidget {
  const InventoryFilterRadioOption({
    super.key,
    required this.value,
    required this.groupValue,
    required this.enabled,
    required this.label,
    required this.onChanged,
  });

  final T value;
  final T groupValue;
  final bool enabled;
  final String label;
  final ValueChanged<T> onChanged;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    final isSelected = value == groupValue;

    return MergeSemantics(
      child: Semantics(
        selected: isSelected,
        child: InkWell(
          onTap: enabled ? () => onChanged(value) : null,
          borderRadius: BorderRadius.circular(AppRadius.lg),
          child: Row(
            children: [
              Expanded(
                child: Text(
                  label,
                  style: Theme.of(context).textTheme.labelLarge?.copyWith(
                    color: enabled
                        ? colors.onSurface
                        : colors.onSurface.withValues(alpha: 0.5),
                  ),
                ),
              ),
              const SizedBox(width: AppSpacing.sm),
              Icon(
                isSelected
                    ? Icons.radio_button_checked_rounded
                    : Icons.radio_button_unchecked_rounded,
                size: 20,
                color: enabled
                    ? (isSelected ? colors.primary : colors.onSurfaceVariant)
                    : colors.onSurface.withValues(alpha: 0.5),
              ),
            ],
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
