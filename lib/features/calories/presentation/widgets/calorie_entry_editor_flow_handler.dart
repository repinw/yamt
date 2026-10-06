import 'package:material_ui/material_ui.dart';
import 'package:uuid/uuid.dart';
import 'package:yamt/core/widgets/app_snack_bar.dart';
import 'package:yamt/features/calories/domain/calorie_product_lookup_models.dart';
import 'package:yamt/features/calories/presentation/models/'
    'calorie_entry_editor_draft.dart';
import 'package:yamt/l10n/app_localizations.dart';

/// Closing the calorie editor with its new entry.
abstract final class CalorieEntryEditorFlowHandler {
  /// Displays error snackbar.
  static void showFailureSnackBar(
    ScaffoldMessengerState messenger,
    String message,
  ) {
    messenger.showAppSnackBar(message, tone: AppSnackBarTone.error);
  }

  /// Validates and builds a new entry and closes the editor with it. The
  /// caller saves the entry.
  static void returnNewEntry(
    BuildContext context, {
    required CalorieEntryEditorDraft draft,
    required String userId,
    required CalorieProductProfile? prefilledProfile,
  }) {
    final formState = draft.formKey.currentState;
    if (formState == null || !formState.validate()) {
      return;
    }

    final parsedDraft = draft.tryParse();
    if (parsedDraft == null) {
      final l10n = AppLocalizations.of(context)!;
      showFailureSnackBar(
        ScaffoldMessenger.of(context),
        l10n.caloriesInvalidNumber,
      );
      return;
    }

    final entry = draft.buildEntry(
      id: const Uuid().v4(),
      userId: userId,
      parsedDraft: parsedDraft,
      imageUrl: prefilledProfile?.imageUrl,
      nutrientDetails: prefilledProfile?.nutrientDetails,
    );
    Navigator.of(context).pop(entry);
  }
}
