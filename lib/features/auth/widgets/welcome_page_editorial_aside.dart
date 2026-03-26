part of 'package:yamt/features/auth/welcome_page.dart';

class _EditorialAside extends StatelessWidget {
  const _EditorialAside({required this.isLoginMode});

  final bool isLoginMode;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;
    final l10n = AppLocalizations.of(context)!;

    return DecoratedBox(
      decoration: AppAuthSurfaces.editorialAside(colors),
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
                  borderRadius: BorderRadius.circular(AppAuthUi.cardRadius),
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
