import 'package:flutter/material.dart';

class RubikControlButton extends StatefulWidget {
  final String label;
  final IconData icon;
  final VoidCallback? onPressed;
  final Color color;
  final bool isLoading;

  const RubikControlButton({
    super.key,
    required this.label,
    required this.icon,
    required this.onPressed,
    this.color = Colors.blue,
    this.isLoading = false,
  });

  @override
  State<RubikControlButton> createState() => _RubikControlButtonState();
}

class _RubikControlButtonState extends State<RubikControlButton>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _scaleAnimation;
  late Animation<double> _rotateAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(milliseconds: 300),
      vsync: this,
    );

    _scaleAnimation = Tween<double>(begin: 1.0, end: 0.95).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeInOut),
    );

    _rotateAnimation = Tween<double>(begin: 0, end: 0.5).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _onTapDown(TapDownDetails details) {
    if (widget.onPressed != null) {
      _controller.forward();
    }
  }

  void _onTapUp(TapUpDetails details) {
    _controller.reverse();
  }

  void _onTapCancel() {
    _controller.reverse();
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTapDown: _onTapDown,
      onTapUp: _onTapUp,
      onTapCancel: _onTapCancel,
      onTap: widget.onPressed,
      child: Column(
        children: [
          AnimatedBuilder(
            animation: _scaleAnimation,
            builder: (context, child) {
              return Transform.scale(
                scale: _scaleAnimation.value,
                child: child,
              );
            },
            child: Container(
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: widget.color,
                boxShadow: [
                  BoxShadow(
                    color: widget.color.withOpacity(0.4),
                    blurRadius: 12,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              padding: const EdgeInsets.all(16),
              child: widget.isLoading
                  ? SizedBox(
                      width: 24,
                      height: 24,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        valueColor: const AlwaysStoppedAnimation(Colors.white),
                      ),
                    )
                  : Icon(
                      widget.icon,
                      color: Colors.white,
                      size: 28,
                    ),
            ),
          ),
          const SizedBox(height: 12),
          Text(
            widget.label,
            style: const TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w600,
              height: 1.2,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }
}

class AnimatedSolutionCard extends StatefulWidget {
  final String move;
  final bool isCurrent;
  final bool isDone;

  const AnimatedSolutionCard({
    super.key,
    required this.move,
    this.isCurrent = false,
    this.isDone = false,
  });

  @override
  State<AnimatedSolutionCard> createState() => _AnimatedSolutionCardState();
}

class _AnimatedSolutionCardState extends State<AnimatedSolutionCard>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _scaleAnimation;
  late Animation<Color?> _colorAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(milliseconds: 400),
      vsync: this,
    );

    _scaleAnimation = Tween<double>(begin: 0.8, end: 1.0).animate(
      CurvedAnimation(parent: _controller, curve: Curves.elasticOut),
    );

    final startColor = widget.isDone ? Colors.green[200] : Colors.grey[300];
    final endColor = widget.isCurrent
        ? Colors.blue[300]
        : widget.isDone
            ? Colors.green[200]
            : Colors.grey[300];

    _colorAnimation = ColorTween(begin: startColor, end: endColor).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeInOut),
    );

    _controller.forward();
  }

  @override
  void didUpdateWidget(AnimatedSolutionCard oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.isCurrent != oldWidget.isCurrent ||
        widget.isDone != oldWidget.isDone) {
      _controller.forward(from: 0);
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
        return Transform.scale(
          scale: _scaleAnimation.value,
          child: Container(
            padding: const EdgeInsets.symmetric(
              horizontal: 10,
              vertical: 6,
            ),
            decoration: BoxDecoration(
              color: _colorAnimation.value,
              borderRadius: BorderRadius.circular(6),
              border: Border.all(
                color: widget.isCurrent ? Colors.blue : Colors.grey,
                width: widget.isCurrent ? 2 : 1,
              ),
              boxShadow: widget.isCurrent
                  ? [
                      BoxShadow(
                        color: Colors.blue.withOpacity(0.3),
                        blurRadius: 8,
                        offset: const Offset(0, 2),
                      ),
                    ]
                  : [],
            ),
            child: Text(
              widget.move,
              style: TextStyle(
                fontFamily: 'monospace',
                fontWeight:
                    widget.isCurrent ? FontWeight.bold : FontWeight.normal,
                color: widget.isCurrent ? Colors.white : Colors.black,
                fontSize: 12,
              ),
            ),
          ),
        );
      },
    );
  }
}
