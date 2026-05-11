import 'package:flutter/material.dart';
import 'package:yamt/core/constants/app_layout_constants.dart';
import 'package:yamt/core/widgets/app_ink_well.dart';

/// Shared max width for the settings content column.
const settingsMaxWidth = 560.0;

const _settingsTileIconSize = 34.0;

/// Section wrapper for grouped settings rows.
class SettingsSection extends StatelessWidget {
  /// Creates a settings section.
  const SettingsSection({
    required this.title,
    required this.children,
    super.key,
  });

  /// Section title.
  final String title;

  /// Row widgets inside this section.
  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    return Padding(
      padding: const EdgeInsets.only(bottom: AppSpacing.lg),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.only(
              left: AppSpacing.xs,
              bottom: AppSpacing.sm,
            ),
            child: Text(
              title,
              style: Theme.of(context).textTheme.labelSmall?.copyWith(
                color: colors.primary,
                fontSize: 11,
                fontWeight: FontWeight.w900,
                letterSpacing: 0.8,
              ),
            ),
          ),
          SettingsCard(
            child: Column(
              children: [
                for (var index = 0; index < children.length; index += 1) ...[
                  children[index],
                  if (index < children.length - 1)
                    Divider(
                      height: 1,
                      indent: 58,
                      color: colors.outlineVariant.withValues(alpha: 0.34),
                    ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }
}

/// Card surface used by settings rows and header blocks.
class SettingsCard extends StatelessWidget {
  /// Creates a settings card.
  const SettingsCard({required this.child, super.key});

  /// Card contents.
  final Widget child;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return DecoratedBox(
      decoration: BoxDecoration(
        color: isDark ? colors.surfaceContainerLow : colors.surface,
        borderRadius: BorderRadius.circular(AppRadius.lg),
        border: Border.all(
          color: colors.outlineVariant.withValues(alpha: isDark ? 0.24 : 0.18),
        ),
        boxShadow: [
          BoxShadow(
            color: colors.shadow.withValues(alpha: isDark ? 0.18 : 0.08),
            blurRadius: 18,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(AppRadius.lg),
        child: child,
      ),
    );
  }
}

/// Reusable settings row.
class SettingsTile extends StatelessWidget {
  /// Creates a settings tile.
  const SettingsTile({
    required this.icon,
    required this.title,
    this.subtitle,
    this.trailing,
    this.onTap,
    this.enabled = true,
    this.showChevron = true,
    this.iconColor,
    super.key,
  });

  /// Leading icon.
  final IconData icon;

  /// Main row label.
  final String title;

  /// Optional row subtitle.
  final String? subtitle;

  /// Optional trailing widget before the chevron.
  final Widget? trailing;

  /// Tap callback.
  final VoidCallback? onTap;

  /// Whether the row is enabled.
  final bool enabled;

  /// Whether the row shows a chevron.
  final bool showChevron;

  /// Optional leading icon color override.
  final Color? iconColor;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    final resolvedIconColor = iconColor ?? colors.primary;
    final effectiveOnTap = enabled ? onTap : null;
    final opacity = enabled ? 1.0 : 0.45;

    return Material(
      color: Colors.transparent,
      child: AppInkWell(
        onTap: effectiveOnTap,
        child: Opacity(
          opacity: opacity,
          child: Padding(
            padding: const EdgeInsets.symmetric(
              horizontal: AppSpacing.md,
              vertical: AppSpacing.sm,
            ),
            child: Row(
              children: [
                Container(
                  width: _settingsTileIconSize,
                  height: _settingsTileIconSize,
                  decoration: BoxDecoration(
                    color: resolvedIconColor.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(11),
                  ),
                  child: Icon(icon, color: resolvedIconColor, size: 18),
                ),
                const SizedBox(width: AppSpacing.md),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        title,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: Theme.of(context).textTheme.titleSmall?.copyWith(
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                      if (subtitle case final subtitle?) ...[
                        const SizedBox(height: 2),
                        Text(
                          subtitle,
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          style: Theme.of(context).textTheme.bodySmall
                              ?.copyWith(
                                color: colors.onSurfaceVariant,
                                fontSize: 12,
                                fontWeight: FontWeight.w600,
                              ),
                        ),
                      ],
                    ],
                  ),
                ),
                if (trailing case final trailing?) ...[
                  const SizedBox(width: AppSpacing.sm),
                  trailing,
                ],
                if (showChevron) const SettingsChevron(),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// Settings row chevron.
class SettingsChevron extends StatelessWidget {
  /// Creates a settings chevron.
  const SettingsChevron({super.key});

  @override
  Widget build(BuildContext context) {
    return Icon(
      Icons.chevron_right_rounded,
      color: Theme.of(context).colorScheme.primary,
      size: 22,
    );
  }
}

/// Compact trailing value shown in settings rows.
class SettingsTrailingValue extends StatelessWidget {
  /// Creates a trailing settings value.
  const SettingsTrailingValue({
    required this.value,
    this.swatchColor,
    super.key,
  });

  /// Display value.
  final String value;

  /// Optional color swatch.
  final Color? swatchColor;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        if (swatchColor case final swatchColor?) ...[
          Container(
            width: 11,
            height: 11,
            decoration: BoxDecoration(
              color: swatchColor,
              shape: BoxShape.circle,
            ),
          ),
          const SizedBox(width: 6),
        ],
        Text(
          value,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: Theme.of(context).textTheme.labelMedium?.copyWith(
            color: colors.primary,
            fontWeight: FontWeight.w800,
          ),
        ),
      ],
    );
  }
}
