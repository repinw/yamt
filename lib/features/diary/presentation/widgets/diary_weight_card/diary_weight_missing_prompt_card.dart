import 'package:flutter/material.dart';
import 'package:yamt/core/constants/app_layout_constants.dart';
import 'package:yamt/features/diary/presentation/diary_theme.dart';
import 'package:yamt/l10n/app_localizations.dart';

/// Prompt shown when the selected diary day has no weight entry.
class DiaryWeightMissingPromptCard extends StatelessWidget {
  /// Creates a missing weight prompt.
  const DiaryWeightMissingPromptCard({
    required this.onTrack,
    required this.onDismiss,
    super.key,
  });

  /// Opens the weight entry dialog.
  final VoidCallback onTrack;

  /// Dismisses the prompt for the selected day.
  final VoidCallback onDismiss;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final colors = Theme.of(context).colorScheme;
    final isDark = colors.brightness == Brightness.dark;
    final accentColors = DiaryAccentColors.of(context);
    final titleColor = accentColors.activityFor(colors.brightness);
    final textColor = accentColors.activityTextFor(colors.brightness);
    final backgroundColor = Color.alphaBlend(
      titleColor.withValues(alpha: isDark ? 0.16 : 0.08),
      colors.surfaceContainerLow,
    );
    final borderColor = titleColor.withValues(alpha: isDark ? 0.38 : 0.24);

    return DecoratedBox(
      decoration: BoxDecoration(
        color: backgroundColor,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: borderColor),
        boxShadow: [
          BoxShadow(
            color: accentColors.activity.withValues(
              alpha: isDark ? 0.1 : 0.15,
            ),
            blurRadius: 24,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(24),
        child: Stack(
          children: [
            Positioned(
              top: -16,
              right: -16,
              child: Icon(
                Icons.trending_down_rounded,
                size: 82,
                color: Colors.white.withValues(alpha: isDark ? 0.04 : 0.35),
              ),
            ),
            Positioned(
              top: AppSpacing.lg,
              right: AppSpacing.lg,
              child: Icon(Icons.add_rounded, color: titleColor, size: 18),
            ),
            Padding(
              padding: const EdgeInsets.all(AppSpacing.xl),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(
                        Icons.error_outline_rounded,
                        color: titleColor,
                        size: 18,
                      ),
                      const SizedBox(width: AppSpacing.xs),
                      Expanded(
                        child: Text(
                          l10n.diaryWeightTitle,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: Theme.of(context).textTheme.labelSmall
                              ?.copyWith(
                                color: Theme.of(
                                  context,
                                ).colorScheme.onSurfaceVariant,
                                fontWeight: FontWeight.w900,
                                letterSpacing: 0.8,
                              ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: AppSpacing.sm),
                  Text(
                    l10n.diaryWeightMissingPrompt,
                    style: Theme.of(context).textTheme.labelMedium?.copyWith(
                      color: textColor,
                      fontWeight: FontWeight.w900,
                      height: 1.25,
                    ),
                  ),
                  const SizedBox(height: AppSpacing.md),
                  Row(
                    children: [
                      Expanded(
                        child: TextButton(
                          onPressed: onTrack,
                          style: TextButton.styleFrom(
                            foregroundColor: titleColor,
                            padding: EdgeInsets.zero,
                            alignment: Alignment.centerLeft,
                            textStyle: Theme.of(context).textTheme.labelSmall
                                ?.copyWith(
                                  fontWeight: FontWeight.w900,
                                  letterSpacing: 0.8,
                                ),
                          ),
                          child: Text(l10n.diaryWeightTrackNowAction),
                        ),
                      ),
                      const SizedBox(width: AppSpacing.xs),
                      TextButton(
                        onPressed: onDismiss,
                        style: TextButton.styleFrom(
                          foregroundColor: textColor,
                          backgroundColor: accentColors.activity.withValues(
                            alpha: isDark ? 0.18 : 0.12,
                          ),
                          minimumSize: const Size(44, 30),
                          padding: const EdgeInsets.symmetric(
                            horizontal: AppSpacing.sm,
                          ),
                          textStyle: Theme.of(context).textTheme.labelSmall
                              ?.copyWith(fontWeight: FontWeight.w900),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(8),
                          ),
                        ),
                        child: Text(l10n.diaryOkAction),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
