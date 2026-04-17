import 'package:flutter/material.dart';
import 'package:yamt/core/constants/app_ui_constants.dart';

/// Shows an inventory action picker as an elevated bottom sheet.
Future<T?> showInventoryActionPickerSheet<T>(
  BuildContext context, {
  required WidgetBuilder builder,
  bool useRootNavigator = true,
}) {
  return showModalBottomSheet<T>(
    context: context,
    useRootNavigator: useRootNavigator,
    useSafeArea: true,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    builder: builder,
  );
}

/// Shared shell for inventory action picker sheets.
class InventoryActionPickerSheet extends StatelessWidget {
  /// The inventory action picker sheet.
  const InventoryActionPickerSheet({
    required this.title,
    required this.children,
    required this.onClose,
    super.key,
    this.subtitle,
    this.footer,
  });

  /// The title.
  final String title;

  /// Optional subtitle.
  final String? subtitle;

  /// The body children.
  final List<Widget> children;

  /// Optional footer widget.
  final Widget? footer;

  /// The close action.
  final VoidCallback onClose;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    final mediaQuery = MediaQuery.of(context);
    const borderRadius = BorderRadius.vertical(
      top: Radius.circular(AppRadius.xl + AppSpacing.xs),
    );
    final subtitleText = subtitle?.trim();
    final hasSubtitle = subtitleText != null && subtitleText.isNotEmpty;
    final maxBodyHeight = mediaQuery.size.height * 0.6;

    return Align(
      alignment: Alignment.bottomCenter,
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 520),
        child: DecoratedBox(
          decoration: BoxDecoration(
            color: colors.surface,
            borderRadius: borderRadius,
          ),
          child: Padding(
            padding: AppInsets.pageLarge,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            title,
                            style: Theme.of(context).textTheme.headlineSmall
                                ?.copyWith(fontWeight: FontWeight.w800),
                          ),
                          if (hasSubtitle) ...[
                            const SizedBox(height: AppSpacing.xs),
                            Text(
                              subtitleText,
                              style: Theme.of(context).textTheme.bodyMedium
                                  ?.copyWith(
                                    color: colors.onSurfaceVariant,
                                    height: 1.35,
                                  ),
                            ),
                          ],
                        ],
                      ),
                    ),
                    const SizedBox(width: AppSpacing.md),
                    IconButton(
                      onPressed: onClose,
                      tooltip: MaterialLocalizations.of(
                        context,
                      ).closeButtonTooltip,
                      icon: Icon(Icons.close, color: colors.onSurfaceVariant),
                      style: IconButton.styleFrom(
                        backgroundColor: colors.surfaceContainerHighest,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: AppSpacing.xxxl),
                ConstrainedBox(
                  constraints: BoxConstraints(maxHeight: maxBodyHeight),
                  child: SingleChildScrollView(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        ...children,
                        if (footer != null) ...[
                          const SizedBox(height: AppSpacing.md),
                          footer!,
                        ],
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// Shared leading icon chip for inventory action picker options.
class InventoryActionPickerOptionIcon extends StatelessWidget {
  /// The inventory action picker option icon.
  const InventoryActionPickerOptionIcon({
    required this.icon,
    required this.foregroundColor,
    required this.backgroundColor,
    super.key,
  });

  /// The icon data.
  final IconData icon;

  /// The foreground color used in light theme.
  final Color foregroundColor;

  /// The background color reused for the icon in dark theme.
  final Color backgroundColor;

  @override
  Widget build(BuildContext context) {
    final brightness = Theme.of(context).brightness;
    final iconColor = brightness == Brightness.dark
        ? backgroundColor
        : foregroundColor;

    return Container(
      width: AppSizes.dialogIconContainer,
      height: AppSizes.dialogIconContainer,
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.72),
        shape: BoxShape.circle,
      ),
      alignment: Alignment.center,
      child: Icon(icon, color: iconColor),
    );
  }
}
