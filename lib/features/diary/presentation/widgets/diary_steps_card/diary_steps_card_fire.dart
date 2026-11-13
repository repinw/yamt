import 'dart:ui' show lerpDouble;

import 'package:material_ui/material_ui.dart';
import 'package:yamt/core/constants/app_steps_card_constants.dart';
import 'package:yamt/core/theme/steps_fire_colors.dart';

/// Sets the steps card on fire: its rim glows like embers and breathes
/// slowly. With Reduce Motion the glow stands still.
class DiaryStepsEmberFrame extends StatelessWidget {
  /// Creates the glowing rim around [child].
  const new({required this.borderRadius, required this.child, super.key});

  /// Corners of [child], which the rim follows.
  final BorderRadius borderRadius;

  /// The card.
  final Widget child;

  @override
  Widget build(BuildContext context) => _FireLoop(
    duration: AppStepsCard.emberBreath,
    reverse: true,
    builder: (context, t) {
      final heat = Curves.easeInOut.transform(t);
      return DecoratedBox(
        decoration: BoxDecoration(
          borderRadius: borderRadius,
          boxShadow: [
            // A wide haze around the card, and a tight hot edge on it.
            BoxShadow(
              color: StepsFireColors.glow.withValues(
                alpha: lerpDouble(
                  AppStepsCard.emberGlowAlphaMin,
                  AppStepsCard.emberGlowAlphaMax,
                  heat,
                ),
              ),
              blurRadius: lerpDouble(
                AppStepsCard.emberGlowMin,
                AppStepsCard.emberGlowMax,
                heat,
              )!,
              spreadRadius: lerpDouble(1, AppStepsCard.emberGlowSpread, heat)!,
            ),
            BoxShadow(
              color: StepsFireColors.flame.withValues(
                alpha: lerpDouble(
                  AppStepsCard.emberEdgeAlphaMin,
                  AppStepsCard.emberEdgeAlphaMax,
                  heat,
                ),
              ),
              blurRadius: AppStepsCard.emberEdgeGlow,
            ),
          ],
        ),
        child: DecoratedBox(
          position: DecorationPosition.foreground,
          decoration: BoxDecoration(
            borderRadius: borderRadius,
            border: Border.all(
              color: Color.lerp(
                StepsFireColors.ember,
                StepsFireColors.rimBright,
                heat,
              )!,
              width: AppStepsCard.emberRim,
            ),
            // Heat that rises from the lower edge.
            gradient: LinearGradient(
              begin: const Alignment(0, AppStepsCard.emberHeatStart),
              end: Alignment.bottomCenter,
              colors: [
                StepsFireColors.glow.withValues(alpha: 0),
                StepsFireColors.glow.withValues(
                  alpha: lerpDouble(
                    AppStepsCard.emberHeatAlphaMin,
                    AppStepsCard.emberHeatAlphaMax,
                    heat,
                  ),
                ),
              ],
            ),
          ),
          child: child,
        ),
      );
    },
  );
}

/// The flame that stands for the walker while the card burns: it flickers
/// between flame and bright core. With Reduce Motion it stands still.
class DiaryStepsFlame extends StatelessWidget {
  /// Creates the flame.
  const new({super.key});

  @override
  Widget build(BuildContext context) => _FireLoop(
    duration: AppStepsCard.flameFlicker,
    reverse: true,
    builder: (context, t) => Transform.scale(
      scale: lerpDouble(
        AppStepsCard.flameFlickerScaleMin,
        AppStepsCard.flameFlickerScale,
        t,
      ),
      alignment: Alignment.bottomCenter,
      child: Icon(
        Icons.local_fire_department_rounded,
        size: AppStepsCard.icon,
        color: Color.lerp(StepsFireColors.flame, StepsFireColors.core, t),
      ),
    ),
  );
}

/// The fill of the goal line while the card burns: fire runs through it and
/// glows upwards. With Reduce Motion the fire stands still.
class DiaryStepsFireLine extends StatelessWidget {
  /// Creates the burning fill.
  const new({super.key});

  @override
  Widget build(BuildContext context) => _FireLoop(
    duration: AppStepsCard.fireRun,
    reverse: false,
    builder: (context, t) => Container(
      height: AppStepsCard.goalLine,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(AppStepsCard.goalLine / 2),
        // One full width per round; the bands repeat, so no seam shows.
        gradient: LinearGradient(
          begin: Alignment(-1 - 2 * t, 0),
          end: Alignment(1 - 2 * t, 0),
          colors: StepsFireColors.run,
          tileMode: TileMode.repeated,
        ),
        boxShadow: [
          BoxShadow(
            color: StepsFireColors.flame.withValues(
              alpha: AppStepsCard.fireLineGlowAlpha,
            ),
            blurRadius: AppStepsCard.fireLineGlow,
            offset: const Offset(0, -AppStepsCard.fireLineGlowRise),
          ),
        ],
      ),
    ),
  );
}

/// Runs [builder] with a value that loops from 0 to 1, and back with
/// [reverse]. With Reduce Motion the value stays in the middle.
class _FireLoop extends StatefulWidget {
  const new({
    required this.duration,
    required this.reverse,
    required this.builder,
  });

  final Duration duration;
  final bool reverse;
  final Widget Function(BuildContext context, double t) builder;

  @override
  State<_FireLoop> createState() => _FireLoopState();
}

class _FireLoopState extends State<_FireLoop>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller = AnimationController(
    vsync: this,
    duration: widget.duration,
  );

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (MediaQuery.disableAnimationsOf(context)) {
      _controller
        ..stop()
        ..value = AppStepsCard.fireStill;
    } else if (!_controller.isAnimating) {
      _controller.repeat(reverse: widget.reverse);
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  // Its own layer, so a frame of the fire does not repaint the page.
  Widget build(BuildContext context) => RepaintBoundary(
    child: AnimatedBuilder(
      animation: _controller,
      builder: (context, _) => widget.builder(context, _controller.value),
    ),
  );
}
