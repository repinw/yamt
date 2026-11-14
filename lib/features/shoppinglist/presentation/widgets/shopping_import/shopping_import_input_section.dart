import 'dart:async';
import 'dart:developer' show log;

import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:material_ui/material_ui.dart';
import 'package:yamt/core/constants/app_layout_constants.dart';
import 'package:yamt/core/device/document_scanner.dart';
import 'package:yamt/core/widgets/app_snack_bar.dart';
import 'package:yamt/features/shoppinglist/domain/shopping_import_reading.dart';
import 'package:yamt/features/shoppinglist/presentation/controllers/shopping_import_controller.dart';
import 'package:yamt/features/shoppinglist/presentation/widgets/shopping_import/shopping_import_keys.dart';
import 'package:yamt/l10n/app_localizations.dart';

/// Pages a shopping list scan may have.
const _maxScanPages = 5;

/// Lines the empty field shows, so it reads as room for a whole list.
const _fieldMinLines = 8;

enum _Mode { text, scan }

/// The start of the import: paste a list as text or scan a written one.
class ShoppingImportInputSection extends ConsumerStatefulWidget {
  /// Creates the input section that edits [text].
  const new({required this.text, super.key});

  /// The pasted list.
  final TextEditingController text;

  @override
  ConsumerState<ShoppingImportInputSection> createState() =>
      _ShoppingImportInputSectionState();
}

class _ShoppingImportInputSectionState
    extends ConsumerState<ShoppingImportInputSection> {
  _Mode _mode = _Mode.text;

  ShoppingImportController get _controller =>
      ref.read(shoppingImportControllerProvider.notifier);

  Future<void> _paste() async {
    final data = await Clipboard.getData(Clipboard.kTextPlain);
    // The page owns the text field and disposes it when it closes.
    if (!mounted) return;
    final pasted = data?.text;
    if (pasted == null || pasted.isEmpty) return;
    final current = widget.text.text;
    widget.text.text = current.trim().isEmpty ? pasted : '$current\n$pasted';
  }

  void _read() {
    final text = widget.text.text;
    if (text.trim().isEmpty) return;
    FocusScope.of(context).unfocus();
    unawaited(_controller.readText(text));
  }

  Future<void> _scan() async {
    final messenger = ScaffoldMessenger.of(context);
    final failed = AppLocalizations.of(context)!.shoppingImportScanFailed;
    final List<String>? pages;
    try {
      pages = await scanDocumentPages(
        maxPages: _maxScanPages,
        allowGallery: true,
      );
    } on Object catch (error, stackTrace) {
      log(
        'The list scan failed.',
        name: 'ShoppingImportInputSection',
        error: error,
        stackTrace: stackTrace,
      );
      messenger.showAppSnackBar(failed, tone: AppSnackBarTone.error);
      return;
    }
    if (pages == null || pages.isEmpty || !mounted) return;
    unawaited(_controller.readFiles(pages));
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final theme = Theme.of(context);
    final isText = _mode == _Mode.text;
    return Column(
      children: [
        Expanded(
          child: ListView(
            padding: AppInsets.page,
            children: [
              SegmentedButton<_Mode>(
                segments: [
                  ButtonSegment(
                    value: _Mode.text,
                    icon: const Icon(Icons.content_paste_rounded),
                    label: Text(
                      l10n.shoppingImportModeText,
                      key: ShoppingImportKeys.modeText,
                    ),
                  ),
                  ButtonSegment(
                    value: _Mode.scan,
                    icon: const Icon(Icons.document_scanner_outlined),
                    label: Text(
                      l10n.shoppingImportModeScan,
                      key: ShoppingImportKeys.modeScan,
                    ),
                  ),
                ],
                selected: {_mode},
                onSelectionChanged: (selection) =>
                    setState(() => _mode = selection.single),
              ),
              const SizedBox(height: AppSpacing.xxxl),
              Text(
                isText
                    ? l10n.shoppingImportTextTitle
                    : l10n.shoppingImportScanTitle,
                style: theme.textTheme.titleLarge,
              ),
              const SizedBox(height: AppSpacing.xs),
              Text(
                isText
                    ? l10n.shoppingImportTextHint
                    : l10n.shoppingImportScanHint,
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: theme.colorScheme.onSurfaceVariant,
                ),
              ),
              const SizedBox(height: AppSpacing.xl),
              if (isText) _TextInput(text: widget.text, onPaste: _paste),
            ],
          ),
        ),
        Padding(
          padding: AppInsets.page,
          child: SizedBox(
            width: double.infinity,
            child: isText
                ? ListenableBuilder(
                    listenable: widget.text,
                    builder: (context, _) => FilledButton(
                      key: ShoppingImportKeys.readButton,
                      onPressed: widget.text.text.trim().isEmpty ? null : _read,
                      child: Text(l10n.shoppingImportReadAction),
                    ),
                  )
                : FilledButton.icon(
                    key: ShoppingImportKeys.scanButton,
                    onPressed: _scan,
                    icon: const Icon(Icons.document_scanner_outlined),
                    label: Text(l10n.shoppingImportScanAction),
                  ),
          ),
        ),
      ],
    );
  }
}

class _TextInput extends StatelessWidget {
  const new({required this.text, required this.onPaste});

  final TextEditingController text;
  final VoidCallback onPaste;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final theme = Theme.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        TextField(
          key: ShoppingImportKeys.textField,
          controller: text,
          minLines: _fieldMinLines,
          maxLines: null,
          keyboardType: TextInputType.multiline,
          textCapitalization: TextCapitalization.sentences,
          decoration: InputDecoration(hintText: l10n.shoppingImportFieldHint),
        ),
        ListenableBuilder(
          listenable: text,
          builder: (context, _) => Row(
            children: [
              Expanded(
                child: Text(
                  l10n.shoppingImportLineCount(
                    shoppingImportLineCount(text.text),
                  ),
                  key: ShoppingImportKeys.lineCount,
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: theme.colorScheme.onSurfaceVariant,
                  ),
                ),
              ),
              TextButton(
                key: ShoppingImportKeys.clearButton,
                onPressed: text.text.isEmpty ? null : text.clear,
                child: Text(l10n.shoppingImportClear),
              ),
            ],
          ),
        ),
        const SizedBox(height: AppSpacing.xs),
        OutlinedButton.icon(
          key: ShoppingImportKeys.pasteButton,
          onPressed: onPaste,
          icon: const Icon(Icons.content_paste_go_rounded),
          label: Text(l10n.shoppingImportPaste),
        ),
      ],
    );
  }
}
