import 'package:material_ui/material_ui.dart';
import 'package:yamt/core/constants/app_intro_layout_constants.dart';
import 'package:yamt/core/constants/app_layout_constants.dart';
import 'package:yamt/features/onboarding/presentation/widgets/intro/fields/'
    'intro_chapter_header.dart';
import 'package:yamt/features/onboarding/presentation/widgets/intro/fields/'
    'intro_scroll_body.dart';

/// Shared layout for the explaining pages of the calorie onboarding intro.
class IntroStoryPage extends StatelessWidget {
  /// Creates an intro story page.
  const new({
    required this.icon,
    required this.kicker,
    required this.title,
    required this.body,
    required this.accent,
    this.titleHighlight,
    this.footnote,
    super.key,
  });

  /// Icon shown inside the badge.
  final IconData icon;

  /// Kicker above the headline.
  final String kicker;

  /// Page headline.
  final String title;

  /// Part of the headline drawn in the accent color.
  final String? titleHighlight;

  /// Explaining text below the headline.
  final String body;

  /// Accent color of this chapter.
  final Color accent;

  /// Optional accent-colored closing line.
  final String? footnote;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final note = footnote;

    return IntroScrollBody(
      children: [
        Container(
          width: AppIntroLayout.storyBadge,
          height: AppIntroLayout.storyBadge,
          decoration: BoxDecoration(
            color: accent.withValues(alpha: AppIntroLayout.storyBadgeOpacity),
            shape: BoxShape.circle,
            border: Border.all(
              color: accent.withValues(
                alpha: AppIntroLayout.storyBadgeBorderOpacity,
              ),
              width: AppIntroLayout.cardBorderWidth,
            ),
          ),
          child: Icon(icon, size: AppIntroLayout.storyIcon, color: accent),
        ),
        const SizedBox(height: AppSpacing.xxxxl),
        IntroChapterHeader(
          kicker: kicker,
          title: title,
          titleHighlight: titleHighlight,
          body: body,
          accent: accent,
          alignment: CrossAxisAlignment.center,
        ),
        if (note != null) ...[
          const SizedBox(height: AppSpacing.lg),
          Text(
            note,
            textAlign: TextAlign.center,
            style: theme.textTheme.bodyMedium?.copyWith(
              color: accent,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ],
    );
  }
}
