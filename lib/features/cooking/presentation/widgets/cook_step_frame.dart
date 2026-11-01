import 'package:material_ui/material_ui.dart';
import 'package:yamt/core/constants/app_graphit_constants.dart';
import 'package:yamt/core/constants/app_layout_constants.dart';
import 'package:yamt/core/theme/food_label_colors.dart';

/// One step of the cooking page: a kicker, title and hint, the step's
/// [children], and the main button at the bottom.
class CookStepFrame extends StatelessWidget {
  /// Creates the frame.
  const new({
    required this.title,
    required this.children,
    required this.buttonLabel,
    required this.onButton,
    this.kicker,
    this.hint,
    super.key,
  });

  /// Key of the main button.
  static const buttonKey = ValueKey<String>('cook-main-button');

  /// The small caption above [title].
  final String? kicker;

  /// The title of the step.
  final String title;

  /// A hint below [title].
  final String? hint;

  /// The content of the step.
  final List<Widget> children;

  /// The label of the main button.
  final String buttonLabel;

  /// Called by the main button; `null` turns it off.
  final VoidCallback? onButton;

  @override
  Widget build(BuildContext context) {
    final colors = FoodLabelColors.of(context);
    final textTheme = Theme.of(context).textTheme;
    final kicker = this.kicker;
    final hint = this.hint;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Expanded(
          child: ListView(
            padding: const EdgeInsets.fromLTRB(
              AppSpacing.xl,
              AppSpacing.xl,
              AppSpacing.xl,
              AppSpacing.xl,
            ),
            children: [
              if (kicker != null)
                Text(
                  kicker.toUpperCase(),
                  style: textTheme.labelMedium?.copyWith(
                    color: colors.muted,
                    letterSpacing: AppGraphit.kickerTracking,
                  ),
                ),
              Text(
                title,
                style: textTheme.headlineSmall?.copyWith(
                  color: colors.ink,
                  fontWeight: FontWeight.w800,
                ),
              ),
              if (hint != null)
                Padding(
                  padding: const EdgeInsets.only(top: AppSpacing.xs),
                  child: Text(
                    hint,
                    style: textTheme.bodyMedium?.copyWith(color: colors.muted),
                  ),
                ),
              const SizedBox(height: AppSpacing.md),
              ...children,
            ],
          ),
        ),
        DecoratedBox(
          decoration: BoxDecoration(
            border: Border(top: BorderSide(color: colors.rule)),
          ),
          child: SafeArea(
            top: false,
            child: Padding(
              padding: const EdgeInsets.all(AppSpacing.xl),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                spacing: AppSpacing.sm,
                children: [
                  FilledButton(
                    key: buttonKey,
                    onPressed: onButton,
                    style: FilledButton.styleFrom(
                      backgroundColor: colors.accent,
                      foregroundColor: colors.onAccent,
                      minimumSize: const Size.fromHeight(
                        AppGraphit.buttonHeight,
                      ),
                    ),
                    child: Text(buttonLabel),
                  ),
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }
}
