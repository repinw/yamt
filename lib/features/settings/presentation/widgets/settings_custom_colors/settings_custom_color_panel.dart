import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:material_ui/material_ui.dart';
import 'package:yamt/core/constants/app_layout_constants.dart';
import 'package:yamt/core/constants/app_sizes.dart';
import 'package:yamt/core/theme/app_recent_colors_controller.dart';
import 'package:yamt/core/widgets/app_color_picker.dart';
import 'package:yamt/core/widgets/app_ink_well.dart';
import 'package:yamt/features/settings/presentation/widgets/settings_custom_colors/settings_custom_color_strip.dart';
import 'package:yamt/l10n/app_localizations.dart';

/// The picker of one color of the design "Individuell", in place of the
/// strip under the preview, so the preview stays in view: a color wheel
/// with the last used colors beside it, brightness, and "Abbrechen" or
/// "Übernehmen". [onChanged] reports every move.
class SettingsCustomColorPanel extends ConsumerStatefulWidget {
  /// Creates the panel.
  const new({
    required this.label,
    required this.color,
    required this.onChanged,
    required this.onCancel,
    required this.onApply,
    super.key,
  });

  /// Key of the "Übernehmen" button.
  static const applyKey = ValueKey<String>('settings-custom-color-apply');

  /// Key of the last used [color].
  static Key recentKey(Color color) =>
      ValueKey('settings-custom-color-recent-${color.toARGB32()}');

  /// Name of the color.
  final String label;

  /// The color to start from.
  final Color color;

  /// Called on every move.
  final ValueChanged<Color> onChanged;

  /// Called when the user keeps the color as it was.
  final VoidCallback onCancel;

  /// Called with the color the user takes.
  final ValueChanged<Color> onApply;

  @override
  ConsumerState<SettingsCustomColorPanel> createState() =>
      _SettingsCustomColorPanelState();
}

class _SettingsCustomColorPanelState
    extends ConsumerState<SettingsCustomColorPanel> {
  late Color _color = widget.color;

  // Counts the last used colors taken, so the picker starts over there.
  var _restarts = 0;

  void _change(Color color) {
    setState(() => _color = color);
    widget.onChanged(color);
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final theme = Theme.of(context);
    final muted = theme.textTheme.labelMedium?.copyWith(
      color: theme.colorScheme.onSurfaceVariant,
    );
    final recent = ref.watch(appRecentColorsControllerProvider);

    return Padding(
      padding: const EdgeInsets.fromLTRB(
        AppSpacing.xl,
        AppSpacing.md,
        AppSpacing.xl,
        AppSpacing.md,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        spacing: AppSpacing.sm,
        children: [
          AppColorPicker(
            key: ValueKey(_restarts),
            color: _color,
            onChanged: _change,
            wheelSize: AppSizes.customColorWheel,
            besideWheel: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              spacing: AppSpacing.sm,
              children: [
                Text(
                  widget.label,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: theme.textTheme.titleMedium,
                ),
                Text(_hexOf(_color), style: muted),
                if (recent.isNotEmpty) ...[
                  const SizedBox(height: AppSpacing.xs),
                  Text(l10n.settingsCustomColorRecent, style: muted),
                  // Each swatch keeps a full tap target around it.
                  Wrap(
                    children: [
                      for (final color in recent)
                        Semantics(
                          button: true,
                          label: l10n.settingsCustomColorRecentSwatch(
                            _hexOf(color),
                          ),
                          excludeSemantics: true,
                          child: AppInkWell(
                            key: SettingsCustomColorPanel.recentKey(color),
                            customBorder: const CircleBorder(),
                            onTap: () {
                              _change(color);
                              setState(() => _restarts++);
                            },
                            child: SizedBox.square(
                              dimension: AppSizes.minTapTarget,
                              child: Center(
                                child: SettingsCustomColorSwatch(color: color),
                              ),
                            ),
                          ),
                        ),
                    ],
                  ),
                ],
              ],
            ),
          ),
          // The buttons stack when large text leaves no room side by side.
          OverflowBar(
            alignment: MainAxisAlignment.end,
            spacing: AppSpacing.sm,
            overflowAlignment: OverflowBarAlignment.end,
            children: [
              TextButton(
                onPressed: widget.onCancel,
                child: Text(
                  MaterialLocalizations.of(context).cancelButtonLabel,
                ),
              ),
              FilledButton(
                key: SettingsCustomColorPanel.applyKey,
                onPressed: () => widget.onApply(_color),
                child: Text(l10n.settingsCustomColorApply),
              ),
            ],
          ),
        ],
      ),
    );
  }

  // The color as #RRGGBB.
  static String _hexOf(Color color) =>
      '#${color.toARGB32().toRadixString(16).substring(2).toUpperCase()}';
}
