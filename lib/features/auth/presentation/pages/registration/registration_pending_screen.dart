import 'dart:math';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';

import 'package:psf_application/app/constants/app_colors.dart';
import 'package:psf_application/app/constants/app_strings.dart';
import 'package:psf_application/shared/widgets/dialogs/app_dialog.dart';

/// Shown right after RegistrationPreviewScreen submits the application
/// (see its _completeRegistration), and again on any later app launch —
/// before approval — that a returning member is routed back to via
/// RegistrationNavigator ('/registration-pending', see that file's
/// mapScreenNameToRoute).
///
/// This screen is a deliberate dead end: there is no wizard step "back"
/// to return to (registration is already submitted) and no Home to go
/// "forward" to (Home is reserved for an approved, active member — see
/// RegistrationPreviewScreen's doc comment on why
/// AppPrefs.isRegistrationCompleted is left unset at submission time). So
/// both the hardware/gesture back action and the OS "close app" request
/// are intercepted with [PopScope] and answered with an explicit exit
/// confirmation instead of silently leaving the screen — see
/// _confirmExit.
class RegistrationPendingScreen extends StatefulWidget {
  const RegistrationPendingScreen({super.key});

  @override
  State<RegistrationPendingScreen> createState() =>
      _RegistrationPendingScreenState();
}

class _RegistrationPendingScreenState extends State<RegistrationPendingScreen>
    with TickerProviderStateMixin {
  late final _FireworkShow _show;
  late final AnimationController _fireworkController;
  late final AnimationController _successController;

  @override
  void initState() {
    super.initState();

    _show = _buildFireworks();

    // One-shot celebration on entry — not looped, so it doesn't keep
    // distracting the member if this screen stays open while they wait
    // for approval. Long enough for every staggered rocket AND every
    // ground cracker below to fire, ignite, and fade before it stops —
    // a proper, busier little show rather than one quick flash.
    _fireworkController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 7500),
    )..forward();

    _successController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 950),
    )..forward();
  }

  @override
  void dispose() {
    _fireworkController.dispose();
    _successController.dispose();
    super.dispose();
  }

  // ============================================================
  // EXIT CONFIRMATION
  // ============================================================

  Future<void> _confirmExit() async {
    final shouldExit = await AppDialog.confirm(
      title: 'exit_app'.tr,
      message: 'exit_app_message'.tr,
      confirmText: 'exit_app'.tr,
      cancelText: AppStrings.cancel.tr,
    );

    if (shouldExit) {
      SystemNavigator.pop();
    }
  }

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, result) {
        if (didPop) return;
        _confirmExit();
      },
      child: Scaffold(
        backgroundColor: AppColors.background,
        body: SafeArea(
          child: Stack(
            children: [
              SingleChildScrollView(
                physics: const AlwaysScrollableScrollPhysics(),
                padding: const EdgeInsets.fromLTRB(24, 36, 24, 24),
                child: Column(
                  children: [
                    _SuccessBadge(controller: _successController),

                    const SizedBox(height: 26),

                    Text(
                      'registration_submitted'.tr,
                      textAlign: TextAlign.center,
                      style: const TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.w800,
                        color: AppColors.primaryDark,
                      ),
                    ),

                    const SizedBox(height: 10),

                    Text(
                      'registration_submitted_hint'.tr,
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        height: 1.5,
                        color: AppColors.primaryDark.withOpacity(.7),
                      ),
                    ),

                    const SizedBox(height: 22),

                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: const Color(0xFFD9F0ED),
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Icon(
                            Icons.hourglass_top_rounded,
                            color: AppColors.primary,
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'approval_pending'.tr,
                                  style: const TextStyle(
                                    fontWeight: FontWeight.w800,
                                    color: AppColors.primaryDark,
                                  ),
                                ),
                                const SizedBox(height: 5),
                                Text(
                                  'approval_pending_hint'.tr,
                                  style: TextStyle(
                                    height: 1.45,
                                    color:
                                        AppColors.primaryDark.withOpacity(.75),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),

                    const SizedBox(height: 20),

                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(18),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(color: AppColors.border),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'approval_time'.tr,
                            style: const TextStyle(
                              fontWeight: FontWeight.w800,
                              color: AppColors.primaryDark,
                            ),
                          ),
                          const SizedBox(height: 5),
                          Text('approval_time_value'.tr),
                          const Divider(height: 24),
                          Text(
                            'contact_us'.tr,
                            style: const TextStyle(
                              fontWeight: FontWeight.w800,
                              color: AppColors.primaryDark,
                            ),
                          ),
                          const SizedBox(height: 5),
                          Text('support_contact'.tr),
                        ],
                      ),
                    ),
                  ],
                ),
              ),

              // Fireworks sit above the content but never intercept taps.
              Positioned.fill(
                child: IgnorePointer(
                  child: AnimatedBuilder(
                    animation: _fireworkController,
                    builder: (context, _) => CustomPaint(
                      size: Size.infinite,
                      painter: _FireworkPainter(
                        sparks: _show.sparks,
                        rockets: _show.rockets,
                        glitter: _show.glitter,
                        progress: _fireworkController.value,
                      ),
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

// ============================================================
// SUCCESS BADGE — bouncing checkmark + fading expansion ring
// ============================================================

class _SuccessBadge extends StatelessWidget {
  const _SuccessBadge({required this.controller});

  final AnimationController controller;

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: controller,
      builder: (context, _) {
        final bounce = Curves.elasticOut.transform(controller.value);
        final ringProgress = Curves.easeOut.transform(controller.value);

        return SizedBox(
          width: 150,
          height: 150,
          child: Stack(
            alignment: Alignment.center,
            children: [
              Opacity(
                opacity: (1 - ringProgress).clamp(0.0, 1.0),
                child: Transform.scale(
                  scale: 0.6 + ringProgress * 0.9,
                  child: Container(
                    width: 150,
                    height: 150,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      border: Border.all(
                        color: AppColors.success.withOpacity(0.5),
                        width: 3,
                      ),
                    ),
                  ),
                ),
              ),
              Transform.scale(
                scale: bounce.clamp(0.0, 1.4),
                child: Container(
                  width: 108,
                  height: 108,
                  decoration: BoxDecoration(
                    color: AppColors.success.withOpacity(0.12),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(
                    Icons.check_circle_rounded,
                    color: AppColors.success,
                    size: 62,
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}

// ============================================================
// FIREWORKS / CRACKERS — a small self-contained particle show, no extra
// package needed: several rockets launch one after another (not all at
// once, closer to a real show), each climbing up a fading trail from
// below and then, on arrival, throwing a ring of sparks outward that
// decelerate, arc down slightly under gravity, and fade out — replacing
// the previous straight-down falling-confetti/paper effect (and, before
// that, a single burst with no launch).
// ============================================================

/// Everything needed to paint one show: the rockets (the climbing dot +
/// trail before each aerial burst), every burst's sparks (both the
/// rockets' and the ground crackers' — a burst is a burst regardless of
/// whether something climbed up to it first), and the glitter dots each
/// burst leaves twinkling behind it for a while after the main flash.
class _FireworkShow {
  const _FireworkShow({
    required this.rockets,
    required this.sparks,
    required this.glitter,
  });

  final List<_RocketTrail> rockets;
  final List<_FireworkSpark> sparks;
  final List<_GlitterDot> glitter;
}

/// Builds the whole show up front (once, in initState) so the animation
/// itself is pure math over these fixed lists each frame — nothing here
/// is regenerated per tick.
_FireworkShow _buildFireworks() {
  final random = Random();
  final rockets = <_RocketTrail>[];
  final sparks = <_FireworkSpark>[];
  final glitter = <_GlitterDot>[];

  const palette = [
    AppColors.primary,
    Color(0xFFFFC857),
    Color(0xFFFF6B6B),
    Color(0xFF5AA9E6),
    Color(0xFFB388FF),
    Color(0xFFFF9F45),
    Color(0xFF4FD1C5),
    Color(0xFFFF4FA3),
  ];

  // ---- AERIAL ROCKETS — climb up, then burst ------------------------
  // Where each one explodes, spread across the upper portion of the
  // screen, roughly where the old confetti used to drift down from, so
  // it reads as "happening above/around the success badge" rather than
  // covering the text underneath.
  const rocketOrigins = [
    Offset(0.20, 0.16),
    Offset(0.78, 0.13),
    Offset(0.50, 0.24),
    Offset(0.30, 0.36),
    Offset(0.72, 0.32),
    Offset(0.50, 0.44),
  ];

  for (var i = 0; i < rocketOrigins.length; i++) {
    final origin = rocketOrigins[i];
    final color = palette[i % palette.length];

    // Staggered so rockets launch one after another across most of the
    // animation, leaving comfortable room at the end for the last one's
    // sparks to still fully burst and fade rather than being cut off —
    // and enough of a head start (base 0.14) that even the first
    // rocket's full climb fits before it ignites, see launchDuration.
    final ignitionTime =
        (i / rocketOrigins.length) * 0.55 + 0.14 + random.nextDouble() * 0.04;

    final launchDuration = 0.09 + random.nextDouble() * 0.05;

    rockets.add(
      _RocketTrail(
        originX: origin.dx,
        originY: origin.dy,
        // Starts well below its burst point — off the bottom of the
        // screen at the very start of its climb — so it visibly travels
        // up into view rather than just fading in near the top.
        launchY: origin.dy + 0.55 + random.nextDouble() * 0.15,
        ignitionTime: ignitionTime,
        launchDuration: launchDuration,
        color: color,
      ),
    );

    _addBurst(
      sparks: sparks,
      glitter: glitter,
      random: random,
      originX: origin.dx,
      originY: origin.dy,
      startDelay: ignitionTime,
      color: color,
      sparkCount: 18 + random.nextInt(10),
      sparkSpeed: 0.16 + random.nextDouble() * 0.15,
      sparkSize: 2.5,
    );
  }

  // ---- GROUND CRACKERS — no climb, just pop, again and again --------
  // These don't launch from anywhere — they fire directly at a spread of
  // spots across the lower-middle of the screen, continuously, one after
  // another across almost the entire show (not clustered together like
  // the rockets above), so on top of the aerial bursts there's always
  // something small popping somewhere — closer to a real mix of
  // rockets-in-the-sky plus ground crackers going off than a handful of
  // isolated single bursts. Sizes/speeds/colors are randomized per
  // cracker so they don't all look identical.
  const crackerCount = 10;

  for (var i = 0; i < crackerCount; i++) {
    final color = palette[random.nextInt(palette.length)];
    final originX = 0.12 + random.nextDouble() * 0.76;
    final originY = 0.46 + random.nextDouble() * 0.28;
    final startDelay = random.nextDouble() * 0.82;
    final isSmallPop = random.nextBool();

    _addBurst(
      sparks: sparks,
      glitter: glitter,
      random: random,
      originX: originX,
      originY: originY,
      startDelay: startDelay,
      color: color,
      sparkCount: isSmallPop ? 8 + random.nextInt(6) : 13 + random.nextInt(8),
      sparkSpeed:
          isSmallPop ? 0.06 + random.nextDouble() * 0.05 : 0.10 + random.nextDouble() * 0.08,
      sparkSize: isSmallPop ? 1.8 : 2.2,
    );
  }

  return _FireworkShow(rockets: rockets, sparks: sparks, glitter: glitter);
}

/// Adds one burst's worth of sparks (the main flash) plus its glitter
/// dots (the fading twinkle left behind afterward) — shared by both the
/// rocket-triggered aerial bursts and the ground crackers above, since a
/// burst is the same shape either way, only its origin/size/timing
/// differ.
void _addBurst({
  required List<_FireworkSpark> sparks,
  required List<_GlitterDot> glitter,
  required Random random,
  required double originX,
  required double originY,
  required double startDelay,
  required Color color,
  required int sparkCount,
  required double sparkSpeed,
  required double sparkSize,
}) {
  for (var i = 0; i < sparkCount; i++) {
    // Evenly spaced around the circle, each with a little jitter so the
    // burst doesn't look like a perfectly uniform starburst.
    final angle =
        (i / sparkCount) * pi * 2 + (random.nextDouble() - 0.5) * 0.35;

    sparks.add(
      _FireworkSpark(
        originX: originX,
        originY: originY,
        angle: angle,
        // Fraction of the canvas's shorter side this spark travels once
        // its burst has fully played out.
        speed: sparkSpeed + random.nextDouble() * 0.03,
        size: sparkSize + random.nextDouble() * 2.2,
        startDelay: startDelay,
        color: color,
      ),
    );
  }

  // A handful of small dots scattered around the burst that fade in just
  // after the main flash and then twinkle on and off for a while before
  // dying out — the lingering "sparkle" a real cracker leaves behind,
  // distinct from the bigger spark circles above (which simply fly
  // outward and fade, without blinking).
  final glitterCount = 5 + random.nextInt(4);

  for (var i = 0; i < glitterCount; i++) {
    final appearAt = (startDelay + 0.05).clamp(0.0, 1.0);

    glitter.add(
      _GlitterDot(
        originX: originX,
        originY: originY,
        angle: random.nextDouble() * pi * 2,
        distance: (0.4 + random.nextDouble() * 0.7) * sparkSpeed,
        size: 1.4 + random.nextDouble() * 1.6,
        color: color,
        appearAt: appearAt,
        fadeOutAt:
            (startDelay + 0.28 + random.nextDouble() * 0.22).clamp(0.0, 1.0),
        twinkleSpeed: 5 + random.nextDouble() * 7,
        twinklePhase: random.nextDouble() * pi * 2,
      ),
    );
  }
}

/// The climbing dot + fading trail a rocket draws on its way up to
/// [originX]/[originY], where it hands off to that same burst's sparks
/// (see _FireworkSpark.startDelay, which is always this rocket's
/// [ignitionTime]) the instant it arrives.
class _RocketTrail {
  const _RocketTrail({
    required this.originX,
    required this.originY,
    required this.launchY,
    required this.ignitionTime,
    required this.launchDuration,
    required this.color,
  });

  /// 0..1 fraction of the canvas — where this rocket explodes.
  final double originX;
  final double originY;

  /// 0..~1.7 fraction of canvas height this rocket climbs from — often
  /// below the visible screen, matching how a real firework launches from
  /// the ground below where it bursts.
  final double launchY;

  /// 0..1 fraction of the overall animation at which this rocket arrives
  /// and its burst ignites.
  final double ignitionTime;

  /// Fraction of the overall animation this rocket spends climbing,
  /// immediately before [ignitionTime].
  final double launchDuration;

  final Color color;
}

class _FireworkSpark {
  const _FireworkSpark({
    required this.originX,
    required this.originY,
    required this.angle,
    required this.speed,
    required this.size,
    required this.startDelay,
    required this.color,
  });

  /// 0..1 fraction of the canvas — where this spark's burst ignites from.
  final double originX;
  final double originY;

  /// Direction (radians) this spark flies outward from the burst origin.
  final double angle;

  /// How far this spark travels, as a fraction of the canvas's shorter
  /// side, once its burst has fully played out.
  final double speed;

  final double size;

  /// 0..~0.9 fraction of the overall animation before this spark's burst
  /// ignites — shared by every spark in one burst (so they all fire
  /// together), but different between bursts (so bursts fire in
  /// sequence, not all at once).
  final double startDelay;

  final Color color;
}

/// One small dot in a burst's lingering "sparkle" — sits at a fixed
/// point relative to the burst origin (it doesn't fly outward like a
/// spark does), fades in shortly after the main flash, twinkles on and
/// off for a while, then fades out for good.
class _GlitterDot {
  const _GlitterDot({
    required this.originX,
    required this.originY,
    required this.angle,
    required this.distance,
    required this.size,
    required this.color,
    required this.appearAt,
    required this.fadeOutAt,
    required this.twinkleSpeed,
    required this.twinklePhase,
  });

  /// 0..1 fraction of the canvas — the burst this dot belongs to.
  final double originX;
  final double originY;

  /// Fixed position relative to the burst origin, as an angle + distance
  /// (fraction of the canvas's shorter side) — computed once, not
  /// animated, so the dot just twinkles in place rather than moving.
  final double angle;
  final double distance;

  final double size;
  final Color color;

  /// 0..1 fraction of the overall animation this dot starts fading in —
  /// always a little after its burst's own startDelay, so it reads as
  /// "left behind by the flash" rather than part of it.
  final double appearAt;

  /// 0..1 fraction of the overall animation this dot has completely
  /// faded out by.
  final double fadeOutAt;

  /// How fast this dot blinks once visible, and where in its blink cycle
  /// it starts — randomized per dot so a burst's dots don't all twinkle
  /// in perfect unison.
  final double twinkleSpeed;
  final double twinklePhase;
}

class _FireworkPainter extends CustomPainter {
  _FireworkPainter({
    required this.rockets,
    required this.sparks,
    required this.glitter,
    required this.progress,
  });

  final List<_RocketTrail> rockets;
  final List<_FireworkSpark> sparks;
  final List<_GlitterDot> glitter;
  final double progress;

  @override
  void paint(Canvas canvas, Size size) {
    final shortSide = min(size.width, size.height);

    for (final rocket in rockets) {
      final launchStart =
          (rocket.ignitionTime - rocket.launchDuration).clamp(0.0, 1.0);

      // Only visible during its own climb — before launchStart it hasn't
      // lifted off yet, and once it reaches ignitionTime it has arrived
      // and handed off to its burst's sparks below, so there's no rocket
      // left to draw.
      if (progress <= launchStart || progress >= rocket.ignitionTime) {
        continue;
      }

      final t = (progress - launchStart) / rocket.launchDuration;

      // Ease-out: quick off the ground, slowing as it nears the top —
      // like a real rocket losing thrust rather than flying at a
      // constant speed the whole way up.
      final eased = 1 - pow(1 - t, 2).toDouble();

      final originX = rocket.originX * size.width;
      final originY = rocket.originY * size.height;
      final launchY = rocket.launchY * size.height;

      // A tiny side-to-side wobble, purely cosmetic, so the climb doesn't
      // look like a perfectly straight mechanical line.
      final headX = originX + sin(t * 2 * pi) * 4;
      final headY = launchY + (originY - launchY) * eased;

      // A short fading tail trailing behind (below) the head, rather than
      // one line that keeps growing the whole climb.
      final tailY =
          (headY + shortSide * 0.10).clamp(originY, launchY);

      final trailPaint = Paint()
        ..shader = LinearGradient(
          colors: [
            rocket.color.withOpacity(0.9),
            rocket.color.withOpacity(0.0),
          ],
        ).createShader(
          Rect.fromPoints(Offset(headX, headY), Offset(headX, tailY)),
        )
        ..strokeWidth = 3
        ..strokeCap = StrokeCap.round;

      canvas.drawLine(Offset(headX, headY), Offset(headX, tailY), trailPaint);

      canvas.drawCircle(
        Offset(headX, headY),
        3.2,
        Paint()..color = rocket.color,
      );
    }

    for (final spark in sparks) {
      // Each spark's own 0..1 window starts the moment its burst ignites
      // and runs to the end of the animation, so every burst gets its
      // full travel-and-fade regardless of how late it starts.
      final localProgress =
          ((progress - spark.startDelay) / (1 - spark.startDelay))
              .clamp(0.0, 1.0);

      if (localProgress <= 0) continue;

      // Fast initial burst that decelerates (ease-out) — a real firework
      // shell's sparks slow down as they travel, they don't fly outward
      // at a constant speed.
      final eased = 1 - pow(1 - localProgress, 2).toDouble();
      final distance = eased * spark.speed * shortSide;

      final originX = spark.originX * size.width;
      final originY = spark.originY * size.height;

      // A little gravity so sparks arc downward as they fade, instead of
      // flying outward in perfectly straight lines forever.
      final gravity = localProgress * localProgress * shortSide * 0.12;

      final dx = originX + cos(spark.angle) * distance;
      final dy = originY + sin(spark.angle) * distance + gravity;

      // Bright for the first instant (the "bang"), then fades out — a
      // quick flash rather than a slow fade, closer to how an actual
      // spark burns out.
      final opacity = localProgress < 0.15
          ? 1.0
          : (1 - (localProgress - 0.15) / 0.85).clamp(0.0, 1.0);

      if (opacity <= 0) continue;

      final paint = Paint()..color = spark.color.withOpacity(opacity);

      canvas.drawCircle(
        Offset(dx, dy),
        spark.size * (1 - localProgress * 0.4),
        paint,
      );
    }

    for (final dot in glitter) {
      if (progress <= dot.appearAt || progress >= dot.fadeOutAt) continue;

      final span = (dot.fadeOutAt - dot.appearAt).clamp(0.001, 1.0);
      final t = (progress - dot.appearAt) / span;

      // Fade in quickly, hold, then fade out — with a twinkle (a sine
      // flicker) layered on top so it reads as sparkling rather than a
      // flat dot quietly appearing and disappearing.
      final envelope = t < 0.15
          ? t / 0.15
          : (t > 0.7 ? (1 - (t - 0.7) / 0.3) : 1.0);
      final twinkle = 0.55 +
          0.45 *
              sin(dot.twinklePhase + progress * dot.twinkleSpeed * pi * 2);
      final opacity = (envelope * twinkle).clamp(0.0, 1.0);

      if (opacity <= 0.02) continue;

      final dx = dot.originX * size.width +
          cos(dot.angle) * dot.distance * shortSide;
      final dy = dot.originY * size.height +
          sin(dot.angle) * dot.distance * shortSide;

      canvas.drawCircle(
        Offset(dx, dy),
        dot.size,
        Paint()..color = dot.color.withOpacity(opacity),
      );
    }
  }

  @override
  bool shouldRepaint(covariant _FireworkPainter oldDelegate) =>
      oldDelegate.progress != progress;
}
