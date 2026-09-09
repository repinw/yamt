import 'package:flutter/material.dart';
import 'package:yamt/core/constants/app_layout_constants.dart';
import 'package:yamt/features/diary/presentation/widgets/diary_intro_dialog.dart';
import 'package:yamt/l10n/app_localizations.dart';

/// Dismissible hint banner shown in the diary during week 1 to explain goals
/// and adaptation.
class DiaryIntroBannerCard extends StatelessWidget {
  /// Creates the week 1 intro banner card.
  const DiaryIntroBannerCard({
    required this.onOpenIntro,
    required this.onDismiss,
    super.key,
  });

  /// Action when tapping to view the intro.
  final VoidCallback onOpenIntro;

  /// Action when dismissing the banner card.
  final VoidCallback onDismiss;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final colors = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;
    final isDark = colors.brightness == Brightness.dark;

    final backgroundColor = Color.alphaBlend(
      colors.primary.withValues(alpha: isDark ? 0.12 : 0.06),
      colors.surfaceContainerLow,
    );
    final borderColor = colors.primary.withValues(alpha: isDark ? 0.32 : 0.18);

    return Container(
      key: DiaryIntroDialogKeys.bannerCard,
      decoration: BoxDecoration(
        color: backgroundColor,
        borderRadius: BorderRadius.circular(AppRadius.lg),
        border: Border.all(color: borderColor),
      ),
      padding: const EdgeInsets.fromLTRB(
        AppSpacing.lg,
        AppSpacing.md,
        AppSpacing.sm,
        AppSpacing.md,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                Icons.lightbulb_outline_rounded,
                size: 20,
                color: colors.primary,
              ),
              const SizedBox(width: AppSpacing.sm),
              Expanded(
                child: Text(
                  l10n.diaryIntroBannerTitle,
                  style: textTheme.titleSmall?.copyWith(
                    fontWeight: FontWeight.w700,
                    color: colors.onSurface,
                  ),
                ),
              ),
              IconButton(
                key: DiaryIntroDialogKeys.bannerDismissButton,
                icon: const Icon(Icons.close_rounded, size: 18),
                tooltip: l10n.diaryIntroBannerDismiss,
                visualDensity: VisualDensity.compact,
                color: colors.onSurfaceVariant,
                onPressed: onDismiss,
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.xs),
          Padding(
            padding: const EdgeInsets.only(right: AppSpacing.sm),
            child: Text(
              l10n.diaryIntroBannerBody,
              style: textTheme.bodySmall?.copyWith(
                color: colors.onSurfaceVariant,
                height: 1.35,
              ),
            ),
          ),
          const SizedBox(height: AppSpacing.md),
          Align(
            alignment: Alignment.centerLeft,
            child: FilledButton.tonalIcon(
              key: DiaryIntroDialogKeys.bannerActionButton,
              style: FilledButton.styleFrom(
                visualDensity: VisualDensity.compact,
                padding: const EdgeInsets.symmetric(
                  horizontal: AppSpacing.md,
                  vertical: AppSpacing.xs,
                ),
              ),
              onPressed: onOpenIntro,
              icon: const Icon(Icons.auto_stories_outlined, size: 16),
              label: Text(l10n.diaryIntroBannerAction),
            ),
          ),
        ],
      ),
    );
  }
}
