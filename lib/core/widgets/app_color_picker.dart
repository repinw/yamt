import 'package:material_ui/material_ui.dart';
import 'package:yamt/core/constants/app_layout_constants.dart';
import 'package:yamt/core/constants/app_sizes.dart';
import 'package:yamt/l10n/app_localizations.dart';

/// Steps of the hue track, enough for a smooth rainbow.
const _hueStops = 12;

/// A free color picker: hue, saturation and brightness, each on a slider
/// whose track shows the colors it reaches.
///
/// [onChanged] reports every move, [onChangeEnd] the color when the finger
/// lifts. The picker reads [color] only when it is created; give it a new
/// key to start over from another color.
class AppColorPicker extends StatefulWidget {
  /// Creates the picker, starting at [color].
  const new({
    required this.color,
    required this.onChanged,
    this.onChangeEnd,
    super.key,
  });

  /// Key of the hue slider.
  static const hueKey = ValueKey<String>('app-color-picker-hue');

  /// Key of the saturation slider.
  static const saturationKey = ValueKey<String>('app-color-picker-saturation');

  /// Key of the brightness slider.
  static const valueKey = ValueKey<String>('app-color-picker-value');

  /// The color to start from.
  final Color color;

  /// Called on every move of a slider.
  final ValueChanged<Color> onChanged;

  /// Called when a slider is let go.
  final ValueChanged<Color>? onChangeEnd;

  @override
  State<AppColorPicker> createState() => _AppColorPickerState();
}

class _AppColorPickerState extends State<AppColorPicker> {
  // Kept as HSV, so the hue survives a move to grey or black.
  late HSVColor _hsv = HSVColor.fromColor(widget.color);

  void _change(HSVColor hsv) {
    setState(() => _hsv = hsv);
    widget.onChanged(hsv.toColor());
  }

  void _end(HSVColor hsv) => widget.onChangeEnd?.call(hsv.toColor());

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final hsv = _hsv;
    String percent(double share) =>
        l10n.colorPickerPercent((share * 100).round());
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      spacing: AppSpacing.xs,
      children: [
        _GradientSlider(
          key: AppColorPicker.hueKey,
          label: l10n.colorPickerHue,
          value: hsv.hue,
          max: 360,
          format: (hue) => l10n.colorPickerDegrees(hue.round()),
          colors: [
            for (var stop = 0; stop <= _hueStops; stop++)
              hsv
                  .withHue(stop * 360 / _hueStops % 360)
                  .withSaturation(1)
                  .withValue(1)
                  .toColor(),
          ],
          onChanged: (hue) => _change(hsv.withHue(hue)),
          onChangeEnd: (hue) => _end(hsv.withHue(hue)),
        ),
        _GradientSlider(
          key: AppColorPicker.saturationKey,
          label: l10n.colorPickerSaturation,
          value: hsv.saturation,
          max: 1,
          format: percent,
          colors: [
            hsv.withSaturation(0).toColor(),
            hsv.withSaturation(1).toColor(),
          ],
          onChanged: (saturation) => _change(hsv.withSaturation(saturation)),
          onChangeEnd: (saturation) => _end(hsv.withSaturation(saturation)),
        ),
        _GradientSlider(
          key: AppColorPicker.valueKey,
          label: l10n.colorPickerBrightness,
          value: hsv.value,
          max: 1,
          format: percent,
          colors: [hsv.withValue(0).toColor(), hsv.withValue(1).toColor()],
          onChanged: (value) => _change(hsv.withValue(value)),
          onChangeEnd: (value) => _end(hsv.withValue(value)),
        ),
      ],
    );
  }
}

class _GradientSlider extends StatelessWidget {
  const new({
    required this.label,
    required this.value,
    required this.max,
    required this.format,
    required this.colors,
    required this.onChanged,
    required this.onChangeEnd,
    super.key,
  });

  final String label;
  final double value;
  final double max;

  /// The value as a screen reader reads it.
  final String Function(double value) format;
  final List<Color> colors;
  final ValueChanged<double> onChanged;
  final ValueChanged<double> onChangeEnd;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: theme.textTheme.labelMedium?.copyWith(
            color: theme.colorScheme.onSurfaceVariant,
          ),
        ),
        SliderTheme(
          data: SliderTheme.of(context).copyWith(
            trackHeight: AppSizes.colorPickerTrack,
            trackShape: _GradientTrackShape(colors),
            thumbColor: theme.colorScheme.onSurface,
          ),
          child: Slider(
            value: value.clamp(0, max),
            max: max,
            semanticFormatterCallback: format,
            onChanged: onChanged,
            onChangeEnd: onChangeEnd,
          ),
        ),
      ],
    );
  }
}

/// A rounded track filled with a gradient over its whole width.
class _GradientTrackShape extends SliderTrackShape with BaseSliderTrackShape {
  const new(this.colors);

  final List<Color> colors;

  @override
  void paint(
    PaintingContext context,
    Offset offset, {
    required RenderBox parentBox,
    required SliderThemeData sliderTheme,
    required Animation<double> enableAnimation,
    required Offset thumbCenter,
    required TextDirection textDirection,
    Offset? secondaryOffset,
    bool isDiscrete = false,
    bool isEnabled = false,
    double additionalActiveTrackHeight = 2,
  }) {
    final rect = getPreferredRect(
      parentBox: parentBox,
      offset: offset,
      sliderTheme: sliderTheme,
      isEnabled: isEnabled,
      isDiscrete: isDiscrete,
    );
    final paint = Paint()
      ..shader = LinearGradient(colors: colors).createShader(rect);
    context.canvas.drawRRect(
      RRect.fromRectAndRadius(rect, const Radius.circular(AppRadius.sm)),
      paint,
    );
  }
}
