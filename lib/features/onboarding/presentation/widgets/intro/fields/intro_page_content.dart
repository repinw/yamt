import 'package:material_ui/material_ui.dart';
import 'package:yamt/features/onboarding/presentation/widgets/intro/fields/'
    'intro_chapter_header.dart';
import 'package:yamt/features/onboarding/presentation/widgets/intro/fields/'
    'intro_scroll_body.dart';

/// Shared content shell for the calorie-goal onboarding input pages.
class IntroPageContent extends StatelessWidget {
  /// Creates an onboarding page with the standard chapter header.
  const new({
    required this.kicker,
    required this.title,
    required this.subtitle,
    required this.accent,
    required this.children,
    super.key,
  });

  /// Kicker above the headline.
  final String kicker;

  /// Page title.
  final String title;

  /// Page subtitle.
  final String subtitle;

  /// Accent color of this chapter.
  final Color accent;

  /// Widgets shown below the standard header.
  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    return IntroScrollBody(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        IntroChapterHeader(
          kicker: kicker,
          title: title,
          body: subtitle,
          accent: accent,
        ),
        ...children,
      ],
    );
  }
}
