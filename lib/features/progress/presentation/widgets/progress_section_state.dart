import 'package:material_ui/material_ui.dart';
import 'package:yamt/core/constants/app_layout_constants.dart';
import 'package:yamt/core/constants/app_progress_constants.dart';
import 'package:yamt/core/theme/food_label_colors.dart';
import 'package:yamt/l10n/app_localizations.dart';

/// Placeholder of a Fortschritt section while its data loads.
class ProgressSectionLoading extends StatelessWidget {
  /// Creates the loading placeholder.
  const new({super.key});

  @override
  Widget build(BuildContext context) {
    return const SizedBox(
      height: AppProgress.chartHeight,
      child: Center(child: CircularProgressIndicator.adaptive()),
    );
  }
}

/// Message of a Fortschritt section whose data failed to load.
class ProgressSectionError extends StatelessWidget {
  /// Creates the error message.
  const new({super.key});

  @override
  Widget build(BuildContext context) {
    return ProgressSectionNote(
      text: AppLocalizations.of(context)!.progressLoadFailed,
    );
  }
}

/// A short muted note inside a Fortschritt section, such as an empty state.
class ProgressSectionNote extends StatelessWidget {
  /// Creates the note.
  const new({required this.text, super.key});

  /// The note.
  final String text;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: AppSpacing.md),
      child: Text(
        text,
        style: Theme.of(context).textTheme.bodyMedium
            ?.copyWith(color: FoodLabelColors.of(context).muted),
      ),
    );
  }
}
