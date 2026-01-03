import 'package:flutter/material.dart';
import 'dart:math' as math;

class RotatingCubeView extends StatefulWidget {
  final Duration duration;
  final bool isRotating;

  const RotatingCubeView({
    super.key,
    this.duration = const Duration(seconds: 4),
    this.isRotating = true,
  });

  @override
  State<RotatingCubeView> createState() => _RotatingCubeViewState();
}

class _RotatingCubeViewState extends State<RotatingCubeView>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: widget.duration,
      vsync: this,
    );

    if (widget.isRotating) {
      _controller.repeat();
    }
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
      builder: (context, child) {
        return Transform(
          alignment: Alignment.center,
          transform: Matrix4.identity()
            ..setEntry(3, 2, 0.001)
            ..rotateX(_controller.value * 2 * math.pi * 0.5)
            ..rotateY(_controller.value * 2 * math.pi)
            ..rotateZ(_controller.value * 2 * math.pi * 0.3),
          child: Container(
            width: 160,
            height: 160,
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(12),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.15),
                  blurRadius: 15,
                  offset: const Offset(0, 5),
                )
              ],
            ),
            child: Stack(
              children: [
                // Front face (Blue)
                Positioned.fill(
                  child: Transform.translate(
                    offset: const Offset(0, 0),
                    child: Container(
                      decoration: BoxDecoration(
                        color: Colors.blue[400],
                        borderRadius: BorderRadius.circular(8),
                      ),
                      margin: const EdgeInsets.all(4),
                      child: const Center(
                        child: Text(
                          'F',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 24,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}

class AnimatedCubeTransition extends StatefulWidget {
  final Widget child;
  final Duration duration;

  const AnimatedCubeTransition({
    super.key,
    required this.child,
    this.duration = const Duration(milliseconds: 500),
  });

  @override
  State<AnimatedCubeTransition> createState() => _AnimatedCubeTransitionState();
}

class _AnimatedCubeTransitionState extends State<AnimatedCubeTransition>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _animation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: widget.duration,
      vsync: this,
    );

    _animation = Tween<double>(begin: 0, end: 1).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeInOut),
    );

    _controller.forward();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _animation,
      builder: (context, child) {
        return Transform(
          alignment: Alignment.center,
          transform: Matrix4.identity()
            ..setEntry(3, 2, 0.001)
            ..rotateY(_animation.value * math.pi),
          child: Opacity(
            opacity: 1.0 - (_animation.value * 0.3),
            child: child!,
          ),
        );
      },
      child: widget.child,
    );
  }
}
