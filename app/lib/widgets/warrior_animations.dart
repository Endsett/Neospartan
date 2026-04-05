import 'package:flutter/material.dart';
import 'dart:math' as math;
import '../theme.dart';

/// Warrior-themed loading screen with animated shield and combat effects
class WarriorLoadingScreen extends StatefulWidget {
  final String? message;
  final double progress;
  final bool showProgress;

  const WarriorLoadingScreen({
    super.key,
    this.message,
    this.progress = 0.0,
    this.showProgress = false,
  });

  @override
  State<WarriorLoadingScreen> createState() => _WarriorLoadingScreenState();
}

class _WarriorLoadingScreenState extends State<WarriorLoadingScreen>
    with TickerProviderStateMixin {
  late AnimationController _shieldController;
  late AnimationController _pulseController;
  late AnimationController _sparkController;
  late Animation<double> _shieldRotation;
  late Animation<double> _pulseAnimation;
  late Animation<double> _sparkAnimation;

  @override
  void initState() {
    super.initState();

    // Shield rotation animation
    _shieldController = AnimationController(
      duration: const Duration(seconds: 3),
      vsync: this,
    )..repeat();

    _shieldRotation = Tween<double>(begin: 0, end: 2 * math.pi).animate(
      CurvedAnimation(parent: _shieldController, curve: Curves.easeInOut),
    );

    // Pulse animation
    _pulseController = AnimationController(
      duration: const Duration(milliseconds: 1500),
      vsync: this,
    )..repeat(reverse: true);

    _pulseAnimation = Tween<double>(begin: 0.8, end: 1.2).animate(
      CurvedAnimation(parent: _pulseController, curve: Curves.easeInOut),
    );

    // Spark animation
    _sparkController = AnimationController(
      duration: const Duration(milliseconds: 800),
      vsync: this,
    )..repeat(reverse: true);

    _sparkAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _sparkController, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _shieldController.dispose();
    _pulseController.dispose();
    _sparkController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // Animated shield
            AnimatedBuilder(
              animation: Listenable.merge([
                _shieldController,
                _pulseController,
              ]),
              builder: (context, child) {
                return Transform.scale(
                  scale: _pulseAnimation.value,
                  child: CustomPaint(
                    size: const Size(120, 140),
                    painter: _ShieldPainter(
                      rotation: _shieldRotation.value,
                      sparkIntensity: _sparkAnimation.value,
                    ),
                  ),
                );
              },
            ),

            const SizedBox(height: 40),

            // Loading text
            Text(
              widget.message ?? 'PREPARING FOR BATTLE',
              style: const TextStyle(
                color: LaconicTheme.spartanBronze,
                fontSize: 14,
                letterSpacing: 4.0,
                fontWeight: FontWeight.bold,
              ),
            ),

            const SizedBox(height: 20),

            // Progress indicator with warrior styling
            if (widget.showProgress) ...[
              SizedBox(
                width: 200,
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(2),
                  child: LinearProgressIndicator(
                    value: widget.progress > 0 ? widget.progress : null,
                    backgroundColor: LaconicTheme.ironGray.withOpacity(0.3),
                    valueColor: const AlwaysStoppedAnimation<Color>(
                      LaconicTheme.spartanBronze,
                    ),
                    minHeight: 4,
                  ),
                ),
              ),
              const SizedBox(height: 16),
            ],

            // Animated dots
            _AnimatedDots(),
          ],
        ),
      ),
    );
  }
}

/// Shield painter with animated effects
class _ShieldPainter extends CustomPainter {
  final double rotation;
  final double sparkIntensity;

  _ShieldPainter({required this.rotation, required this.sparkIntensity});

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);

    // Shield outline
    final shieldPath = Path()
      ..moveTo(center.dx, 10)
      ..lineTo(size.width - 10, 30)
      ..quadraticBezierTo(
        size.width - 5,
        size.height / 2,
        size.width - 10,
        size.height - 20,
      )
      ..quadraticBezierTo(center.dx, size.height - 5, 10, size.height - 20)
      ..quadraticBezierTo(5, size.height / 2, 10, 30)
      ..close();

    // Shield gradient
    final gradient = LinearGradient(
      begin: Alignment.topLeft,
      end: Alignment.bottomRight,
      colors: [
        LaconicTheme.spartanBronze.withOpacity(0.8),
        LaconicTheme.spartanBronze.withOpacity(0.4),
        LaconicTheme.ironGray.withOpacity(0.6),
      ],
    );

    final shieldPaint = Paint()
      ..shader = gradient.createShader(
        Rect.fromLTWH(0, 0, size.width, size.height),
      )
      ..style = PaintingStyle.fill;

    canvas.drawPath(shieldPath, shieldPaint);

    // Shield border
    final borderPaint = Paint()
      ..color = LaconicTheme.spartanBronze
      ..strokeWidth = 3
      ..style = PaintingStyle.stroke;

    canvas.drawPath(shieldPath, borderPaint);

    // Lambda symbol (Spartan shield emblem)
    final textPainter = TextPainter(
      text: const TextSpan(
        text: 'Λ',
        style: TextStyle(
          color: Colors.black,
          fontSize: 48,
          fontWeight: FontWeight.bold,
        ),
      ),
      textDirection: TextDirection.ltr,
      textAlign: TextAlign.center,
    );

    textPainter.layout();
    textPainter.paint(
      canvas,
      Offset(
        center.dx - textPainter.width / 2,
        center.dy - textPainter.height / 2,
      ),
    );

    // Spark effects
    if (sparkIntensity > 0.5) {
      final sparkPaint = Paint()
        ..color = LaconicTheme.spartanBronze.withOpacity(sparkIntensity)
        ..strokeWidth = 2
        ..style = PaintingStyle.stroke;

      // Random spark lines
      for (int i = 0; i < 8; i++) {
        final angle = (i / 8) * 2 * math.pi + rotation;
        final startRadius = 70.0;
        final endRadius = 80.0 + (sparkIntensity * 10);

        final startX = center.dx + math.cos(angle) * startRadius;
        final startY = center.dy + math.sin(angle) * startRadius;
        final endX = center.dx + math.cos(angle) * endRadius;
        final endY = center.dy + math.sin(angle) * endRadius;

        canvas.drawLine(Offset(startX, startY), Offset(endX, endY), sparkPaint);
      }
    }
  }

  @override
  bool shouldRepaint(covariant _ShieldPainter oldDelegate) {
    return oldDelegate.rotation != rotation ||
        oldDelegate.sparkIntensity != sparkIntensity;
  }
}

/// Animated loading dots
class _AnimatedDots extends StatefulWidget {
  @override
  State<_AnimatedDots> createState() => _AnimatedDotsState();
}

class _AnimatedDotsState extends State<_AnimatedDots>
    with TickerProviderStateMixin {
  late AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(milliseconds: 1200),
      vsync: this,
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
      builder: (context, child) {
        return Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: List.generate(3, (index) {
            final delay = index * 0.3;
            final animationValue = (_controller.value + delay) % 1.0;
            final opacity = animationValue < 0.5
                ? animationValue * 2
                : (1 - animationValue) * 2;

            return Container(
              margin: const EdgeInsets.symmetric(horizontal: 4),
              width: 8,
              height: 8,
              decoration: BoxDecoration(
                color: LaconicTheme.spartanBronze.withOpacity(opacity),
                shape: BoxShape.circle,
              ),
            );
          }),
        );
      },
    );
  }
}

/// Combat-style page transition
class CombatPageTransition extends PageRouteBuilder {
  final Widget child;

  CombatPageTransition({required this.child})
    : super(
        pageBuilder: (context, animation, secondaryAnimation) => child,
        transitionsBuilder: (context, animation, secondaryAnimation, child) {
          // Slide from right with fade
          final slideAnimation =
              Tween<Offset>(
                begin: const Offset(1.0, 0.0),
                end: Offset.zero,
              ).animate(
                CurvedAnimation(
                  parent: animation,
                  curve: const Interval(0.0, 0.7, curve: Curves.easeOutCubic),
                ),
              );

          // Fade animation
          final fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
            CurvedAnimation(
              parent: animation,
              curve: const Interval(0.0, 0.5, curve: Curves.easeIn),
            ),
          );

          // Scale animation for impact
          final scaleAnimation = Tween<double>(begin: 0.95, end: 1.0).animate(
            CurvedAnimation(
              parent: animation,
              curve: const Interval(0.0, 0.7, curve: Curves.easeOutBack),
            ),
          );

          return FadeTransition(
            opacity: fadeAnimation,
            child: SlideTransition(
              position: slideAnimation,
              child: ScaleTransition(scale: scaleAnimation, child: child),
            ),
          );
        },
        transitionDuration: const Duration(milliseconds: 500),
        reverseTransitionDuration: const Duration(milliseconds: 400),
      );
}

/// Battle-ready button with press animations
class BattleButton extends StatefulWidget {
  final String text;
  final VoidCallback onPressed;
  final bool isPrimary;
  final IconData? icon;

  const BattleButton({
    super.key,
    required this.text,
    required this.onPressed,
    this.isPrimary = true,
    this.icon,
  });

  @override
  State<BattleButton> createState() => _BattleButtonState();
}

class _BattleButtonState extends State<BattleButton>
    with SingleTickerProviderStateMixin {
  late AnimationController _pressController;
  late Animation<double> _scaleAnimation;

  @override
  void initState() {
    super.initState();
    _pressController = AnimationController(
      duration: const Duration(milliseconds: 150),
      vsync: this,
    );
    _scaleAnimation = Tween<double>(begin: 1.0, end: 0.95).animate(
      CurvedAnimation(parent: _pressController, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _pressController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTapDown: (_) => _pressController.forward(),
      onTapUp: (_) {
        _pressController.reverse();
        widget.onPressed();
      },
      onTapCancel: () => _pressController.reverse(),
      child: AnimatedBuilder(
        animation: _scaleAnimation,
        builder: (context, child) {
          return Transform.scale(
            scale: _scaleAnimation.value,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 16),
              decoration: BoxDecoration(
                color: widget.isPrimary
                    ? LaconicTheme.spartanBronze
                    : Colors.transparent,
                border: Border.all(color: LaconicTheme.spartanBronze, width: 2),
                borderRadius: BorderRadius.circular(4),
                boxShadow: widget.isPrimary
                    ? [
                        BoxShadow(
                          color: LaconicTheme.spartanBronze.withOpacity(0.4),
                          blurRadius: 12,
                          spreadRadius: 2,
                        ),
                      ]
                    : null,
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  if (widget.icon != null) ...[
                    Icon(
                      widget.icon,
                      color: widget.isPrimary
                          ? Colors.black
                          : LaconicTheme.spartanBronze,
                      size: 20,
                    ),
                    const SizedBox(width: 8),
                  ],
                  Text(
                    widget.text,
                    style: TextStyle(
                      color: widget.isPrimary
                          ? Colors.black
                          : LaconicTheme.spartanBronze,
                      fontSize: 14,
                      fontWeight: FontWeight.bold,
                      letterSpacing: 2.0,
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}
