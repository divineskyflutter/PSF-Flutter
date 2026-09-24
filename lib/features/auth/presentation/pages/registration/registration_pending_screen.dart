import 'dart:async';
import 'dart:math';

import 'package:audioplayers/audioplayers.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:get/get.dart';
import 'package:url_launcher/url_launcher.dart';

import 'package:psf_application/app/constants/app_colors.dart';
import 'package:psf_application/app/constants/app_strings.dart';
import 'package:psf_application/shared/utils/app_validators.dart';
import 'package:psf_application/shared/utils/toast_util.dart';
import 'package:psf_application/shared/widgets/dialogs/app_dialog.dart';

/// One Support-section contact — the client's requirements doc lists
/// these by name/number directly (not fetched from the API), so they're
/// plain constants here rather than a model/request round-trip.
class _SupportContact {
  const _SupportContact({
    required this.nameKey,
    required this.phone,
  });

  final String nameKey;

  /// Plain 10-digit number, no formatting — [_formattedPhone] groups it
  /// for display, [_telUri]/[_whatsAppUri] use it as-is.
  final String phone;
}

const List<_SupportContact> _supportContacts = [
  _SupportContact(nameKey: 'support_contact_office_name', phone: '9664698982'),
  _SupportContact(nameKey: 'support_contact_1_name', phone: '9825635110'),
  _SupportContact(nameKey: 'support_contact_2_name', phone: '8000212041'),
];

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
    with TickerProviderStateMixin, WidgetsBindingObserver {
  // Reached two different ways: right after RegistrationPreviewScreen
  // submits (the normal case below — "Registration submitted!") or
  // straight from a login attempt on an application that's still under
  // review (see LoginController/LoginScreen) — a returning member, not
  // someone who just finished submitting, so the "Congratulations, just
  // submitted" framing would be wrong for them. Everything else on this
  // screen (the pending notice, approval time, contact details) reads
  // correctly either way.
  bool get _fromLogin {
    final arguments = Get.arguments;
    return arguments is Map && arguments['fromLogin'] == true;
  }

  late final _FireworkShow _show;
  late final AnimationController _fireworkController;
  late final AnimationController _successController;
  late final AudioPlayer _fireworkAudioPlayer;

  @override
  void initState() {
    super.initState();

    // So didChangeAppLifecycleState below actually gets called — see
    // that method for why this screen needs to know about backgrounding
    // at all.
    WidgetsBinding.instance.addObserver(this);

    _show = _buildFireworks();

    // Loops continuously per the client's requirements doc — the
    // celebration animation on this screen must stay visible and never
    // stop on its own. Long enough for every staggered rocket AND every
    // ground cracker below to fire, ignite, and fade before looping back
    // to the start — a proper, busier little show each time round,
    // rather than one quick flash repeated.
    _fireworkController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 7500),
    )..repeat();

    _successController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 950),
    )..forward();

    // Rocket-launch + firecracker crackle, looping continuously right
    // alongside the animation above — a short (~7s), trimmed-down clip
    // from a real fireworks recording, not the full multi-minute file.
    // ReleaseMode.loop makes the player itself restart the clip the
    // instant it ends, so there's no gap of silence waiting for this
    // code to notice completion and call play() again.
    _fireworkAudioPlayer = AudioPlayer();
    unawaited(_startFireworkAudio());
  }

  Future<void> _startFireworkAudio() async {
    try {
      // Without an explicit AudioContext, audioplayers leaves Android's
      // audio-focus request at whatever its own default is — on some
      // OEM audio stacks (Motorola's included) a player that never
      // explicitly asks for and is granted focus just plays into
      // silence: no exception, nothing in the logs, it simply never
      // becomes audible. Asking for it outright, as ordinary media
      // audio, is what those stacks expect before they'll actually
      // route sound to the speaker.
      await AudioPlayer.global.setAudioContext(
        AudioContext(
          android: const AudioContextAndroid(
            isSpeakerphoneOn: false,
            stayAwake: false,
            contentType: AndroidContentType.music,
            usageType: AndroidUsageType.media,
            audioFocus: AndroidAudioFocus.gain,
          ),
          // AudioContextIOS's own constructor asserts that
          // mixWithOthers may only be paired with the playback,
          // playAndRecord, or multiRoute categories — pairing it with
          // ambient (as this did before) throws that assertion the
          // moment this const object is built, on EVERY platform
          // (Android included, since this whole AudioContext literal is
          // constructed unconditionally regardless of which OS is
          // actually running) — which is exactly why sound still wasn't
          // playing on this Android device even after the audio-focus
          // fix: _startFireworkAudio was throwing before it ever reached
          // setAudioContext/play. The ambient category already mixes
          // with other apps' audio by default on iOS, so it doesn't need
          // the option spelled out at all.
          iOS: AudioContextIOS(
            category: AVAudioSessionCategory.ambient,
          ),
        ),
      );

      await _fireworkAudioPlayer.setReleaseMode(ReleaseMode.loop);
      await _fireworkAudioPlayer.setVolume(1.0);
      await _fireworkAudioPlayer.play(
        AssetSource('audio/fireworks_loop.mp3'),
      );

      debugPrint('[fireworks-audio] playback started');
    } catch (error, stackTrace) {
      // Playback failing should never block or crash this screen — the
      // celebration is still fully there visually either way, sound is
      // a nice-to-have on top — but log it (instead of swallowing it
      // silently) so a "no sound, no error" report can actually be
      // tracked down from the console next time.
      debugPrint('[fireworks-audio] failed to start: $error\n$stackTrace');
    }
  }

  // Tapping Call or WhatsApp below (_callContact/_whatsAppContact) opens
  // the phone dialer or WhatsApp itself via an external-application
  // intent — that backgrounds this Flutter app without ever popping or
  // disposing this screen, so nothing else here would otherwise notice.
  // Left alone, the firework loop — ReleaseMode.loop, so it never stops
  // on its own — just kept playing underneath whatever the member
  // switched to, indefinitely, until they came back and left this screen
  // some other way. Pausing on anything other than "resumed" (and
  // resuming when the member returns) covers that, plus the ordinary
  // case of leaving the app to the home screen or another app entirely.
  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    super.didChangeAppLifecycleState(state);
    unawaited(_syncFireworkAudioWithLifecycle(state));
  }

  Future<void> _syncFireworkAudioWithLifecycle(AppLifecycleState state) async {
    try {
      if (state == AppLifecycleState.resumed) {
        await _fireworkAudioPlayer.resume();
      } else {
        await _fireworkAudioPlayer.pause();
      }
    } catch (error, stackTrace) {
      // Same reasoning as _startFireworkAudio's own catch — this is
      // decorative sound, never worth crashing or blocking the screen
      // over (e.g. if playback never actually started in the first
      // place, pause()/resume() here have nothing to act on).
      debugPrint(
        '[fireworks-audio] lifecycle pause/resume failed: $error\n$stackTrace',
      );
    }
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _fireworkController.dispose();
    _successController.dispose();
    unawaited(_fireworkAudioPlayer.dispose());
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

  // ============================================================
  // SUPPORT — CALL / WHATSAPP
  // ============================================================

  Future<void> _launchOrError(Uri uri) async {
    final launched = await launchUrl(
      uri,
      mode: LaunchMode.externalApplication,
    );

    if (!launched) {
      ToastUtil.error('could_not_open_app_error'.tr);
    }
  }

  Future<void> _callContact(String phone) => _launchOrError(
        Uri(scheme: 'tel', path: phone),
      );

  Future<void> _whatsAppContact(String phone) => _launchOrError(
        // "91" = India's country code — every number here is a local
        // 10-digit Indian mobile number, same assumption AppValidators
        // .mobile already makes.
        Uri.parse('https://wa.me/91$phone'),
      );

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
                      _fromLogin
                          ? 'welcome_back_review_title'.tr
                          : 'registration_submitted'.tr,
                      textAlign: TextAlign.center,
                      style: const TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.w800,
                        color: AppColors.primaryDark,
                      ),
                    ),

                    const SizedBox(height: 10),

                    Text(
                      _fromLogin
                          ? 'welcome_back_review_hint'.tr
                          : 'registration_submitted_hint'.tr,
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
                          const SizedBox(height: 4),
                          Text(
                            'support_office_hours_title'.tr,
                            style: const TextStyle(
                              fontWeight: FontWeight.w700,
                              color: AppColors.primaryDark,
                            ),
                          ),
                          Text('support_office_hours_morning'.tr),
                          Text('support_office_hours_afternoon'.tr),
                          const SizedBox(height: 12),
                          for (final contact in _supportContacts) ...[
                            _SupportContactRow(
                              contact: contact,
                              onCall: () => _callContact(contact.phone),
                              onWhatsApp: () =>
                                  _whatsAppContact(contact.phone),
                            ),
                            const SizedBox(height: 10),
                          ],
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
                        flashes: _show.flashes,
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
// SUPPORT CONTACT ROW — name/number + tap-to-call/WhatsApp icons
// ============================================================

class _SupportContactRow extends StatelessWidget {
  const _SupportContactRow({
    required this.contact,
    required this.onCall,
    required this.onWhatsApp,
  });

  final _SupportContact contact;
  final VoidCallback onCall;
  final VoidCallback onWhatsApp;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                contact.nameKey.tr,
                style: const TextStyle(
                  fontWeight: FontWeight.w600,
                  color: AppColors.primaryDark,
                ),
              ),
              Text(
                AppValidators.formatMobile(contact.phone),
                style: TextStyle(
                  color: AppColors.primaryDark.withOpacity(.7),
                ),
              ),
            ],
          ),
        ),
        _SupportIconButton(
          icon: Icons.call_rounded,
          tooltip: 'call'.tr,
          onTap: onCall,
        ),
        const SizedBox(width: 8),
        _SupportIconButton(
          // The actual WhatsApp glyph, not a generic Material chat
          // bubble — FontAwesomeIcons.whatsapp is a real IconData (it
          // carries its own fontFamily/fontPackage), so it drops
          // straight into _SupportIconButton's existing Icon(...) below
          // with no other changes needed there.
          icon: FontAwesomeIcons.whatsapp,
          tooltip: 'whatsapp'.tr,
          onTap: onWhatsApp,
        ),
      ],
    );
  }
}

class _SupportIconButton extends StatelessWidget {
  const _SupportIconButton({
    required this.icon,
    required this.tooltip,
    required this.onTap,
  });

  final IconData icon;
  final String tooltip;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Tooltip(
      message: tooltip,
      child: InkWell(
        borderRadius: BorderRadius.circular(20),
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: AppColors.primary.withOpacity(0.1),
            shape: BoxShape.circle,
          ),
          child: Icon(icon, color: AppColors.primary, size: 18),
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
    required this.flashes,
  });

  final List<_RocketTrail> rockets;
  final List<_FireworkSpark> sparks;
  final List<_GlitterDot> glitter;
  final List<_BurstFlash> flashes;
}

/// Builds the whole show up front (once, in initState) so the animation
/// itself is pure math over these fixed lists each frame — nothing here
/// is regenerated per tick.
_FireworkShow _buildFireworks() {
  final random = Random();
  final rockets = <_RocketTrail>[];
  final sparks = <_FireworkSpark>[];
  final glitter = <_GlitterDot>[];
  final flashes = <_BurstFlash>[];

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

    // Staggered so rockets launch one after another across almost the
    // *entire* animation — spread out to 0.74 (was 0.55) so the last
    // rocket now ignites close to the very end of the cycle instead of
    // leaving the final ~30% of every loop with nothing left to watch.
    // That trailing dead patch, followed by AnimationController.repeat()
    // snapping straight back to the start, was exactly what read as
    // "stops, then starts again" instead of one continuous show. Still
    // enough head start (base 0.10) that even the first rocket's full
    // climb fits before it ignites, see launchDuration.
    final ignitionTime =
        (i / rocketOrigins.length) * 0.74 + 0.10 + random.nextDouble() * 0.04;

    // Shorter climb + a snappier (less quadratic) ease below makes the
    // rocket look like it's shooting up fast and steady, closer to a real
    // launch, instead of visibly decelerating the way a longer/quadratic
    // climb reads as "floaty".
    final launchDuration = 0.055 + random.nextDouble() * 0.035;

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
      flashes: flashes,
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
  const crackerCount = 14;

  // One cracker per equal-width slice of the whole cycle (0..0.97, with a
  // small random jitter inside its own slice) instead of pure random
  // placement across only the first 0.82 of the loop. Pure randomness
  // could — and did — leave a stretch near the end of every loop with
  // nothing popping at all, right before AnimationController.repeat()
  // snapped straight back to the start; that dead patch plus the abrupt
  // jump was exactly the "stops, then starts again" feeling reported.
  // Slicing guarantees something is always going off, right up to the
  // loop boundary, so it reads as one continuous show instead.
  final crackerSliceWidth = 0.97 / crackerCount;

  for (var i = 0; i < crackerCount; i++) {
    final color = palette[random.nextInt(palette.length)];
    final originX = 0.12 + random.nextDouble() * 0.76;
    final originY = 0.46 + random.nextDouble() * 0.28;
    final startDelay =
        i * crackerSliceWidth + random.nextDouble() * crackerSliceWidth;
    final isSmallPop = random.nextBool();

    _addBurst(
      sparks: sparks,
      glitter: glitter,
      flashes: flashes,
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

  return _FireworkShow(
    rockets: rockets,
    sparks: sparks,
    glitter: glitter,
    flashes: flashes,
  );
}

/// Adds one burst's worth of sparks (the main flash) plus its glitter
/// dots (the fading twinkle left behind afterward) — shared by both the
/// rocket-triggered aerial bursts and the ground crackers above, since a
/// burst is the same shape either way, only its origin/size/timing
/// differ.
void _addBurst({
  required List<_FireworkSpark> sparks,
  required List<_GlitterDot> glitter,
  required List<_BurstFlash> flashes,
  required Random random,
  required double originX,
  required double originY,
  required double startDelay,
  required Color color,
  required int sparkCount,
  required double sparkSpeed,
  required double sparkSize,
}) {
  // A quick, bright expand-and-fade right at the moment of ignition — the
  // "bang" a real firework/cracker flash has before you can even make out
  // individual sparks. Short and fixed-length like the sparks below, not
  // proportional to how much show time is left.
  flashes.add(
    _BurstFlash(
      originX: originX,
      originY: originY,
      startDelay: startDelay,
      lifeSpan: 0.045 + random.nextDouble() * 0.02,
      color: color,
    ),
  );

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
        speed: sparkSpeed + random.nextDouble() * 0.06,
        size: sparkSize + random.nextDouble() * 2.2,
        startDelay: startDelay,
        // A real spark burns out in well under a second regardless of
        // when in the show it fired — fixed here (not scaled by however
        // much of the animation happens to remain after startDelay) so
        // every spark, early or late, has the same quick, punchy life
        // instead of the earliest bursts lingering for several seconds.
        lifeSpan: 0.08 + random.nextDouble() * 0.05,
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
    final appearAt = (startDelay + 0.04).clamp(0.0, 1.0);

    glitter.add(
      _GlitterDot(
        originX: originX,
        originY: originY,
        angle: random.nextDouble() * pi * 2,
        distance: (0.4 + random.nextDouble() * 0.7) * sparkSpeed,
        size: 1.4 + random.nextDouble() * 1.6,
        color: color,
        appearAt: appearAt,
        // Fades out well within a second of the flash rather than
        // lingering for several — same "fixed short life, not
        // remaining-time-proportional" fix as the sparks above.
        fadeOutAt:
            (startDelay + 0.14 + random.nextDouble() * 0.08).clamp(0.0, 1.0),
        twinkleSpeed: 7 + random.nextDouble() * 8,
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
    required this.lifeSpan,
    required this.color,
  });

  /// 0..1 fraction of the canvas — where this spark's burst ignites from.
  final double originX;
  final double originY;

  /// Direction (radians) this spark flies outward from the burst origin.
  final double angle;

  /// How far this spark travels, as a fraction of the canvas's shorter
  /// side, once its life span has fully played out.
  final double speed;

  final double size;

  /// 0..~0.9 fraction of the overall animation before this spark's burst
  /// ignites — shared by every spark in one burst (so they all fire
  /// together), but different between bursts (so bursts fire in
  /// sequence, not all at once).
  final double startDelay;

  /// Fixed fraction of the overall animation this spark takes to travel
  /// out and fade, starting from [startDelay] — NOT proportional to how
  /// much show time happens to remain after it ignites. Every spark gets
  /// the same short, punchy life regardless of when it fires; without
  /// this, an early burst's sparks would linger fading for most of the
  /// show, which read as slow and unrealistic.
  final double lifeSpan;

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

/// A quick, bright expand-and-fade flash right at a burst's ignition
/// point — drawn under everything else so the sparks/glitter read as
/// flying out of it, gone almost as soon as it appears.
class _BurstFlash {
  const _BurstFlash({
    required this.originX,
    required this.originY,
    required this.startDelay,
    required this.lifeSpan,
    required this.color,
  });

  final double originX;
  final double originY;
  final double startDelay;
  final double lifeSpan;
  final Color color;
}

class _FireworkPainter extends CustomPainter {
  _FireworkPainter({
    required this.rockets,
    required this.sparks,
    required this.glitter,
    required this.flashes,
    required this.progress,
  });

  final List<_RocketTrail> rockets;
  final List<_FireworkSpark> sparks;
  final List<_GlitterDot> glitter;
  final List<_BurstFlash> flashes;
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

      // A gentler ease-out (power 1.4, not quadratic) — still slows a
      // little near the top, but mostly shoots up fast and steady rather
      // than visibly decelerating the whole way, which read as floaty.
      final eased = 1 - pow(1 - t, 1.4).toDouble();

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

    for (final flash in flashes) {
      final localProgress =
          ((progress - flash.startDelay) / flash.lifeSpan).clamp(0.0, 1.0);

      if (localProgress <= 0 || localProgress >= 1) continue;

      final opacity = (1 - localProgress) * (1 - localProgress);
      if (opacity <= 0.02) continue;

      final radius = shortSide * (0.02 + localProgress * 0.05);

      canvas.drawCircle(
        Offset(flash.originX * size.width, flash.originY * size.height),
        radius,
        Paint()..color = Colors.white.withOpacity(opacity * 0.85),
      );
    }

    // Helper: a spark's traveled distance + gravity drop at any point in
    // its own 0..1 life, reused below to draw both the current position
    // and a slightly-earlier trailing position for a streaked look.
    double sparkDistance(double localT) =>
        (1 - pow(1 - localT, 2).toDouble());

    for (final spark in sparks) {
      // Each spark burns out over its own short, fixed lifeSpan starting
      // the moment its burst ignites — not stretched over whatever show
      // time happens to remain, which used to make early sparks linger
      // fading for several seconds. This is the fix for the "slow" /
      // "fake" look: every spark, early or late in the show, now has the
      // same quick, punchy life a real spark has.
      final localProgress =
          ((progress - spark.startDelay) / spark.lifeSpan).clamp(0.0, 1.0);

      if (localProgress <= 0) continue;

      final originX = spark.originX * size.width;
      final originY = spark.originY * size.height;

      // Fast initial burst that decelerates (ease-out) — a real firework
      // shell's sparks slow down as they travel, they don't fly outward
      // at a constant speed.
      final eased = sparkDistance(localProgress);
      final distance = eased * spark.speed * shortSide;
      final gravity = localProgress * localProgress * shortSide * 0.10;
      final dx = originX + cos(spark.angle) * distance;
      final dy = originY + sin(spark.angle) * distance + gravity;

      // Bright for the first instant (the "bang"), then fades out — a
      // quick flash rather than a slow fade, closer to how an actual
      // spark burns out.
      final opacity = localProgress < 0.2
          ? 1.0
          : (1 - (localProgress - 0.2) / 0.8).clamp(0.0, 1.0);

      if (opacity <= 0) continue;

      // A short trailing streak (from a slightly-earlier point on the
      // same path to the current point) instead of a plain shrinking
      // dot — reads as a real spark burning through the air rather than
      // a dot fading in place.
      final trailT = (localProgress - 0.10).clamp(0.0, 1.0);
      final trailEased = sparkDistance(trailT);
      final trailDistance = trailEased * spark.speed * shortSide;
      final trailGravity = trailT * trailT * shortSide * 0.10;
      final tx = originX + cos(spark.angle) * trailDistance;
      final ty = originY + sin(spark.angle) * trailDistance + trailGravity;

      final streakPaint = Paint()
        ..color = spark.color.withOpacity(opacity)
        ..strokeWidth = spark.size * (1 - localProgress * 0.5)
        ..strokeCap = StrokeCap.round;

      canvas.drawLine(Offset(tx, ty), Offset(dx, dy), streakPaint);

      // A brighter head dot at the very tip of the streak — the "hot"
      // leading edge of the spark.
      canvas.drawCircle(
        Offset(dx, dy),
        spark.size * 0.55 * (1 - localProgress * 0.4),
        Paint()..color = Color.lerp(spark.color, Colors.white, 0.35)!
            .withOpacity(opacity),
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
