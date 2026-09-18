import 'package:material_ui/material_ui.dart';
import 'package:yamt/core/constants/app_intro_layout_constants.dart';
import 'package:yamt/core/constants/app_layout_constants.dart';
import 'package:yamt/features/onboarding/presentation/widgets/intro/fields/'
    'intro_chapter_header.dart';
import 'package:yamt/features/onboarding/presentation/widgets/intro/fields/'
    'intro_scroll_body.dart';

/// Input page that fits the screen without scrolling.
///
/// The chapter header sits on top, the [footer] sits directly above the intro
/// controls, and the pickers in between take whatever height is left. On very
/// short screens or with large text the page falls back to scrolling, and the
/// pickers keep their default height.
class IntroFillPageContent extends StatelessWidget {
  /// Creates a filling input page.
  const new({
    required this.kicker,
    required this.title,
    required this.subtitle,
    required this.accent,
    required this.body,
    required this.minFillHeight,
    this.footer,
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

  /// Builds the pickers. `fill` is true when they get the remaining height.
  final Widget Function({required bool fill}) body;

  /// Message pinned right above the intro controls.
  final Widget? footer;

  /// Height the pickers need at least to fill instead of scrolling.
  final double minFillHeight;

  static const _padding = EdgeInsets.only(
    top: AppIntroLayout.chromeClearance,
    bottom: AppIntroLayout.controlsClearance,
    left: AppSpacing.lg,
    right: AppSpacing.lg,
  );

  @override
  Widget build(BuildContext context) {
    final header = IntroChapterHeader(
      kicker: kicker,
      title: title,
      body: subtitle,
      accent: accent,
    );
    final note = footer;

    return LayoutBuilder(
      builder: (context, constraints) {
        final fits =
            constraints.maxHeight >= AppIntroLayout.fillLayoutMinHeight &&
            MediaQuery.textScalerOf(context).scale(1) <=
                AppIntroLayout.fillLayoutMaxTextScale;
        if (!fits) {
          return IntroScrollBody(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              header,
              const SizedBox(height: AppSpacing.xl),
              body(fill: false),
              if (note != null) ...[
                const SizedBox(height: AppSpacing.md),
                note,
              ],
            ],
          );
        }

        return Padding(
          padding: _padding,
          child: Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(
                maxWidth: AppSizes.narrowContentMaxWidth,
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  header,
                  const SizedBox(height: AppSpacing.xl),
                  Expanded(
                    child: LayoutBuilder(
                      builder: (context, area) {
                        // Too little room left: only the pickers scroll,
                        // header and footer stay where they are.
                        if (area.maxHeight < minFillHeight) {
                          return SingleChildScrollView(
                            child: body(fill: false),
                          );
                        }
                        return body(fill: true);
                      },
                    ),
                  ),
                  if (note != null) ...[
                    const SizedBox(height: AppSpacing.md),
                    note,
                  ],
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}
