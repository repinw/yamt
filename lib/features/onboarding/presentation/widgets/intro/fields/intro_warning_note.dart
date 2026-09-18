import 'package:material_ui/material_ui.dart';
import 'package:yamt/core/constants/app_intro_layout_constants.dart';
import 'package:yamt/core/constants/app_layout_constants.dart';

/// Warning callout of the onboarding intro.
///
/// Glass surface with an error-colored edge on the left, so a warning stands
/// out without leaving the intro's look.
class IntroWarningNote extends StatelessWidget {
  /// Creates a warning note.
  const new({required this.message, super.key});

  /// Warning text.
  final String message;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colors = theme.colorScheme;

    return DecoratedBox(
      decoration: BoxDecoration(
        color: colors.errorContainer.withValues(
          alpha: AppIntroLayout.glassOpacity,
        ),
        borderRadius: BorderRadius.circular(AppRadius.md),
        border: Border(
          left: BorderSide(
            color: colors.error,
            width: AppIntroLayout.choiceBorderWidth,
          ),
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.md),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(
              Icons.warning_amber_rounded,
              size: AppIntroLayout.choiceIcon,
              color: colors.error,
            ),
            const SizedBox(width: AppSpacing.sm),
            Expanded(
              child: Text(
                message,
                style: theme.textTheme.bodySmall?.copyWith(
                  color: colors.onErrorContainer,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
