import 'dart:math' as math;

import 'package:material_ui/material_ui.dart';
import 'package:yamt/core/constants/app_intro_layout_constants.dart';
import 'package:yamt/features/onboarding/presentation/widgets/intro/fields/'
    'intro_stream_lines.dart';

/// Slowly drifting accent wash behind the intro pages.
///
/// Two soft blobs breathe in and out on their own timers, so the page never
/// looks static, and both fade into the accent of the current chapter.
class IntroBackdrop extends StatefulWidget {
  /// Creates the intro backdrop.
  const new({required this.accent, required this.counterAccent, super.key});

  /// Accent color of the current chapter.
  final Color accent;

  /// Secondary color of the current chapter.
  final Color counterAccent;

  @override
  State<IntroBackdrop> createState() => _IntroBackdropState();
}

class _IntroBackdropState extends State<IntroBackdrop>
    with TickerProviderStateMixin {
  late final AnimationController _slow;
  late final AnimationController _slower;
  late final AnimationController _stream;

  @override
  void initState() {
    super.initState();
    _slow = AnimationController(
      vsync: this,
      duration: AppIntroLayout.backdropSlowCycle,
    );
    _slower = AnimationController(
      vsync: this,
      duration: AppIntroLayout.backdropSlowerCycle,
    );
    _stream = AnimationController(
      vsync: this,
      duration: AppIntroLayout.streamCycle,
    );
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    // Respect reduced motion, and keep widget tests from spinning forever.
    if (MediaQuery.disableAnimationsOf(context)) {
      _slow.stop();
      _slower.stop();
      _stream.stop();
      return;
    }
    if (!_slow.isAnimating) {
      _slow.repeat(reverse: true);
    }
    if (!_slower.isAnimating) {
      _slower.repeat(reverse: true);
    }
    if (!_stream.isAnimating) {
      _stream.repeat();
    }
  }

  @override
  void dispose() {
    _slow.dispose();
    _slower.dispose();
    _stream.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final canvas = Theme.of(context).canvasColor;

    return RepaintBoundary(
      child: Stack(
        children: [
          Positioned.fill(child: ColoredBox(color: canvas)),
          _Blob(
            animation: _slow,
            accent: widget.accent,
            begin: const Alignment(-0.9, -0.85),
            end: const Alignment(-0.5, -0.45),
            scale: AppIntroLayout.backdropBlobLarge,
          ),
          _Blob(
            animation: _slower,
            accent: widget.counterAccent,
            begin: const Alignment(1, 0.9),
            end: const Alignment(0.45, 0.4),
            scale: AppIntroLayout.backdropBlobSmall,
          ),
          Positioned.fill(
            child: AnimatedBuilder(
              animation: _stream,
              builder: (context, _) => IntroStreamLines(
                progress: _stream.value,
                accent: widget.accent,
                counterAccent: widget.counterAccent,
              ),
            ),
          ),
          Positioned.fill(
            child: DecoratedBox(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    canvas.withValues(alpha: AppIntroLayout.vignetteOpacity),
                    canvas.withValues(alpha: 0),
                    canvas.withValues(alpha: AppIntroLayout.vignetteOpacity),
                  ],
                  stops: const [0, 0.45, 1],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _Blob extends StatelessWidget {
  const new({
    required this.animation,
    required this.accent,
    required this.begin,
    required this.end,
    required this.scale,
  });

  final Animation<double> animation;
  final Color accent;
  final Alignment begin;
  final Alignment end;
  final double scale;

  @override
  Widget build(BuildContext context) {
    final shortestSide = math.min(
      MediaQuery.sizeOf(context).width,
      MediaQuery.sizeOf(context).height,
    );
    final diameter = shortestSide * scale;

    return AnimatedBuilder(
      animation: animation,
      builder: (context, child) {
        final t = Curves.easeInOut.transform(animation.value);

        return Align(
          alignment: Alignment.lerp(begin, end, t)!,
          child: Transform.scale(
            scale: 1 + t * AppIntroLayout.backdropBreath,
            child: child,
          ),
        );
      },
      child: AnimatedContainer(
        duration: AppIntroLayout.backdropAccentFade,
        width: diameter,
        height: diameter,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          gradient: RadialGradient(
            colors: [
              accent.withValues(alpha: AppIntroLayout.backdropBlobOpacity),
              accent.withValues(alpha: 0),
            ],
          ),
        ),
      ),
    );
  }
}
