import 'package:material_ui/material_ui.dart';
import 'package:yamt/core/constants/app_layout_constants.dart';
import 'package:yamt/features/onboarding/domain/intro_activity_option.dart';
import 'package:yamt/features/onboarding/presentation/models/'
    'intro_input_page_args.dart';
import 'package:yamt/features/onboarding/presentation/widgets/intro/fields/'
    'intro_choice_card.dart';
import 'package:yamt/features/onboarding/presentation/widgets/intro/fields/'
    'intro_page_content.dart';
import 'package:yamt/l10n/app_localizations.dart';

/// Intro page that asks how active a typical week is, training included.
class IntroActivityPage extends StatelessWidget {
  /// Creates the activity level intro page.
  const new({required this.args, super.key});

  /// Chapter styling and the calculator form.
  final IntroInputPageArgs args;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final selected = IntroActivityOption.fromCalorieOption(
      args.state.activityLevelOption,
    );

    return IntroPageContent(
      kicker: args.kicker,
      accent: args.accent,
      title: l10n.introActivityTitle,
      subtitle: l10n.introActivitySubtitle,
      children: [
        const SizedBox(height: AppSpacing.lg),
        for (final option in IntroActivityOption.values)
          Padding(
            padding: const EdgeInsets.only(bottom: AppSpacing.xs),
            child: IntroChoiceCard(
              icon: _icon(option),
              title: _title(l10n, option),
              subtitle: _description(l10n, option),
              isSelected: selected == option,
              onTap: () =>
                  args.notifier.updateActivityLevel(option.calorieOption),
            ),
          ),
      ],
    );
  }

  IconData _icon(IntroActivityOption option) {
    return switch (option) {
      IntroActivityOption.sitting => Icons.chair_outlined,
      IntroActivityOption.light => Icons.directions_walk,
      IntroActivityOption.onFeet => Icons.directions_run,
      IntroActivityOption.hardLabour => Icons.construction_outlined,
    };
  }

  String _title(AppLocalizations l10n, IntroActivityOption option) {
    return switch (option) {
      IntroActivityOption.sitting => l10n.introActivitySittingTitle,
      IntroActivityOption.light => l10n.introActivityLightTitle,
      IntroActivityOption.onFeet => l10n.introActivityOnFeetTitle,
      IntroActivityOption.hardLabour => l10n.introActivityHardLabourTitle,
    };
  }

  String _description(AppLocalizations l10n, IntroActivityOption option) {
    return switch (option) {
      IntroActivityOption.sitting => l10n.introActivitySittingBody,
      IntroActivityOption.light => l10n.introActivityLightBody,
      IntroActivityOption.onFeet => l10n.introActivityOnFeetBody,
      IntroActivityOption.hardLabour => l10n.introActivityHardLabourBody,
    };
  }
}
