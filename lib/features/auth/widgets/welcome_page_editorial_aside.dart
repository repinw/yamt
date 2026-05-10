import 'package:flutter/material.dart';
import 'package:yamt/core/constants/app_layout_constants.dart';
import 'package:yamt/features/shared/widgets/credential_form_ui_constants.dart';
import 'package:yamt/l10n/app_localizations.dart';

/// Editorial side panel for the wide auth welcome layout.
class EditorialAside extends StatelessWidget {
  /// Creates the editorial side panel.
  const EditorialAside({required this.isLoginMode, super.key});

  /// Whether the parent welcome page is showing login mode.
  final bool isLoginMode;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;
    final l10n = AppLocalizations.of(context)!;

    return DecoratedBox(
      decoration: CredentialFormSurfaces.editorialAside(colors),
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.xxxxl),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              l10n.authBrandSubtitle.toUpperCase(),
              style: textTheme.labelSmall?.copyWith(color: colors.primary),
            ),
            const SizedBox(height: AppSpacing.md),
            Text(
              isLoginMode ? l10n.authBrandTitle : l10n.authRegisterTitle,
              style: textTheme.displaySmall?.copyWith(color: colors.onSurface),
            ),
            const SizedBox(height: AppSpacing.md),
            Text(
              isLoginMode ? l10n.authBrandSubtitle : l10n.authRegisterSubtitle,
              style: textTheme.bodyLarge?.copyWith(
                color: colors.onSurfaceVariant,
              ),
            ),
            const SizedBox(height: AppSpacing.xxxxl),
            Expanded(
              child: DecoratedBox(
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(
                    CredentialFormUi.cardRadius,
                  ),
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [
                      colors.primaryContainer.withValues(alpha: 0.4),
                      colors.surfaceContainerLowest,
                    ],
                  ),
                ),
                child: Stack(
                  fit: StackFit.expand,
                  children: [
                    Positioned(
                      top: -40,
                      right: -30,
                      child: DecoratedBox(
                        decoration: BoxDecoration(
                          color: colors.primaryContainer.withValues(alpha: 0.4),
                          shape: BoxShape.circle,
                        ),
                        child: const SizedBox(width: 180, height: 180),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
