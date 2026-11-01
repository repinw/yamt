import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:material_ui/material_ui.dart';
import 'package:yamt/core/constants/app_layout_constants.dart';
import 'package:yamt/core/widgets/app_responsive_viewport.dart';
import 'package:yamt/core/widgets/app_snack_bar.dart';
import 'package:yamt/features/data_export/application/data_export_labels.dart';
import 'package:yamt/features/data_export/application/data_export_report_provider.dart';
import 'package:yamt/features/data_export/domain/data_export_purpose.dart';
import 'package:yamt/features/data_export/domain/data_export_range.dart';
import 'package:yamt/features/data_export/domain/data_export_report.dart';
import 'package:yamt/features/data_export/presentation/controllers/data_export_share_controller.dart';
import 'package:yamt/features/data_export/presentation/widgets/data_export_purpose_tile.dart';
import 'package:yamt/features/data_export/presentation/widgets/data_export_range_chips.dart';
import 'package:yamt/features/progress/domain/progress_period.dart';
import 'package:yamt/l10n/app_localizations.dart';

/// Exports the food, goals, weight, and TDEE of a period as files for the
/// share sheet: picked by who the export is for and by the days it covers.
class DataExportPage extends ConsumerStatefulWidget {
  /// Creates the export page.
  const new({super.key});

  /// Key of the share button.
  static const shareKey = ValueKey<String>('data-export-share');

  /// Key of the button that copies the AI text.
  static const copyKey = ValueKey<String>('data-export-copy');

  /// Key of the line that says what the export holds.
  static const summaryKey = ValueKey<String>('data-export-summary');

  @override
  ConsumerState<DataExportPage> createState() => _DataExportPageState();
}

class _DataExportPageState extends ConsumerState<DataExportPage> {
  DataExportPurpose _purpose = DataExportPurpose.ai;
  DataExportRange _range = const DataExportGoalRange(ProgressScope.goal);

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final textTheme = Theme.of(context).textTheme;
    final report = ref.watch(dataExportReportProvider(_range));
    final header = textTheme.labelLarge?.copyWith(fontWeight: FontWeight.w700);
    return Scaffold(
      appBar: AppBar(title: Text(l10n.dataExportTitle)),
      body: ListView(
        padding: responsivePagePadding(
          context,
          top: AppSpacing.md,
          bottom: AppSpacing.xl,
        ),
        children: [
          Text(l10n.dataExportPurposeHeader, style: header),
          const SizedBox(height: AppSpacing.xs),
          for (final purpose in DataExportPurpose.values) ...[
            DataExportPurposeTile(
              purpose: purpose,
              selected: purpose == _purpose,
              onSelected: (purpose) => setState(() => _purpose = purpose),
            ),
            const SizedBox(height: AppSpacing.xs),
          ],
          const SizedBox(height: AppSpacing.xl),
          Text(l10n.dataExportRangeHeader, style: header),
          const SizedBox(height: AppSpacing.xs),
          DataExportRangeChips(
            selected: _range,
            onSelected: (range) => setState(() => _range = range),
          ),
          const SizedBox(height: AppSpacing.xs),
          _Summary(report: report),
        ],
      ),
      bottomNavigationBar: _ShareBar(purpose: _purpose, report: report),
    );
  }
}

class _Summary extends StatelessWidget {
  const new({required this.report});

  final AsyncValue<DataExportReport> report;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final theme = Theme.of(context);
    final style = theme.textTheme.bodySmall?.copyWith(
      color: theme.colorScheme.onSurfaceVariant,
    );
    final labels = DataExportLabels(
      l10n,
      Localizations.localeOf(context).toString(),
    );
    return report.when(
      data: (report) => Text(
        l10n.dataExportSummary(
          labels.date(report.from),
          labels.date(report.to),
          report.days.length,
          report.entryCount,
          report.weighingCount,
        ),
        key: DataExportPage.summaryKey,
        style: style,
      ),
      loading: () => const LinearProgressIndicator(),
      error: (_, _) => Text(
        l10n.dataExportLoadFailed,
        style: style?.copyWith(color: theme.colorScheme.error),
      ),
    );
  }
}

class _ShareBar extends ConsumerWidget {
  const new({required this.purpose, required this.report});

  final DataExportPurpose purpose;

  final AsyncValue<DataExportReport> report;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context)!;
    final theme = Theme.of(context);
    final isSharing = ref.watch(dataExportShareControllerProvider).isLoading;
    final loaded = report.value;
    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(
          AppSpacing.xl,
          AppSpacing.xs,
          AppSpacing.xl,
          AppSpacing.xl,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              l10n.dataExportPrivacyNote,
              style: theme.textTheme.bodySmall?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
            const SizedBox(height: AppSpacing.md),
            // The Builder's context is the button's, which anchors the
            // share sheet on tablets.
            Row(
              spacing: AppSpacing.sm,
              children: [
                // Some AI apps take no file; the text pastes anywhere.
                if (purpose == DataExportPurpose.ai)
                  OutlinedButton.icon(
                    key: DataExportPage.copyKey,
                    onPressed: loaded == null
                        ? null
                        : () => unawaited(_copy(context, ref, loaded)),
                    icon: const Icon(Icons.copy_rounded),
                    label: Text(l10n.dataExportCopy),
                  ),
                Expanded(
                  child: Builder(
                    builder: (buttonContext) => FilledButton(
                      key: DataExportPage.shareKey,
                      onPressed: loaded == null || isSharing
                          ? null
                          : () => unawaited(_share(buttonContext, ref, loaded)),
                      child: isSharing
                          ? const SizedBox.square(
                              dimension: AppSpacing.xl,
                              child: CircularProgressIndicator(),
                            )
                          : Text(
                              purpose.saves
                                  ? l10n.dataExportSave
                                  : l10n.dataExportShare,
                            ),
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _copy(
    BuildContext context,
    WidgetRef ref,
    DataExportReport report,
  ) async {
    final l10n = AppLocalizations.of(context)!;
    final outcome = await ref
        .read(dataExportShareControllerProvider.notifier)
        .copy(
          report: report,
          labels: DataExportLabels(
            l10n,
            Localizations.localeOf(context).toString(),
          ),
        );
    if (!context.mounted) return;
    _showOutcome(context, outcome);
  }

  Future<void> _share(
    BuildContext context,
    WidgetRef ref,
    DataExportReport report,
  ) async {
    final l10n = AppLocalizations.of(context)!;
    final box = context.findRenderObject() as RenderBox?;
    final outcome = await ref
        .read(dataExportShareControllerProvider.notifier)
        .share(
          report: report,
          purpose: purpose,
          labels: DataExportLabels(
            l10n,
            Localizations.localeOf(context).toString(),
          ),
          origin: box == null
              ? null
              : box.localToGlobal(Offset.zero) & box.size,
        );
    if (!context.mounted) return;
    _showOutcome(context, outcome);
  }

  void _showOutcome(BuildContext context, DataExportOutcome outcome) {
    final l10n = AppLocalizations.of(context)!;
    final messenger = ScaffoldMessenger.of(context);
    switch (outcome) {
      case DataExportOutcome.copied:
        messenger.showAppSnackBar(l10n.dataExportCopied);
      case DataExportOutcome.saved:
        messenger.showAppSnackBar(l10n.dataExportSaved);
      case DataExportOutcome.failed:
        messenger.showAppSnackBar(
          l10n.dataExportShareFailed,
          tone: AppSnackBarTone.error,
        );
      case DataExportOutcome.shared || DataExportOutcome.canceled:
        break;
    }
  }
}
