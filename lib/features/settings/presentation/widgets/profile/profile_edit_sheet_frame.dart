import 'dart:async';

import 'package:material_ui/material_ui.dart';
import 'package:yamt/core/constants/app_layout_constants.dart';
import 'package:yamt/core/constants/app_sizes.dart';
import 'package:yamt/core/theme/food_label_colors.dart';
import 'package:yamt/features/settings/presentation/widgets/profile/profile_kicker.dart';
import 'package:yamt/l10n/app_localizations.dart';

/// Opens a profile editor that [builder] builds as a bottom sheet.
Future<void> showProfileEditSheet(
  BuildContext context, {
  required WidgetBuilder builder,
}) {
  return showModalBottomSheet<void>(
    context: context,
    useRootNavigator: true,
    useSafeArea: true,
    isScrollControlled: true,
    showDragHandle: true,
    backgroundColor: FoodLabelColors.of(context).card,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(AppRadius.xl)),
    ),
    builder: builder,
  );
}

/// The layout of a profile editor: caption and title, the input, what the
/// edit changes, and the cancel and apply buttons. Apply saves the edit and
/// closes the sheet, or tells that saving failed.
class ProfileEditSheetFrame extends StatefulWidget {
  /// Creates the frame.
  const new({
    required this.kicker,
    required this.title,
    required this.input,
    required this.effect,
    required this.canApply,
    required this.onSave,
    super.key,
  });

  /// Caption above the title.
  final String kicker;

  /// Name of the edited fact.
  final String title;

  /// Where the user changes the value.
  final Widget input;

  /// What the edit changes, or `null` before there is a change.
  final Widget? effect;

  /// Whether the apply button is enabled.
  final bool canApply;

  /// Saves the edit and reports whether it was stored.
  final Future<bool> Function() onSave;

  /// Stable key of the apply button.
  static const applyButtonKey = ValueKey<String>('profile-edit-apply');

  @override
  State<ProfileEditSheetFrame> createState() => _FrameState();
}

class _FrameState extends State<ProfileEditSheetFrame> {
  var _saveFailed = false;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final theme = Theme.of(context);
    final effect = widget.effect;
    return Padding(
      padding: EdgeInsets.only(bottom: MediaQuery.viewInsetsOf(context).bottom),
      child: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(
          AppSpacing.md,
          0,
          AppSpacing.md,
          AppSpacing.lg,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          spacing: AppSpacing.md,
          children: [
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                ProfileKicker(text: widget.kicker),
                Text(
                  widget.title,
                  style: theme.textTheme.headlineSmall?.copyWith(
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ],
            ),
            widget.input,
            ?effect,
            if (_saveFailed)
              Text(
                l10n.profileEditSaveFailed,
                style: theme.textTheme.bodySmall?.copyWith(
                  color: theme.colorScheme.error,
                ),
              ),
            _Actions(canApply: widget.canApply, onApply: _apply),
          ],
        ),
      ),
    );
  }

  Future<void> _apply() async {
    setState(() => _saveFailed = false);
    final saved = await widget.onSave();
    if (!mounted) {
      return;
    }
    if (saved) {
      Navigator.of(context).pop();
      return;
    }
    setState(() => _saveFailed = true);
  }
}

class _Actions extends StatelessWidget {
  const new({required this.canApply, required this.onApply});

  final bool canApply;
  final Future<void> Function() onApply;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final label = FoodLabelColors.of(context);
    final textTheme = Theme.of(context).textTheme;
    final shape = RoundedRectangleBorder(
      borderRadius: BorderRadius.circular(AppRadius.md),
    );
    return Row(
      spacing: AppSpacing.sm,
      children: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          style: TextButton.styleFrom(
            foregroundColor: label.ink,
            minimumSize: const Size(0, AppSizes.minTapTarget),
            shape: shape,
            textStyle: textTheme.titleSmall?.copyWith(
              fontWeight: FontWeight.w700,
              decoration: TextDecoration.underline,
            ),
          ),
          child: Text(l10n.profileEditCancel),
        ),
        Expanded(
          child: FilledButton(
            key: ProfileEditSheetFrame.applyButtonKey,
            onPressed: canApply ? () => unawaited(onApply()) : null,
            style: FilledButton.styleFrom(
              backgroundColor: label.accent,
              foregroundColor: label.onAccent,
              minimumSize: const Size.fromHeight(AppSizes.minTapTarget),
              shape: shape,
              textStyle: textTheme.titleSmall?.copyWith(
                fontWeight: FontWeight.w700,
              ),
            ),
            child: Text(l10n.profileEditApply),
          ),
        ),
      ],
    );
  }
}
