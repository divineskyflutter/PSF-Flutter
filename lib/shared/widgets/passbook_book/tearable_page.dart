import 'dart:async';
import 'dart:math' as math;

import 'package:audioplayers/audioplayers.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

/// How a page rips. One is picked at random every time a new tear starts.
enum _TearStyle {
  /// A rip running roughly straight across (left to right or right to left).
  flat,

  /// A steep rip cutting a big diagonal corner off the page.
  diagonal,

  /// A rip running down (or up) the page, splitting it into left and right.
  vertical,
}

/// One rip. The geometry is worked out in a "tear space" where the rip always
/// runs left to right; a vertical tear is that space turned on its side.
class _Tear {
  _Tear({
    required this.style,
    required this.fromStart,
    required this.startFrac,
    required this.slope,
    required this.jag,
  });

  final _TearStyle style;

  /// Starts at the near end of its axis (left for flat / diagonal, top for
  /// vertical).
  final bool fromStart;

  /// Where the rip starts across the page and how far it drifts, as fractions
  /// of the page's cross size (in tear space).
  final double startFrac;
  final double slope;
  final List<double> jag;

  double progress = 0;

  /// Set once the rip has gone right across: which half falls away (the
  /// smaller one) and the animation that drops it.
  bool? fallenIsUpper;
  AnimationController? fall;

  bool get vertical => style == _TearStyle.vertical;
  bool get complete => progress >= 1;
}

/// Wraps a book page so the member can RIP it: drag up or down on the page
/// (a sideways drag is left alone — that turns the page) and a jagged tear
/// opens through the spot you touched, following the drag, with a paper
/// ripping sound. Let go early and the page stays half torn; start again
/// anywhere else and a NEW tear begins right there. Rip a tear all the way
/// across and only the cut-off piece (the smaller half) falls off the screen —
/// the rest of the page stays, can still be torn further, and can still be
/// turned. Nothing is stored: leaving the screen and coming back gives a
/// fresh, whole page.
///
/// Every tear is random — its style ([_TearStyle]), slope and jaggedness
/// differ each time. The page content is drawn through clips only (no
/// snapshots), so it stays smooth while dragging.
class TearablePage extends StatefulWidget {
  const TearablePage({
    super.key,
    required this.child,
    this.onSettled,
  });

  final Widget child;

  /// A tear stopped changing (the finger lifted or a piece finished falling)
  /// — lets the book refresh its snapshot of this page, which it uses for the
  /// page-turn animation.
  final VoidCallback? onSettled;

  @override
  State<TearablePage> createState() => _TearablePageState();
}

class _TearablePageState extends State<TearablePage>
    with TickerProviderStateMixin {
  static const _points = 18;
  static const _maxOpenAngle = 0.22;
  static const _ripSound = 'audio/paper_tear.wav';

  final math.Random _random = math.Random();
  final AudioPlayer _audio = AudioPlayer();

  /// Tears still on the page: half-open ones and ones whose piece is falling.
  final List<_Tear> _tears = [];

  /// Pieces that have fallen away for good (page coordinates).
  final List<List<Offset>> _fallen = [];

  _Tear? _active;
  bool _soundPlayed = false;

  @override
  void initState() {
    super.initState();
    unawaited(_prepareAudio());
  }

  Future<void> _prepareAudio() async {
    try {
      await _audio.setAudioContext(
        AudioContext(
          android: const AudioContextAndroid(
            isSpeakerphoneOn: false,
            stayAwake: false,
            contentType: AndroidContentType.sonification,
            usageType: AndroidUsageType.media,
            audioFocus: AndroidAudioFocus.gainTransientMayDuck,
          ),
          iOS: AudioContextIOS(category: AVAudioSessionCategory.ambient),
        ),
      );
      await _audio.setReleaseMode(ReleaseMode.stop);
      await _audio.setSource(AssetSource(_ripSound));
    } catch (e) {
      debugPrint('[tear-audio] could not prepare: $e');
    }
  }

  Future<void> _playRip() async {
    try {
      await _audio.setPlaybackRate(.9 + _random.nextDouble() * .25);
      await _audio.setVolume(1);
      await _audio.seek(Duration.zero);
      await _audio.resume();
    } catch (e) {
      debugPrint('[tear-audio] could not play: $e');
    }
  }

  @override
  void dispose() {
    for (final t in _tears) {
      t.fall?.dispose();
    }
    unawaited(_audio.dispose());
    super.dispose();
  }

  // ----------------------------------------------------------------- gestures

  void _onDragStart(DragStartDetails details, Size size) {
    final at = details.localPosition;
    _soundPlayed = false;

    final r = _random.nextDouble();
    final style = r < .38
        ? _TearStyle.flat
        : (r < .72 ? _TearStyle.diagonal : _TearStyle.vertical);

    // The rip runs through the spot that was touched, from the nearest edge.
    late final bool fromStart;
    late double startFrac;
    late double slope;

    switch (style) {
      case _TearStyle.flat:
        fromStart = at.dx < size.width / 2;
        startFrac = (at.dy / size.height).clamp(.1, .9);
        slope = (_random.nextDouble() - .5) * .14;
      case _TearStyle.diagonal:
        fromStart = at.dx < size.width / 2;
        final sign = _random.nextBool() ? 1.0 : -1.0;
        slope = sign * (.35 + _random.nextDouble() * .3);
        // pass through the touch point: y(t) = startFrac + slope * t
        final tTouch = fromStart ? at.dx / size.width : 1 - at.dx / size.width;
        startFrac = at.dy / size.height - slope * tTouch;
        // keep both ends inside the page (flatten the slope if needed)
        while ((startFrac < .03 || startFrac + slope > .97 ||
                startFrac > .97 || startFrac + slope < .03) &&
            slope.abs() > .05) {
          slope *= .8;
          startFrac = at.dy / size.height - slope * tTouch;
        }
        startFrac = startFrac.clamp(.03, .97);
      case _TearStyle.vertical:
        fromStart = at.dy < size.height / 2;
        startFrac = (at.dx / size.width).clamp(.1, .9);
        slope = (_random.nextDouble() - .5) * .12;
    }

    final tear = _Tear(
      style: style,
      fromStart: fromStart,
      startFrac: startFrac,
      slope: slope,
      jag: List.generate(_points, (_) => (_random.nextDouble() - .5) * .034),
    );
    _active = tear;
  }

  void _onDragUpdate(DragUpdateDetails details, Size size) {
    final tear = _active;
    if (tear == null || tear.complete) return;

    final next = (tear.progress + details.delta.dy.abs() / (size.height * .75))
        .clamp(0.0, 1.0);
    if (next == tear.progress) return;

    if (!_tears.contains(tear)) _tears.add(tear);

    if (!_soundPlayed) {
      _soundPlayed = true;
      unawaited(_playRip());
      HapticFeedback.lightImpact();
    }

    setState(() => tear.progress = next);
    if (tear.complete) _startFall(tear, size);
  }

  void _onDragEnd() {
    final tear = _active;
    _active = null;
    if (tear == null) return;
    if (tear.complete) return; // the rip sound carries on with the fall
    unawaited(_audio.stop());
    if (_tears.contains(tear)) widget.onSettled?.call();
  }

  void _startFall(_Tear tear, Size size) {
    final geo = _geometry(tear, size);
    tear.fallenIsUpper = _area(geo.upper) <= _area(geo.lower);

    final controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 800),
    );
    tear.fall = controller;
    controller
      ..addListener(() {
        if (mounted) setState(() {});
      })
      ..addStatusListener((status) {
        if (status != AnimationStatus.completed || !mounted) return;
        setState(() {
          // The fallen half is gone for good; the other half is simply what
          // is left of the page.
          _fallen.add(tear.fallenIsUpper! ? geo.upper : geo.lower);
          _tears.remove(tear);
        });
        controller.dispose();
        widget.onSettled?.call();
      })
      ..forward();
  }

  // ----------------------------------------------------------------- geometry

  static double _area(List<Offset> poly) {
    var sum = 0.0;
    for (var i = 0; i < poly.length; i++) {
      final a = poly[i];
      final b = poly[(i + 1) % poly.length];
      sum += a.dx * b.dy - b.dx * a.dy;
    }
    return sum.abs() / 2;
  }

  Size _space(_Tear t, Size page) => t.vertical ? Size(page.height, page.width) : page;

  Offset _real(_Tear t, Offset p) => t.vertical ? Offset(p.dy, p.dx) : p;

  List<Offset> _realAll(_Tear t, Iterable<Offset> pts) =>
      pts.map((p) => _real(t, p)).toList();

  _Geometry _geometry(_Tear t, Size page) {
    final space = _space(t, page);

    final line = <Offset>[];
    for (var i = 0; i < _points; i++) {
      final f = i / (_points - 1);
      final y = (t.startFrac + t.slope * f + (i == 0 ? 0 : t.jag[i])) * space.height;
      final x = (t.fromStart ? f : 1 - f) * space.width;
      line.add(Offset(x, y));
    }

    final startX = t.fromStart ? 0.0 : space.width;
    final farX = t.fromStart ? space.width : 0.0;

    if (t.complete) {
      return _Geometry(
        upper: _realAll(t, [...line, Offset(farX, 0), Offset(startX, 0)]),
        lower: _realAll(t, [...line, Offset(farX, space.height), Offset(startX, space.height)]),
        edge: _realAll(t, line),
        tip: _real(t, line.last),
      );
    }

    // The tear has reached `progress` of the way across; interpolate its tip.
    final exact = t.progress * (_points - 1);
    final whole = exact.floor().clamp(0, _points - 2);
    final tip = Offset.lerp(line[whole], line[whole + 1], exact - whole)!;
    final done = <Offset>[...line.take(whole + 1), tip];

    // Where the torn part ends and the whole paper begins: a ragged line
    // across the tear through the tip, so the flap looks torn from the rest
    // rather than cut along a ruler.
    const steps = 16;
    final boundary = <Offset>[
      for (var k = 0; k <= steps; k++)
        Offset(
          tip.dx + t.jag[k % _points] * space.width * 2.2,
          space.height * k / steps,
        ),
    ];
    final above = boundary.where((p) => p.dy < tip.dy).toList().reversed;
    final below = boundary.where((p) => p.dy > tip.dy);

    return _Geometry(
      upper: _realAll(t, [...done, ...above, Offset(startX, 0)]),
      lower: _realAll(t, [...done, ...below, Offset(startX, space.height)]),
      edge: _realAll(t, done),
      tip: _real(t, tip),
    );
  }

  Path _poly(List<Offset> pts) => Path()..addPolygon(pts, true);

  // -------------------------------------------------------------------- build

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final size = constraints.biggest;

        return GestureDetector(
          behavior: HitTestBehavior.translucent,
          onVerticalDragStart: (d) => _onDragStart(d, size),
          onVerticalDragUpdate: (d) => _onDragUpdate(d, size),
          onVerticalDragEnd: (_) => _onDragEnd(),
          onVerticalDragCancel: _onDragEnd,
          child: (_tears.isEmpty && _fallen.isEmpty)
              ? widget.child
              : _buildTorn(size),
        );
      },
    );
  }

  Widget _buildTorn(Size page) {
    // What is left of the page: the whole sheet minus every piece that fell.
    var keep = Path()..addRect(Offset.zero & page);
    for (final gone in _fallen) {
      keep = Path.combine(PathOperation.difference, keep, _poly(gone));
    }

    var base = keep;
    final layers = <Widget>[];

    Widget piece(
      Path region,
      List<Offset> edge, {
      required Offset tip,
      double angle = 0,
      Offset drift = Offset.zero,
      double opacity = 1,
    }) {
      final m = Matrix4.identity()
        ..translate(drift.dx, drift.dy)
        ..translate(tip.dx, tip.dy)
        ..rotateZ(angle)
        ..translate(-tip.dx, -tip.dy);
      return Opacity(
        opacity: opacity,
        child: Transform(
          transform: m,
          child: ClipPath(
            clipper: _PathClipper(region),
            child: CustomPaint(
              foregroundPainter: _TornEdgePainter(edge),
              child: widget.child,
            ),
          ),
        ),
      );
    }

    for (final t in _tears) {
      final geo = _geometry(t, page);
      final upperPath = Path.combine(PathOperation.intersect, keep, _poly(geo.upper));
      final lowerPath = Path.combine(PathOperation.intersect, keep, _poly(geo.lower));

      // The flaps are drawn separately, so cut them out of the plain page.
      base = Path.combine(PathOperation.difference, base, _poly(geo.upper));
      base = Path.combine(PathOperation.difference, base, _poly(geo.lower));

      final dir = (t.fromStart ? 1.0 : -1.0) * (t.vertical ? -1.0 : 1.0);

      if (!t.complete) {
        // Half torn: the two flaps open like a wedge around the tip.
        final open = t.progress * _maxOpenAngle;
        layers
          ..add(piece(upperPath, geo.edge, tip: geo.tip, angle: -dir * open))
          ..add(piece(lowerPath, geo.edge, tip: geo.tip, angle: dir * open));
      } else {
        // Torn right across: the smaller half falls, the other stays put.
        final f = Curves.easeIn.transform(t.fall?.value ?? 0);
        final upperFalls = t.fallenIsUpper ?? true;
        final side = (t.fromStart ? 1.0 : -1.0) * (upperFalls ? -1.0 : 1.0);
        final fallAngle = (upperFalls ? -dir : dir) * (_maxOpenAngle + f * .55);
        final fade = 1 - (f - .65).clamp(0.0, .35) / .35;

        layers
          ..add(piece(upperFalls ? lowerPath : upperPath, geo.edge, tip: geo.tip))
          ..add(piece(
            upperFalls ? upperPath : lowerPath,
            geo.edge,
            tip: geo.tip,
            angle: fallAngle,
            drift: Offset(side * page.width * .12 * f, page.height * 1.2 * f),
            opacity: fade,
          ));
      }
    }

    return Stack(
      fit: StackFit.expand,
      children: [
        ClipPath(clipper: _PathClipper(base), child: widget.child),
        ...layers,
      ],
    );
  }
}

class _Geometry {
  const _Geometry({
    required this.upper,
    required this.lower,
    required this.edge,
    required this.tip,
  });

  /// The two sides of the rip (the part torn so far), in page coordinates.
  final List<Offset> upper;
  final List<Offset> lower;

  /// The rip line itself, for drawing the ragged paper edge.
  final List<Offset> edge;
  final Offset tip;
}

class _PathClipper extends CustomClipper<Path> {
  const _PathClipper(this.path);

  final Path path;

  @override
  Path getClip(Size size) => path;

  @override
  bool shouldReclip(_PathClipper old) => true;
}

/// The white, slightly shadowed ragged edge along the rip.
class _TornEdgePainter extends CustomPainter {
  const _TornEdgePainter(this.line);

  final List<Offset> line;

  @override
  void paint(Canvas canvas, Size size) {
    if (line.length < 2) return;
    final path = Path()..addPolygon(line, false);
    canvas.drawPath(
      path.shift(const Offset(0, 1.5)),
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 3
        ..color = Colors.black.withOpacity(.18),
    );
    canvas.drawPath(
      path,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2.4
        ..strokeJoin = StrokeJoin.bevel
        ..color = const Color(0xFFFBF8F0),
    );
  }

  @override
  bool shouldRepaint(_TornEdgePainter old) => true;
}
