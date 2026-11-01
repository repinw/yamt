import 'dart:async';
import 'dart:developer' show log;

import 'package:flutter/scheduler.dart';
import 'package:material_ui/material_ui.dart';
import 'package:yamt/core/constants/app_holo_foil_constants.dart';
import 'package:yamt/core/device/device_tilt.dart';
import 'package:yamt/core/widgets/holo_foil_painter.dart';

/// A card in gold foil, like a gold rare trading card: while [enabled], it
/// turns with the phone's tilt, and gold glitter and a gold sheen shine
/// with the light. Off, it is just [child].
class HoloFoilCard extends StatefulWidget {
  /// Creates the foil around [child].
  const new({
    required this.enabled,
    required this.borderRadius,
    required this.surface,
    required this.child,
    super.key,
  });

  /// Whether the card wears the foil.
  final bool enabled;

  /// Corners of [child], which the foil follows.
  final BorderRadius borderRadius;

  /// Color of the card, which picks bright or deep gold.
  final Color surface;

  /// The card.
  final Widget child;

  @override
  State<HoloFoilCard> createState() => _HoloFoilCardState();
}

class _HoloFoilCardState extends State<HoloFoilCard>
    with SingleTickerProviderStateMixin, WidgetsBindingObserver {
  late final Ticker _ticker;
  StreamSubscription<Offset>? _tiltSubscription;
  Timer? _idleTimer;
  Offset _target = Offset.zero;
  Offset _tilt = Offset.zero;
  double _sparkle = 0;
  Duration _lastTick = Duration.zero;
  bool _visible = true;
  bool _resumed = true;
  bool _reduceMotion = false;

  @override
  void initState() {
    super.initState();
    _ticker = createTicker(_onTick);
    WidgetsBinding.instance.addObserver(this);
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    _resumed = state == AppLifecycleState.resumed;
    _sync();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    // An offstage tab and Reduce Motion stop the sensor and the frames.
    _visible = TickerMode.valuesOf(context).enabled;
    _reduceMotion = MediaQuery.disableAnimationsOf(context);
    _sync();
  }

  @override
  void didUpdateWidget(HoloFoilCard oldWidget) {
    super.didUpdateWidget(oldWidget);
    // Foil that comes back starts flat, not at the tilt it left with.
    if (!widget.enabled) _target = _tilt = Offset.zero;
    _sync();
  }

  @override
  void dispose() {
    _stop();
    WidgetsBinding.instance.removeObserver(this);
    _ticker.dispose();
    super.dispose();
  }

  bool get _moving => widget.enabled && _visible && _resumed && !_reduceMotion;

  /// Starts the sensor and the frames while the foil moves, and stops them
  /// otherwise.
  void _sync() {
    if (_moving == (_tiltSubscription != null)) return;
    if (!_moving) return _stop();
    // Without a sensor the card stays flat; the glitter still sparkles.
    _tiltSubscription = deviceTiltStream(interval: AppHoloFoil.tiltInterval)
        .listen(
          _onTilt,
          onError: (Object error, StackTrace stackTrace) => log(
            'No tilt for the holo foil',
            error: error,
            stackTrace: stackTrace,
          ),
        );
    _startIdle();
  }

  void _stop() {
    unawaited(_tiltSubscription?.cancel());
    _tiltSubscription = null;
    _idleTimer?.cancel();
    _idleTimer = null;
    _ticker.stop();
  }

  void _onTilt(Offset phoneTilt) {
    _target = Offset(
      (phoneTilt.dx / AppHoloFoil.fullPhoneTilt).clamp(-1, 1),
      (phoneTilt.dy / AppHoloFoil.fullPhoneTilt).clamp(-1, 1),
    );
    // A real tilt switches from the slow idle frames to every frame.
    if (!_ticker.isActive &&
        (_target - _tilt).distance > AppHoloFoil.wakeDistance) {
      _idleTimer?.cancel();
      _idleTimer = null;
      _lastTick = Duration.zero;
      _ticker.start();
    }
  }

  /// A still card only sparkles, on a slow timer instead of every frame.
  void _startIdle() {
    _ticker.stop();
    _idleTimer ??= Timer.periodic(AppHoloFoil.idleFrame, (_) {
      setState(() {
        _sparkle +=
            AppHoloFoil.sparkleIdleSpeed *
            AppHoloFoil.idleFrame.inMicroseconds /
            Duration.microsecondsPerSecond;
      });
    });
  }

  void _onTick(Duration elapsed) {
    final seconds =
        (elapsed - _lastTick).inMicroseconds / Duration.microsecondsPerSecond;
    _lastTick = elapsed;
    final next = Offset.lerp(_tilt, _target, AppHoloFoil.follow)!;
    final moved = (next - _tilt).distance;
    // The glitter sparkles faster while the phone moves.
    _sparkle +=
        seconds *
        (AppHoloFoil.sparkleIdleSpeed + moved * AppHoloFoil.sparkleMoveBoost);
    setState(() => _tilt = next);
    if (moved < AppHoloFoil.restDistance) _startIdle();
  }

  @override
  Widget build(BuildContext context) {
    final light = Offset(
      (0.5 + _tilt.dx / 2).clamp(0, 1),
      (0.5 + _tilt.dy / 2).clamp(0, 1),
    );
    final tilt = widget.enabled ? _tilt : Offset.zero;
    // One tree whether on or off, so the card keeps its state when the foil
    // comes or goes. The outer boundary keeps the foil's frames from
    // repainting the page; the inner one keeps them off the card's content.
    return RepaintBoundary(
      child: Transform(
        alignment: Alignment.center,
        transform: Matrix4.identity()
          ..setEntry(3, 2, AppHoloFoil.perspective)
          ..rotateX(-tilt.dy * AppHoloFoil.maxCardTilt)
          ..rotateY(tilt.dx * AppHoloFoil.maxCardTilt),
        child: ClipRRect(
          borderRadius: widget.borderRadius,
          clipBehavior: widget.enabled ? Clip.antiAlias : Clip.none,
          child: Stack(
            children: [
              RepaintBoundary(child: widget.child),
              if (widget.enabled)
                Positioned.fill(
                  child: IgnorePointer(
                    child: CustomPaint(
                      painter: HoloFoilPainter(
                        light: light,
                        sparkle: _sparkle,
                        isDark: widget.surface.computeLuminance() < 0.5,
                      ),
                    ),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}
