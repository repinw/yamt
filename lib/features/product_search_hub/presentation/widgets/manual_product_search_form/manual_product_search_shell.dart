import 'package:flutter/material.dart';
import 'package:yamt/core/constants/app_layout_constants.dart';
import 'package:yamt/core/device/voice_search_service.dart';
import 'package:yamt/core/widgets/text_voice_search_bar.dart';
import 'package:yamt/l10n/app_localizations.dart';

/// Shell for manual product search modal pages.
class ManualProductSearchShell extends StatelessWidget {
  /// Creates a manual product search shell.
  const ManualProductSearchShell({
    required this.title,
    required this.searchBar,
    required this.body,
    required this.onClose,
    super.key,
  });

  /// Dialog title.
  final String title;

  /// Search bar area.
  final Widget searchBar;

  /// Main content.
  final Widget body;

  /// Close action.
  final VoidCallback onClose;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    final insets = MediaQuery.viewInsetsOf(context).bottom;

    return SafeArea(
      child: SingleChildScrollView(
        padding: EdgeInsets.fromLTRB(
          AppSpacing.xl,
          AppSpacing.lg,
          AppSpacing.xl,
          AppSpacing.xl + insets,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            ManualProductDialogHeader(title: title, onClose: onClose),
            const SizedBox(height: AppSpacing.lg),
            Theme(
              data: _buildSearchToolbarTheme(context),
              child: searchBar,
            ),
            const SizedBox(height: AppSpacing.lg),
            Divider(
              height: 1,
              color: colors.outlineVariant.withValues(alpha: 0.55),
            ),
            const SizedBox(height: AppSpacing.lg),
            body,
          ],
        ),
      ),
    );
  }
}

/// Search toolbar for manual product flows.
class ManualProductSearchToolbar extends StatelessWidget {
  /// Creates a manual product search toolbar.
  const ManualProductSearchToolbar({
    required this.searchController,
    required this.onAiSearchTap,
    required this.onScanBarcode,
    required this.clearButtonKey,
    required this.fieldKey,
    super.key,
    this.isSearching = false,
    this.readOnly = false,
    this.autofocus = false,
    this.onTap,
    this.onChanged,
    this.onVoiceSearchPressed,
    this.voiceSearchService,
    this.voiceSearchController,
    this.startVoiceSearchOnMount = false,
  });

  /// Search text controller.
  final TextEditingController searchController;

  /// Opens AI search.
  final VoidCallback onAiSearchTap;

  /// Opens barcode scanner.
  final VoidCallback onScanBarcode;

  /// Clear button key.
  final Key clearButtonKey;

  /// Search field key.
  final Key fieldKey;

  /// Whether search is running.
  final bool isSearching;

  /// Whether search input is read-only.
  final bool readOnly;

  /// Whether search input autofocuses.
  final bool autofocus;

  /// Tap callback.
  final VoidCallback? onTap;

  /// Text change callback.
  final ValueChanged<String>? onChanged;

  /// Voice search button callback.
  final VoidCallback? onVoiceSearchPressed;

  /// Voice search service.
  final VoiceSearchService? voiceSearchService;

  /// Voice search controller.
  final TextVoiceSearchController? voiceSearchController;

  /// Whether voice search should start on mount.
  final bool startVoiceSearchOnMount;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        TextVoiceSearchBar(
          controller: searchController,
          label: l10n.inventoryReceiptReviewManualSearchLabel,
          hintText: l10n.inventoryReceiptReviewManualSearchLabel,
          isSearching: isSearching,
          voiceButtonKey: const Key(
            'receipt_review_manual_voice_search_button',
          ),
          clearButtonKey: clearButtonKey,
          fieldKey: fieldKey,
          readOnly: readOnly,
          autofocus: autofocus,
          onTap: onTap,
          onChanged: onChanged,
          onVoiceSearchPressed: onVoiceSearchPressed,
          voiceSearchService: voiceSearchService,
          voiceSearchController: voiceSearchController,
          startVoiceSearchOnMount: startVoiceSearchOnMount,
        ),
        const SizedBox(height: AppSpacing.sm),
        ManualProductQuickActionsRow(
          onAiSearchTap: onAiSearchTap,
          onScanBarcode: onScanBarcode,
        ),
      ],
    );
  }
}

/// Header for manual product modal pages.
class ManualProductDialogHeader extends StatelessWidget {
  /// Creates a manual product dialog header.
  const ManualProductDialogHeader({
    required this.title,
    required this.onClose,
    super.key,
  });

  /// Dialog title.
  final String title;

  /// Close action.
  final VoidCallback onClose;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;

    return Row(
      children: [
        Expanded(
          child: Text(
            title,
            style: Theme.of(context).textTheme.headlineSmall?.copyWith(
              fontWeight: FontWeight.w800,
            ),
          ),
        ),
        DecoratedBox(
          decoration: BoxDecoration(
            color: colors.surfaceContainerLow.withValues(alpha: 0.96),
            shape: BoxShape.circle,
            border: Border.all(
              color: colors.outlineVariant.withValues(alpha: 0.72),
            ),
          ),
          child: CloseButton(
            color: colors.onSurfaceVariant,
            onPressed: onClose,
          ),
        ),
      ],
    );
  }
}

/// Quick action buttons shown below manual search field.
class ManualProductQuickActionsRow extends StatelessWidget {
  /// Creates quick action buttons.
  const ManualProductQuickActionsRow({
    required this.onAiSearchTap,
    required this.onScanBarcode,
    super.key,
  });

  /// Opens AI search.
  final VoidCallback onAiSearchTap;

  /// Opens barcode scanner.
  final VoidCallback onScanBarcode;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;

    return Row(
      children: [
        Expanded(
          child: OutlinedButton.icon(
            key: const Key('receipt_review_manual_ai_search_button'),
            onPressed: onAiSearchTap,
            icon: const Icon(Icons.auto_awesome_rounded),
            label: Text(l10n.inventoryManualAddAiSearchAction),
          ),
        ),
        const SizedBox(width: AppSpacing.sm),
        Expanded(
          child: OutlinedButton.icon(
            key: const Key('receipt_review_manual_scan_button'),
            onPressed: onScanBarcode,
            icon: const Icon(Icons.qr_code_scanner_rounded),
            label: Text(l10n.inventoryManualAddScanBarcodeAction),
          ),
        ),
      ],
    );
  }
}

ThemeData _buildSearchToolbarTheme(BuildContext context) {
  final theme = Theme.of(context);
  final colors = theme.colorScheme;
  final shape = RoundedRectangleBorder(
    borderRadius: BorderRadius.circular(AppRadius.xl),
  );
  final iconButtonStyle = IconButton.styleFrom(
    backgroundColor: colors.surfaceContainerLow.withValues(alpha: 0.96),
    foregroundColor: colors.onSurfaceVariant,
    side: BorderSide(
      color: colors.outlineVariant.withValues(alpha: 0.72),
    ),
    shape: shape,
  ).merge(theme.iconButtonTheme.style);

  return theme.copyWith(
    inputDecorationTheme: theme.inputDecorationTheme.copyWith(
      hintStyle: theme.textTheme.bodyLarge?.copyWith(
        color: colors.onSurfaceVariant,
      ),
      filled: true,
      fillColor: colors.surfaceContainerLow.withValues(alpha: 0.96),
      prefixIconColor: colors.primary,
      suffixIconColor: colors.onSurfaceVariant,
      contentPadding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.md,
        vertical: AppSpacing.md,
      ),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(AppRadius.xl),
        borderSide: BorderSide(color: colors.outlineVariant),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(AppRadius.xl),
        borderSide: BorderSide(
          color: colors.outlineVariant.withValues(alpha: 0.72),
        ),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(AppRadius.xl),
        borderSide: BorderSide(color: colors.primary.withValues(alpha: 0.82)),
      ),
    ),
    iconButtonTheme: IconButtonThemeData(
      style: iconButtonStyle,
    ),
  );
}
