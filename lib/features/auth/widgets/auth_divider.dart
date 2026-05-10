import 'package:flutter/material.dart';
import 'package:yamt/core/constants/app_layout_constants.dart';
import 'package:yamt/features/shared/widgets/auth_ui_constants.dart';

/// Divider with centered auth section label.
class AuthDivider extends StatelessWidget {
  /// Creates an auth divider.
  const AuthDivider({required this.label, super.key});

  /// Center label text.
  final String label;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;

    return Row(
      children: [
        Expanded(
          child: DecoratedBox(
            decoration: AppAuthSurfaces.divider(colors),
            child: const SizedBox(height: 1),
          ),
        ),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md),
          child: Text(
            label.toUpperCase(),
            style: Theme.of(
              context,
            ).textTheme.labelSmall?.copyWith(color: colors.outlineVariant),
          ),
        ),
        Expanded(
          child: DecoratedBox(
            decoration: AppAuthSurfaces.divider(colors),
            child: const SizedBox(height: 1),
          ),
        ),
      ],
    );
  }
}
