import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'dart:math' as math;
import '../theme.dart';

/// Haptic feedback utilities for warrior combat experience
class WarriorHaptics {
  /// Light impact for button presses
  static void buttonPress() {
    HapticFeedback.lightImpact();
  }

  /// Medium impact for selections
  static void selection() {
    HapticFeedback.mediumImpact();
  }

  /// Heavy impact for important actions
  static void heavyAction() {
    HapticFeedback.heavyImpact();
  }

  /// Vibration for completion/success
  static void victory() {
    HapticFeedback.vibrate();
  }

  /// Error feedback
  static void error() {
    HapticFeedback.heavyImpact();
  }
}

/// Animated text with warrior typing effect
class WarriorAnimatedText extends StatefulWidget {
  final String text;
  final TextStyle style;
  final Duration duration;

  const WarriorAnimatedText({
    super.key,
    required this.text,
    required this.style,
    this.duration = const Duration(milliseconds: 1500),
  });

  @override
  State<WarriorAnimatedText> createState() => _WarriorAnimatedTextState();
}

class _WarriorAnimatedTextState extends State<WarriorAnimatedText>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<int> _characterCount;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(duration: widget.duration, vsync: this);

    _characterCount = IntTween(
      begin: 0,
      end: widget.text.length,
    ).animate(CurvedAnimation(parent: _controller, curve: Curves.easeOut));

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
      animation: _characterCount,
      builder: (context, child) {
        final text = widget.text.substring(0, _characterCount.value);
        return Text(text, style: widget.style);
      },
    );
  }
}

/// Shake animation for error states
class ShakeAnimation extends StatefulWidget {
  final Widget child;
  final bool shake;

  const ShakeAnimation({super.key, required this.child, this.shake = false});

  @override
  State<ShakeAnimation> createState() => _ShakeAnimationState();
}

class _ShakeAnimationState extends State<ShakeAnimation>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _animation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(milliseconds: 500),
      vsync: this,
    );
    _animation = Tween<double>(
      begin: 0,
      end: 1,
    ).animate(CurvedAnimation(parent: _controller, curve: Curves.elasticIn));
  }

  @override
  void didUpdateWidget(ShakeAnimation oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.shake && !oldWidget.shake) {
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
      animation: _animation,
      builder: (context, child) {
        final offset =
            10 *
            (1 - _animation.value) *
            math.sin(_animation.value * math.pi * 4);
        return Transform.translate(
          offset: Offset(offset, 0),
          child: widget.child,
        );
      },
    );
  }
}

/// Pulse animation for important elements
class PulseAnimation extends StatefulWidget {
  final Widget child;
  final Duration duration;

  const PulseAnimation({
    super.key,
    required this.child,
    this.duration = const Duration(milliseconds: 1500),
  });

  @override
  State<PulseAnimation> createState() => _PulseAnimationState();
}

class _PulseAnimationState extends State<PulseAnimation>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _animation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(duration: widget.duration, vsync: this)
      ..repeat(reverse: true);

    _animation = Tween<double>(
      begin: 1.0,
      end: 1.05,
    ).animate(CurvedAnimation(parent: _controller, curve: Curves.easeInOut));
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
        return Transform.scale(scale: _animation.value, child: widget.child);
      },
    );
  }
}

/// Slide up animation for entrance
class SlideUpAnimation extends StatefulWidget {
  final Widget child;
  final Duration duration;
  final double delay;

  const SlideUpAnimation({
    super.key,
    required this.child,
    this.duration = const Duration(milliseconds: 600),
    this.delay = 0.0,
  });

  @override
  State<SlideUpAnimation> createState() => _SlideUpAnimationState();
}

class _SlideUpAnimationState extends State<SlideUpAnimation>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<Offset> _slideAnimation;
  late Animation<double> _fadeAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(duration: widget.duration, vsync: this);

    _slideAnimation =
        Tween<Offset>(begin: const Offset(0, 0.3), end: Offset.zero).animate(
          CurvedAnimation(
            parent: _controller,
            curve: Interval(widget.delay, 1.0, curve: Curves.easeOutCubic),
          ),
        );

    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _controller,
        curve: Interval(widget.delay, 1.0, curve: Curves.easeIn),
      ),
    );

    Future.delayed(Duration(milliseconds: (widget.delay * 300).toInt()), () {
      if (mounted) _controller.forward();
    });
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
        return FadeTransition(
          opacity: _fadeAnimation,
          child: SlideTransition(
            position: _slideAnimation,
            child: widget.child,
          ),
        );
      },
    );
  }
}

/// Victory/completion animation
class VictoryAnimation extends StatefulWidget {
  final VoidCallback? onComplete;

  const VictoryAnimation({super.key, this.onComplete});

  @override
  State<VictoryAnimation> createState() => _VictoryAnimationState();
}

class _VictoryAnimationState extends State<VictoryAnimation>
    with TickerProviderStateMixin {
  late AnimationController _scaleController;
  late AnimationController _rotateController;
  late Animation<double> _scaleAnimation;
  late Animation<double> _rotateAnimation;

  @override
  void initState() {
    super.initState();

    _scaleController = AnimationController(
      duration: const Duration(milliseconds: 800),
      vsync: this,
    );

    _rotateController = AnimationController(
      duration: const Duration(milliseconds: 1000),
      vsync: this,
    );

    _scaleAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _scaleController, curve: Curves.elasticOut),
    );

    _rotateAnimation = Tween<double>(begin: 0, end: 2 * math.pi).animate(
      CurvedAnimation(parent: _rotateController, curve: Curves.easeOutBack),
    );

    // Trigger victory haptic
    WarriorHaptics.victory();

    _scaleController.forward();
    _rotateController.forward();

    Future.delayed(const Duration(milliseconds: 1500), () {
      widget.onComplete?.call();
    });
  }

  @override
  void dispose() {
    _scaleController.dispose();
    _rotateController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Center(
      child: AnimatedBuilder(
        animation: Listenable.merge([_scaleController, _rotateController]),
        builder: (context, child) {
          return Transform.scale(
            scale: _scaleAnimation.value,
            child: Transform.rotate(
              angle: _rotateAnimation.value,
              child: Container(
                width: 150,
                height: 150,
                decoration: BoxDecoration(
                  color: LaconicTheme.spartanBronze,
                  shape: BoxShape.circle,
                  boxShadow: [
                    BoxShadow(
                      color: LaconicTheme.spartanBronze.withValues(alpha: 0.6),
                      blurRadius: 30,
                      spreadRadius: 10,
                    ),
                  ],
                ),
                child: const Icon(Icons.check, color: Colors.black, size: 80),
              ),
            ),
          );
        },
      ),
    );
  }
}
