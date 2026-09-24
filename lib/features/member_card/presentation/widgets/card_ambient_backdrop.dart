import 'dart:math' as math;

import 'package:flutter/material.dart';

import 'package:psf_application/app/constants/app_colors.dart';

/// Soft, slow-drifting decoration filling the Card tab's edges and corners
/// so the screen doesn't read as empty around the wallet — cheap on
/// purpose (plain radial gradients, translations and one slow rotation, no
/// blur shaders) so it stays smooth on lower-end phones.
///
/// Placed behind the wallet as a non-interactive layer (`IgnorePointer`):
///  * A big, very slow rotating soft wash behind everything (an "aurora").
///  * Eight soft glows — the four corners AND the four edge midpoints —
///    each drifting a little, on its own slow cycle.
///  * A dozen tiny accent dots slowly rising and fading, staggered so
///    they never move in lockstep.
///
/// A placeholder look-and-feel, easy to swap for something more specific
/// later.
class CardAmbientBackdrop extends StatefulWidget {
  const CardAmbientBackdrop({super.key, this.paused = false});

  /// While `true`, all three loops sit still instead of ticking — used to
  /// free up frame budget for the wallet cover's own open/close animation,
  /// which matters more in the moment than this decorative background.
  final bool paused;

  @override
  State<CardAmbientBackdrop> createState() => _CardAmbientBackdropState();
}

class _CardAmbientBackdropState extends State<CardAmbientBackdrop>
    with TickerProviderStateMixin {
  // Three independent, differently-paced loops instead of one — glows,
  // the background wash and the dots each drift at their own slow speed
  // rather than everything breathing in exact unison.
  late final AnimationController _drift = AnimationController(
    vsync: this,
    duration: const Duration(seconds: 18),
  )..repeat();

  late final AnimationController _spin = AnimationController(
    vsync: this,
    duration: const Duration(seconds: 70),
  )..repeat();

  late final AnimationController _rise = AnimationController(
    vsync: this,
    duration: const Duration(seconds: 26),
  )..repeat();

  @override
  void didUpdateWidget(CardAmbientBackdrop oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.paused == oldWidget.paused) return;
    if (widget.paused) {
      _drift.stop();
      _spin.stop();
      _rise.stop();
    } else {
      _drift.repeat();
      _spin.repeat();
      _rise.repeat();
    }
  }

  @override
  void dispose() {
    _drift.dispose();
    _spin.dispose();
    _rise.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return IgnorePointer(
      child: RepaintBoundary(
        child: Stack(
          clipBehavior: Clip.none,
          children: [
            // Big, very slow rotating wash — the "aurora" wash behind
            // everything else, so the background never looks flat.
            Positioned.fill(
              child: AnimatedBuilder(
                animation: _spin,
                builder: (context, _) => Transform.rotate(
                  angle: _spin.value * 2 * math.pi,
                  child: Container(
                    decoration: const BoxDecoration(
                      gradient: SweepGradient(
                        colors: [
                          Color(0x00087A72),
                          Color(0x14087A72),
                          Color(0x00087A72),
                          Color(0x12E3C16F),
                          Color(0x00087A72),
                        ],
                        stops: [0, .18, .5, .78, 1],
                      ),
                    ),
                  ),
                ),
              ),
            ),
            AnimatedBuilder(
              animation: _drift,
              builder: (context, _) {
                final t = _drift.value * 2 * math.pi;

                return Stack(
                  clipBehavior: Clip.none,
                  children: [
                    for (final spec in _glows)
                      _CornerGlow(
                        alignment: spec.alignment,
                        color: spec.color,
                        size: spec.size,
                        offset: Offset(
                          math.sin(t * spec.speed + spec.phase) * spec.travel,
                          math.cos(t * spec.speed + spec.phase) * spec.travel * .7,
                        ),
                      ),
                  ],
                );
              },
            ),
            AnimatedBuilder(
              animation: _rise,
              builder: (context, _) => Stack(
                clipBehavior: Clip.none,
                children: [
                  for (final spec in _dots) _FloatingDot(spec: spec, progress: _rise.value),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// One soft glow's fixed spot and drift parameters.
class _GlowSpec {
  const _GlowSpec({
    required this.alignment,
    required this.color,
    required this.size,
    required this.travel,
    required this.speed,
    required this.phase,
  });

  final Alignment alignment;

  final Color color;

  final double size;

  /// How far it drifts back and forth, in pixels.
  final double travel;

  /// Relative cycle speed — 1 is the shared base speed, smaller is slower.
  final double speed;

  final double phase;
}

const _glows = [
  // Corners.
  _GlowSpec(alignment: Alignment.topLeft, color: AppColors.primary, size: 260, travel: 16, speed: 1, phase: 0),
  _GlowSpec(alignment: Alignment.topRight, color: AppColors.accentGold, size: 220, travel: 14, speed: .8, phase: 1.4),
  _GlowSpec(alignment: Alignment.bottomLeft, color: AppColors.accentGold, size: 240, travel: 14, speed: .65, phase: 2.6),
  _GlowSpec(alignment: Alignment.bottomRight, color: AppColors.primary, size: 280, travel: 18, speed: .9, phase: 4.1),
  // Edge midpoints — new: fills the sides, not just the corners.
  _GlowSpec(alignment: Alignment.centerLeft, color: AppColors.primaryLight, size: 190, travel: 20, speed: .55, phase: .8),
  _GlowSpec(alignment: Alignment.centerRight, color: AppColors.primaryLight, size: 190, travel: 20, speed: .7, phase: 3.2),
  _GlowSpec(alignment: Alignment.topCenter, color: AppColors.accentGold, size: 170, travel: 12, speed: .5, phase: 5.0),
  _GlowSpec(alignment: Alignment.bottomCenter, color: AppColors.primary, size: 200, travel: 12, speed: .6, phase: 1.9),
];

class _CornerGlow extends StatelessWidget {
  const _CornerGlow({
    required this.alignment,
    required this.color,
    required this.size,
    required this.offset,
  });

  final Alignment alignment;

  final Color color;

  final double size;

  final Offset offset;

  @override
  Widget build(BuildContext context) {
    return Align(
      alignment: alignment,
      child: Transform.translate(
        offset: offset,
        child: FractionalTranslation(
          translation: Offset(alignment.x * -.3, alignment.y * -.3),
          child: Container(
            width: size,
            height: size,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              gradient: RadialGradient(
                colors: [color.withOpacity(.16), color.withOpacity(0)],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// One tiny accent dot's fixed layout spot and float parameters — kept as
/// plain data so the widget list can be built with a `for` loop instead of
/// repeating many near-identical widgets.
class _DotSpec {
  const _DotSpec({
    required this.alignment,
    required this.size,
    required this.color,
    required this.phase,
    this.riseDistance = 20,
  });

  final Alignment alignment;

  final double size;

  final Color color;

  /// 0-1 offset into the shared animation cycle, so dots don't all rise
  /// and fade in lockstep.
  final double phase;

  final double riseDistance;
}

const _dots = [
  _DotSpec(alignment: Alignment(-.7, -.55), size: 7, color: AppColors.accentGold, phase: 0),
  _DotSpec(alignment: Alignment(.75, -.4), size: 5, color: AppColors.primary, phase: .18, riseDistance: 16),
  _DotSpec(alignment: Alignment(-.85, .5), size: 6, color: AppColors.primary, phase: .34),
  _DotSpec(alignment: Alignment(.8, .62), size: 8, color: AppColors.accentGold, phase: .5, riseDistance: 24),
  _DotSpec(alignment: Alignment(0, -.85), size: 4, color: AppColors.accentGold, phase: .1, riseDistance: 14),
  _DotSpec(alignment: Alignment(-.35, -.92), size: 5, color: AppColors.primary, phase: .62),
  _DotSpec(alignment: Alignment(.42, -.9), size: 4, color: AppColors.primaryLight, phase: .78, riseDistance: 16),
  _DotSpec(alignment: Alignment(-.95, -.05), size: 5, color: AppColors.accentGold, phase: .88),
  _DotSpec(alignment: Alignment(.95, .1), size: 6, color: AppColors.primary, phase: .05, riseDistance: 22),
  _DotSpec(alignment: Alignment(-.5, .88), size: 4, color: AppColors.primaryLight, phase: .42),
  _DotSpec(alignment: Alignment(.55, .9), size: 5, color: AppColors.accentGold, phase: .7, riseDistance: 18),
  _DotSpec(alignment: Alignment(0, .95), size: 6, color: AppColors.primary, phase: .27, riseDistance: 20),
];

class _FloatingDot extends StatelessWidget {
  const _FloatingDot({required this.spec, required this.progress});

  final _DotSpec spec;

  final double progress;

  @override
  Widget build(BuildContext context) {
    final local = (progress + spec.phase) % 1.0;
    // Rises gently and fades in/out at either end of its cycle instead of
    // popping in and out abruptly.
    final rise = -spec.riseDistance * local;
    final opacity = (math.sin(local * math.pi)).clamp(0.0, 1.0) * .5;

    return Align(
      alignment: spec.alignment,
      child: Transform.translate(
        offset: Offset(0, rise),
        child: Opacity(
          opacity: opacity,
          child: Container(
            width: spec.size,
            height: spec.size,
            decoration: BoxDecoration(shape: BoxShape.circle, color: spec.color),
          ),
        ),
      ),
    );
  }
}
