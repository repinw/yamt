import 'package:flutter/material.dart';
import 'package:yamt/core/constants/app_layout_constants.dart';

/// Displays a recipe section heading with an icon.
class AiChefRecipeSectionTitle extends StatelessWidget {
  /// Creates recipe section title.
  const AiChefRecipeSectionTitle({
    required this.title,
    required this.icon,
    super.key,
  });

  /// Heading text.
  final String title;

  /// Leading icon.
  final IconData icon;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colors = theme.colorScheme;

    return Row(
      children: [
        Icon(icon, size: 20, color: colors.primary),
        const SizedBox(width: AppSpacing.xs),
        Expanded(
          child: Text(
            title,
            style: theme.textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.w900,
              color: colors.onSurface,
            ),
          ),
        ),
      ],
    );
  }
}
