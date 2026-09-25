import 'package:material_ui/material_ui.dart';
import 'package:yamt/core/constants/app_layout_constants.dart';

/// Shell for manual product search modal pages.
class ManualProductSearchShell extends StatelessWidget {
  /// Creates a manual product search shell.
  const new({
    required this.body,
    required this.onClose,
    this.title,
    this.searchBar,
    super.key,
  });

  /// Dialog title.
  final String? title;

  /// Search bar area.
  final Widget? searchBar;

  /// Main content.
  final Widget body;

  /// Close action.
  final VoidCallback onClose;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    final insets = MediaQuery.viewInsetsOf(context).bottom;

    return SafeArea(
      child: SingleChildScrollView(
        padding: EdgeInsets.fromLTRB(
          AppSpacing.xl,
          AppSpacing.lg,
          AppSpacing.xl,
          AppSpacing.xl + insets,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            ManualProductDialogHeader(title: title, onClose: onClose),
            if (searchBar case final searchBar?) ...[
              const SizedBox(height: AppSpacing.lg),
              Theme(data: _buildSearchToolbarTheme(context), child: searchBar),
              const SizedBox(height: AppSpacing.lg),
              Divider(
                height: 1,
                color: colors.outlineVariant.withValues(alpha: 0.55),
              ),
            ],
            const SizedBox(height: AppSpacing.lg),
            body,
          ],
        ),
      ),
    );
  }
}

/// Header for manual product modal pages.
class ManualProductDialogHeader extends StatelessWidget {
  /// Creates a manual product dialog header.
  const new({required this.onClose, super.key, this.title});

  /// Dialog title.
  final String? title;

  /// Close action.
  final VoidCallback onClose;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;

    return Row(
      children: [
        Expanded(
          child: title == null
              ? const SizedBox.shrink()
              : Text(
                  title!,
                  style: Theme.of(context).textTheme.headlineSmall
                      ?.copyWith(fontWeight: FontWeight.w800),
                ),
        ),
        DecoratedBox(
          decoration: BoxDecoration(
            color: colors.surfaceContainerLow.withValues(alpha: 0.96),
            shape: BoxShape.circle,
            border: Border.all(
              color: colors.outlineVariant.withValues(alpha: 0.72),
            ),
          ),
          child: CloseButton(
            color: colors.onSurfaceVariant,
            onPressed: onClose,
          ),
        ),
      ],
    );
  }
}

ThemeData _buildSearchToolbarTheme(BuildContext context) {
  final theme = Theme.of(context);
  final colors = theme.colorScheme;
  final shape = RoundedRectangleBorder(
    borderRadius: BorderRadius.circular(AppRadius.xl),
  );
  final iconButtonStyle = IconButton.styleFrom(
    backgroundColor: colors.surfaceContainerLow.withValues(alpha: 0.96),
    foregroundColor: colors.onSurfaceVariant,
    side: BorderSide(color: colors.outlineVariant.withValues(alpha: 0.72)),
    shape: shape,
  ).merge(theme.iconButtonTheme.style);

  return theme.copyWith(
    inputDecorationTheme: theme.inputDecorationTheme.copyWith(
      hintStyle: theme.textTheme.bodyLarge?.copyWith(
        color: colors.onSurfaceVariant,
      ),
      filled: true,
      fillColor: colors.surfaceContainerLow.withValues(alpha: 0.96),
      prefixIconColor: colors.primary,
      suffixIconColor: colors.onSurfaceVariant,
      contentPadding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.md,
        vertical: AppSpacing.md,
      ),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(AppRadius.xl),
        borderSide: BorderSide(color: colors.outlineVariant),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(AppRadius.xl),
        borderSide: BorderSide(
          color: colors.outlineVariant.withValues(alpha: 0.72),
        ),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(AppRadius.xl),
        borderSide: BorderSide(color: colors.primary.withValues(alpha: 0.82)),
      ),
    ),
    iconButtonTheme: IconButtonThemeData(style: iconButtonStyle),
  );
}
