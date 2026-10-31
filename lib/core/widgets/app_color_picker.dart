import 'dart:math' as math;

import 'package:material_ui/material_ui.dart';
import 'package:yamt/core/constants/app_layout_constants.dart';
import 'package:yamt/core/constants/app_sizes.dart';
import 'package:yamt/core/widgets/app_color_wheel_painter.dart';
import 'package:yamt/l10n/app_localizations.dart';

/// Degrees of hue per screen reader step.
const _hueSemanticsStep = 15;

/// Saturation per screen reader step.
const _saturationSemanticsStep = 0.1;

/// A free color picker: a wheel for hue (around) and saturation (out from
/// the middle), and a slider for brightness whose track shows the colors it
/// reaches.
///
/// [onChanged] reports every move. The picker reads [color] only when it is
/// created; give it a new key to start over from another color.
class AppColorPicker extends StatefulWidget {
  /// Creates the picker, starting at [color].
  const new({
    required this.color,
    required this.onChanged,
    required this.wheelSize,
    required this.besideWheel,
    super.key,
  });

  /// Key of the wheel.
  static const wheelKey = ValueKey<String>('app-color-picker-wheel');

  /// Key of the brightness slider.
  static const valueKey = ValueKey<String>('app-color-picker-value');

  /// The color to start from.
  final Color color;

  /// Called on every move of the wheel or the slider.
  final ValueChanged<Color> onChanged;

  /// Diameter of the wheel.
  final double wheelSize;

  /// Shown right of the wheel.
  final Widget besideWheel;

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

  static double _hueStep(double hue, int direction) =>
      (hue + direction * _hueSemanticsStep) % 360;

  static double _saturationStep(double saturation, int direction) =>
      (saturation + direction * _saturationSemanticsStep).clamp(0.0, 1.0);

  // The point of the wheel under [position] sets hue and saturation.
  void _wheelAt(Offset position) {
    final radius = widget.wheelSize / 2;
    final offset = position - Offset(radius, radius);
    final hue = (math.atan2(offset.dy, offset.dx) * 180 / math.pi + 360) % 360;
    _change(
      _hsv.withHue(hue).withSaturation(math.min(offset.distance / radius, 1)),
    );
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final hsv = _hsv;
    String degrees(double hue) => l10n.colorPickerDegrees(hue.round());
    String percent(double share) =>
        l10n.colorPickerPercent((share * 100).round());
    // Screen readers set hue and saturation step by step, as sliders.
    final wheel = Semantics(
      container: true,
      label: l10n.colorPickerHue,
      value: degrees(hsv.hue),
      increasedValue: degrees(_hueStep(hsv.hue, 1)),
      decreasedValue: degrees(_hueStep(hsv.hue, -1)),
      onIncrease: () => _change(hsv.withHue(_hueStep(hsv.hue, 1))),
      onDecrease: () => _change(hsv.withHue(_hueStep(hsv.hue, -1))),
      child: Semantics(
        container: true,
        label: l10n.colorPickerSaturation,
        value: percent(hsv.saturation),
        increasedValue: percent(_saturationStep(hsv.saturation, 1)),
        decreasedValue: percent(_saturationStep(hsv.saturation, -1)),
        onIncrease: () =>
            _change(hsv.withSaturation(_saturationStep(hsv.saturation, 1))),
        onDecrease: () =>
            _change(hsv.withSaturation(_saturationStep(hsv.saturation, -1))),
        child: GestureDetector(
          key: AppColorPicker.wheelKey,
          onTapUp: (details) => _wheelAt(details.localPosition),
          onPanStart: (details) => _wheelAt(details.localPosition),
          onPanUpdate: (details) => _wheelAt(details.localPosition),
          child: CustomPaint(
            size: Size.square(widget.wheelSize),
            painter: AppColorWheelPainter(hsv),
          ),
        ),
      ),
    );
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      spacing: AppSpacing.md,
      children: [
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          spacing: AppSpacing.lg,
          children: [
            wheel,
            Expanded(child: widget.besideWheel),
          ],
        ),
        _GradientSlider(
          key: AppColorPicker.valueKey,
          label: l10n.colorPickerBrightness,
          value: hsv.value,
          format: (value) => l10n.colorPickerPercent((value * 100).round()),
          colors: [hsv.withValue(0).toColor(), hsv.withValue(1).toColor()],
          onChanged: (value) => _change(hsv.withValue(value)),
        ),
      ],
    );
  }
}

class _GradientSlider extends StatelessWidget {
  const new({
    required this.label,
    required this.value,
    required this.format,
    required this.colors,
    required this.onChanged,
    super.key,
  });

  final String label;

  /// Brightness from 0 to 1.
  final double value;

  /// The value as a screen reader reads it.
  final String Function(double value) format;
  final List<Color> colors;
  final ValueChanged<double> onChanged;

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
            value: value.clamp(0, 1),
            semanticFormatterCallback: format,
            onChanged: onChanged,
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
