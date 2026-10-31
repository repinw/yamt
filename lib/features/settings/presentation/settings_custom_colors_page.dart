import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:material_ui/material_ui.dart';
import 'package:yamt/core/constants/app_layout_constants.dart';
import 'package:yamt/core/theme/app_all_macros_colored_controller.dart';
import 'package:yamt/core/theme/app_custom_colors.dart';
import 'package:yamt/core/theme/app_custom_colors_controller.dart';
import 'package:yamt/core/theme/app_recent_colors_controller.dart';
import 'package:yamt/core/widgets/app_switch_list_tile.dart';
import 'package:yamt/features/settings/presentation/widgets/settings_custom_colors/settings_custom_base_dialog.dart';
import 'package:yamt/features/settings/presentation/widgets/settings_custom_colors/settings_custom_color_panel.dart';
import 'package:yamt/features/settings/presentation/widgets/settings_custom_colors/settings_custom_color_strip.dart';
import 'package:yamt/features/settings/presentation/widgets/settings_custom_colors/settings_custom_colors_preview.dart';
import 'package:yamt/l10n/app_localizations.dart';

/// The largest text scale of the controls below the preview.
const _maxControlsTextScale = 1.4;

/// The editor of the design "Individuell": a diary preview in the own
/// colors and a strip of all colors. A tap on a part of the preview or on a
/// swatch opens the panel of that color in place of the strip. While the
/// user picks, the whole app, this editor too, shows the color live. The
/// undo button takes back the last taken color or reset, one by one, as
/// long as the editor is open.
class SettingsCustomColorsPage extends ConsumerStatefulWidget {
  /// Creates the page.
  const new({super.key});

  /// Key of the undo button.
  static const undoKey = ValueKey<String>('settings-custom-colors-undo');

  /// Key of the reset button.
  static const resetKey = ValueKey<String>('settings-custom-colors-reset');

  /// Key of the "Makros immer bunt" switch.
  static const allMacrosKey = ValueKey<String>(
    'settings-custom-colors-all-macros',
  );

  @override
  ConsumerState<SettingsCustomColorsPage> createState() =>
      _SettingsCustomColorsPageState();
}

class _SettingsCustomColorsPageState
    extends ConsumerState<SettingsCustomColorsPage> {
  // The color the panel changes; null shows the strip.
  AppCustomColor? _editing;

  // The saved colors before each taken color or reset, newest last.
  final _undo = <AppCustomColors>[];

  // Kept for dispose, where ref is gone.
  late final AppCustomColorsController _controller;

  @override
  void initState() {
    super.initState();
    _controller = ref.read(appCustomColorsControllerProvider.notifier);
  }

  @override
  void dispose() {
    // Leaving with the panel open drops the color picked so far; after the
    // frame, as providers can't change while widgets unmount.
    if (_editing != null) {
      unawaited(Future.microtask(_controller.discard));
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final colors = ref.watch(appCustomColorsControllerProvider);
    final allMacrosColored = ref.watch(appAllMacrosColoredControllerProvider);
    if (colors == null) {
      return const Scaffold();
    }

    return PopScope(
      // Back closes the color panel first.
      canPop: _editing == null,
      onPopInvokedWithResult: (didPop, _) {
        if (!didPop) {
          _close();
        }
      },
      child: Scaffold(
        appBar: AppBar(
          title: Text(l10n.settingsDesignCustom),
          actions: [
            IconButton(
              key: SettingsCustomColorsPage.undoKey,
              tooltip: l10n.settingsCustomColorsUndo,
              onPressed: _undo.isEmpty ? null : () => unawaited(_takeBack()),
              icon: const Icon(Icons.undo_rounded),
            ),
            IconButton(
              key: SettingsCustomColorsPage.resetKey,
              tooltip: l10n.settingsCustomColorsReset,
              onPressed: () => unawaited(_reset(context)),
              icon: const Icon(Icons.restart_alt_rounded),
            ),
          ],
        ),
        body: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // The preview lays out as wide as the screen, like the diary
            // it shows, and shrinks to the room left by the margin, the
            // screen and the text size.
            Flexible(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: AppSpacing.xl),
                child: Builder(
                  builder: (context) => FittedBox(
                    fit: BoxFit.scaleDown,
                    alignment: Alignment.topCenter,
                    child: SizedBox(
                      width: MediaQuery.sizeOf(context).width,
                      child: SettingsCustomColorsPreview(
                        colors: colors,
                        allMacrosColored: allMacrosColored,
                        onPick: (key) => unawaited(_open(key)),
                      ),
                    ),
                  ),
                ),
              ),
            ),
            // The controls stay in view without scrolling, so their text
            // grows only so far.
            MediaQuery.withClampedTextScaling(
              maxScaleFactor: _maxControlsTextScale,
              child: AnimatedSize(
                duration: AppDurations.compactMetricExpansion,
                curve: Curves.easeOutCubic,
                alignment: Alignment.topCenter,
                child: _editing == null
                    ? _strip(l10n, colors, allMacrosColored)
                    : _panel(l10n, colors, _editing!),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _strip(
    AppLocalizations l10n,
    AppCustomColors colors,
    bool allMacrosColored,
  ) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const SizedBox(height: AppSpacing.xs),
        SettingsCustomColorStrip(
          colors: colors,
          onSelected: (key) => unawaited(_open(key)),
        ),
        AppSwitchListTile(
          key: SettingsCustomColorsPage.allMacrosKey,
          dense: true,
          contentPadding: const EdgeInsets.symmetric(
            horizontal: AppSpacing.xxl,
          ),
          title: Text(l10n.settingsCustomAllMacrosColored),
          subtitle: Text(l10n.settingsCustomAllMacrosColoredHint),
          value: allMacrosColored,
          onChanged: (value) => unawaited(
            ref
                .read(appAllMacrosColoredControllerProvider.notifier)
                .select(value: value),
          ),
        ),
        const SizedBox(height: AppSpacing.lg),
      ],
    );
  }

  Widget _panel(
    AppLocalizations l10n,
    AppCustomColors colors,
    AppCustomColor key,
  ) {
    return SettingsCustomColorPanel(
      key: ValueKey(key),
      label: settingsCustomColorLabel(l10n, key),
      color: colors[key],
      onChanged: (color) => _controller.preview(key, color),
      onCancel: _close,
      onApply: (color) => unawaited(_apply(key, color)),
    );
  }

  // Opens the panel of [key]; the app follows it until the user takes or
  // drops the color. Another color takes the one picked so far.
  Future<void> _open(AppCustomColor key) async {
    final editing = _editing;
    if (editing != null && editing != key) {
      await _take(
        editing,
        ref.read(appCustomColorsControllerProvider)![editing],
      );
    }
    if (mounted) {
      setState(() => _editing = key);
    }
  }

  // Closes the panel and goes back to the saved colors.
  void _close() {
    _controller.discard();
    setState(() => _editing = null);
  }

  // The colors as saved, without the one the panel shows.
  AppCustomColors _saved() {
    if (_editing != null) {
      _controller.discard();
    }
    return ref.read(appCustomColorsControllerProvider)!;
  }

  // Saves [color] for [key] and puts it first into the last used ones.
  Future<void> _apply(AppCustomColor key, Color color) async {
    setState(() => _editing = null);
    await _take(key, color);
  }

  // Saves [color] for [key], unless it is the saved one, so undo can take
  // it back.
  Future<void> _take(AppCustomColor key, Color color) async {
    _controller.discard();
    final saved = ref.read(appCustomColorsControllerProvider)!;
    if (saved[key] == color) {
      return;
    }
    setState(() => _undo.add(saved));
    // Both start before the first await, while the page still holds them.
    await (
      _controller.select(key, color),
      ref.read(appRecentColorsControllerProvider.notifier).add(color),
    ).wait;
  }

  // Starts the colors over as a copy of the design the user picks again.
  Future<void> _reset(BuildContext context) async {
    final base = await showSettingsCustomBaseDialog(context);
    if (base != null && mounted) {
      final saved = _saved();
      setState(() {
        _editing = null;
        _undo.add(saved);
      });
      await _controller.start(base);
    }
  }

  // Goes back to the colors before the last taken color or reset.
  Future<void> _takeBack() async {
    if (_editing != null) {
      _controller.discard();
    }
    final previous = _undo.last;
    setState(() {
      _editing = null;
      _undo.removeLast();
    });
    await _controller.restore(previous);
  }
}
