import 'dart:async';

import 'package:flutter/material.dart';

/// Fades and slides its [child] up into place once, [index] steps after the
/// screen appears — wrap the sections of a page with increasing indexes and
/// they come in one after another instead of all at once.
///
/// The animation is driven by a single controller feeding a [FadeTransition]
/// and a [SlideTransition] around the prebuilt child, so the child is never
/// rebuilt while it plays.
class StaggeredReveal extends StatefulWidget {
  const StaggeredReveal({
    super.key,
    required this.index,
    required this.child,
    this.step = const Duration(milliseconds: 90),
    this.duration = const Duration(milliseconds: 560),
    this.offset = const Offset(0, .10),
  });

  /// Position in the sequence — the reveal starts `index * step` after build.
  final int index;

  final Widget child;

  final Duration step;

  final Duration duration;

  /// Where the child slides in from, as a fraction of its own size.
  final Offset offset;

  @override
  State<StaggeredReveal> createState() => _StaggeredRevealState();
}

class _StaggeredRevealState extends State<StaggeredReveal> with SingleTickerProviderStateMixin {
  late final AnimationController _controller = AnimationController(
    vsync: this,
    duration: widget.duration,
  );

  late final Animation<double> _curve = CurvedAnimation(
    parent: _controller,
    curve: Curves.easeOutCubic,
  );

  Timer? _timer;

  @override
  void initState() {
    super.initState();
    _timer = Timer(widget.step * widget.index, () {
      if (mounted) _controller.forward();
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return FadeTransition(
      opacity: _curve,
      child: SlideTransition(
        position: Tween<Offset>(begin: widget.offset, end: Offset.zero).animate(_curve),
        child: widget.child,
      ),
    );
  }
}
