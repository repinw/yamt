import 'package:material_ui/material_ui.dart';
import 'package:yamt/core/constants/app_layout_constants.dart';
import 'package:yamt/features/whats_new/domain/whats_new_release.dart';
import 'package:yamt/l10n/app_localizations.dart';

/// Opens the sheet with the [notes] of [version].
Future<void> showWhatsNewSheet(
  BuildContext context, {
  required String version,
  required WhatsNewNotes notes,
}) {
  return showModalBottomSheet<void>(
    context: context,
    useRootNavigator: true,
    isScrollControlled: true,
    useSafeArea: true,
    showDragHandle: true,
    builder: (context) => WhatsNewSheet(version: version, notes: notes),
  );
}

/// What is new, better, and fixed in one version.
class WhatsNewSheet extends StatelessWidget {
  /// Creates the sheet for the [notes] of [version].
  const new({required this.version, required this.notes, super.key});

  /// Key of the sheet's list.
  static const listKey = Key('whats_new_sheet');

  /// The version, such as `3.7.0`.
  final String version;

  /// The notes in the device language.
  final WhatsNewNotes notes;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final textTheme = Theme.of(context).textTheme;
    return ListView(
      key: listKey,
      shrinkWrap: true,
      padding: const EdgeInsets.fromLTRB(
        AppSpacing.xl,
        0,
        AppSpacing.xl,
        AppSpacing.xxl,
      ),
      children: [
        Text(l10n.whatsNewTitle(version), style: textTheme.titleLarge),
        for (final (title, points) in [
          (l10n.whatsNewAdded, notes.added),
          (l10n.whatsNewImproved, notes.improved),
          (l10n.whatsNewFixed, notes.fixed),
        ])
          if (points.isNotEmpty) ...[
            const SizedBox(height: AppSpacing.xl),
            Text(title, style: textTheme.titleMedium),
            for (final point in points)
              Padding(
                padding: const EdgeInsets.only(top: AppSpacing.xs),
                child: Text(l10n.whatsNewPoint(point)),
              ),
          ],
      ],
    );
  }
}
