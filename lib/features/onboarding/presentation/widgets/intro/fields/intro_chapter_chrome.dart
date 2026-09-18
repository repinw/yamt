import 'package:material_ui/material_ui.dart';
import 'package:yamt/core/constants/app_intro_layout_constants.dart';
import 'package:yamt/core/constants/app_layout_constants.dart';
import 'package:yamt/features/onboarding/presentation/models/'
    'calorie_intro_page.dart';
import 'package:yamt/features/onboarding/presentation/models/'
    'intro_chapter_accent.dart';

/// Top chrome of the intro: chapter counter, category, and progress segments.
class IntroChapterChrome extends StatelessWidget {
  /// Creates the intro chapter chrome.
  const new({
    required this.page,
    required this.category,
    required this.counterLabel,
    super.key,
  });

  /// Page the intro currently shows.
  final CalorieIntroPage page;

  /// Short label of the current section.
  final String category;

  /// Formatted `03 / 13` counter.
  final String counterLabel;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colors = theme.colorScheme;
    final accent = page.accent.resolve(context);

    return SafeArea(
      bottom: false,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(
          AppSpacing.lg,
          AppSpacing.md,
          AppSpacing.lg,
          0,
        ),
        child: Row(
          children: [
            Flexible(
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    counterLabel,
                    style: theme.textTheme.labelSmall?.copyWith(
                      color: accent,
                      fontWeight: FontWeight.w800,
                      letterSpacing: AppIntroLayout.kickerSpacing,
                    ),
                  ),
                  const SizedBox(width: AppSpacing.xs),
                  Flexible(
                    child: Text(
                      category.toUpperCase(),
                      overflow: TextOverflow.ellipsis,
                      style: theme.textTheme.labelSmall?.copyWith(
                        color: colors.onSurfaceVariant,
                        fontWeight: FontWeight.w700,
                        letterSpacing: AppIntroLayout.kickerSpacing,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: AppSpacing.md),
            _ProgressSegments(page: page, accent: accent),
          ],
        ),
      ),
    );
  }
}

class _ProgressSegments extends StatelessWidget {
  const new({required this.page, required this.accent});

  final CalorieIntroPage page;
  final Color accent;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;

    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        for (final candidate in CalorieIntroPage.values)
          if (candidate != CalorieIntroPage.welcome)
            Padding(
              padding: const EdgeInsets.only(left: AppSpacing.xxs),
              child: AnimatedContainer(
                duration: AppIntroLayout.selectionTransition,
                height: AppIntroLayout.progressSegmentHeight,
                width: candidate == page
                    ? AppIntroLayout.progressSegmentActiveWidth
                    : AppIntroLayout.progressSegmentWidth,
                decoration: BoxDecoration(
                  color: candidate == page
                      ? accent
                      : colors.surfaceContainerHighest,
                  borderRadius: BorderRadius.circular(AppRadius.pill),
                ),
              ),
            ),
      ],
    );
  }
}
