import 'package:flutter/material.dart';

class AppShimmer extends StatefulWidget {
  final Widget child;

  const AppShimmer({
    super.key,
    required this.child,
  });

  @override
  State<AppShimmer> createState() => _AppShimmerState();
}

class _AppShimmerState extends State<AppShimmer>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;

  @override
  void initState() {
    super.initState();

    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1200),
    )..repeat();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _controller,
      child: widget.child,
      builder: (context, child) {
        return ShaderMask(
          blendMode: BlendMode.srcATop,
          shaderCallback: (bounds) {
            return LinearGradient(
              begin: Alignment(-1.0 + (_controller.value * 2), 0),
              end: Alignment(0.0 + (_controller.value * 2), 0),
              colors: [
                const Color(0xFFE5E5E5),
                const Color(0xFFF5F5F5),
                const Color(0xFFE5E5E5),
              ],
              stops: const [0.2, 0.5, 0.8],
            ).createShader(bounds);
          },
          child: child,
        );
      },
    );
  }
}