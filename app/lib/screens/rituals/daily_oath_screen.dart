import 'dart:async';
import 'package:flutter/material.dart';
import '../../warrior_theme.dart';
import '../../warrior_constants.dart';
import '../../services/warrior_progress_service.dart';
import '../agoge_screen.dart';

/// Daily Oath Screen - Entry ritual for daily commitment
/// Part of the warrior forge experience
class DailyOathScreen extends StatefulWidget {
  final VoidCallback onOathCompleted;

  const DailyOathScreen({super.key, required this.onOathCompleted});

  @override
  State<DailyOathScreen> createState() => _DailyOathScreenState();
}

class _DailyOathScreenState extends State<DailyOathScreen>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _fadeInAnimation;
  late Animation<double> _slideAnimation;
  late Animation<double> _pulseAnimation;

  String _dailyQuote = '';
  bool _showQuote = false;
  bool _showOath = false;
  bool _oathAccepted = false;

  @override
  void initState() {
    super.initState();

    _controller = AnimationController(
      duration: const Duration(milliseconds: 2000),
      vsync: this,
    );

    _fadeInAnimation = CurvedAnimation(
      parent: _controller,
      curve: const Interval(0.0, 0.4, curve: Curves.easeOut),
    );

    _slideAnimation = Tween<double>(begin: 50, end: 0).animate(
      CurvedAnimation(
        parent: _controller,
        curve: const Interval(0.2, 0.6, curve: Curves.easeOutCubic),
      ),
    );

    _pulseAnimation =
        TweenSequence<double>([
          TweenSequenceItem(tween: Tween(begin: 1.0, end: 1.05), weight: 1),
          TweenSequenceItem(tween: Tween(begin: 1.05, end: 1.0), weight: 1),
        ]).animate(
          CurvedAnimation(
            parent: _controller,
            curve: const Interval(0.6, 1.0, curve: Curves.easeInOut),
          ),
        );

    _dailyQuote = WarriorConstants.getRandomQuote();

    // Sequence the animations
    _startSequence();
  }

  void _startSequence() async {
    // Phase 1: Fade in quote
    await Future.delayed(const Duration(milliseconds: 500));
    setState(() => _showQuote = true);

    // Phase 2: Show oath
    await Future.delayed(const Duration(milliseconds: 3000));
    setState(() => _showOath = true);
    _controller.forward();
  }

  void _acceptOath() async {
    setState(() => _oathAccepted = true);

    final progressService = WarriorProgressService();
    await progressService.createOath(
      'I will forge myself today through discipline and effort.',
    );
    await progressService.completeOath();

    // Dramatic exit
    await Future.delayed(const Duration(milliseconds: 800));

    if (mounted) {
      Navigator.of(context).pushReplacement(
        PageRouteBuilder(
          pageBuilder: (context, animation, secondaryAnimation) =>
              const AgogeScreen(),
          transitionsBuilder: (context, animation, secondaryAnimation, child) {
            return FadeTransition(opacity: animation, child: child);
          },
          transitionDuration: const Duration(milliseconds: 800),
        ),
      );
      widget.onOathCompleted();
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: WarriorTheme.background,
      body: SafeArea(
        child: Stack(
          children: [
            // Background gradient
            Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    WarriorTheme.obsidian,
                    WarriorTheme.obsidianLight,
                    WarriorTheme.bronzeMuted.withValues(alpha: 0.1),
                  ],
                ),
              ),
            ),

            // Content
            Padding(
              padding: const EdgeInsets.all(WarriorTheme.spaceXl),
              child: Column(
                children: [
                  const SizedBox(height: WarriorTheme.spaceXxl),

                  // Title
                  Text(
                    'THE FORGE AWAITS',
                    style: WarriorTheme.headlineLarge.copyWith(
                      color: WarriorTheme.bronze,
                      letterSpacing: 6,
                    ),
                  ),

                  const SizedBox(height: WarriorTheme.spaceXxl * 2),

                  // Stoic Quote
                  AnimatedOpacity(
                    opacity: _showQuote ? 1.0 : 0.0,
                    duration: WarriorTheme.durationCinematic,
                    child: Container(
                      padding: const EdgeInsets.all(WarriorTheme.spaceLg),
                      decoration: BoxDecoration(
                        border: Border(
                          left: BorderSide(
                            color: WarriorTheme.bronze.withValues(alpha: 0.5),
                            width: 3,
                          ),
                        ),
                      ),
                      child: Text(
                        _dailyQuote,
                        style: WarriorTheme.oathText,
                        textAlign: TextAlign.center,
                      ),
                    ),
                  ),

                  const Spacer(),

                  // Oath Section
                  AnimatedBuilder(
                    animation: _controller,
                    builder: (context, child) {
                      return Transform.translate(
                        offset: Offset(0, _slideAnimation.value),
                        child: Opacity(
                          opacity: _fadeInAnimation.value,
                          child: child,
                        ),
                      );
                    },
                    child: AnimatedOpacity(
                      opacity: _showOath ? 1.0 : 0.0,
                      duration: WarriorTheme.durationNormal,
                      child: Column(
                        children: [
                          // Oath Text
                          Container(
                            padding: const EdgeInsets.all(WarriorTheme.spaceLg),
                            decoration: BoxDecoration(
                              color: WarriorTheme.surfaceElevated,
                              border: Border.all(
                                color: WarriorTheme.outline,
                                width: 1,
                              ),
                            ),
                            child: Column(
                              children: [
                                Icon(
                                  Icons.shield,
                                  size: 48,
                                  color: WarriorTheme.bronze,
                                ),
                                const SizedBox(height: WarriorTheme.spaceMd),
                                Text(
                                  'DAILY OATH',
                                  style: WarriorTheme.labelLarge.copyWith(
                                    color: WarriorTheme.ash,
                                  ),
                                ),
                                const SizedBox(height: WarriorTheme.spaceMd),
                                Text(
                                  'I commit to forging my body and mind through discipline. I will not retreat. I will not surrender. Today, I become stronger.',
                                  style: WarriorTheme.bodyLarge.copyWith(
                                    color: WarriorTheme.ashLight,
                                  ),
                                  textAlign: TextAlign.center,
                                ),
                              ],
                            ),
                          ),

                          const SizedBox(height: WarriorTheme.spaceXl),

                          // Accept Button
                          AnimatedBuilder(
                            animation: _pulseAnimation,
                            builder: (context, child) {
                              return Transform.scale(
                                scale: _oathAccepted
                                    ? 1.0
                                    : _pulseAnimation.value,
                                child: child,
                              );
                            },
                            child: SizedBox(
                              width: double.infinity,
                              height: 64,
                              child: ElevatedButton(
                                onPressed: _oathAccepted ? null : _acceptOath,
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: _oathAccepted
                                      ? WarriorTheme.success
                                      : WarriorTheme.crimson,
                                  foregroundColor: WarriorTheme.onAccent,
                                  shape: WarriorTheme.shapeSharp,
                                  elevation: 0,
                                ),
                                child: AnimatedSwitcher(
                                  duration: WarriorTheme.durationNormal,
                                  child: _oathAccepted
                                      ? Row(
                                          mainAxisAlignment:
                                              MainAxisAlignment.center,
                                          children: [
                                            const Icon(Icons.check, size: 28),
                                            const SizedBox(
                                              width: WarriorTheme.spaceSm,
                                            ),
                                            Text(
                                              'OATH BOUND',
                                              style: WarriorTheme.labelLarge,
                                            ),
                                          ],
                                        )
                                      : Text(
                                          'ACCEPT THE OATH',
                                          style: WarriorTheme.labelLarge,
                                        ),
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),

                  const SizedBox(height: WarriorTheme.spaceXl),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Small oath widget for inline use
class OathChip extends StatelessWidget {
  final bool isCompleted;
  final VoidCallback? onTap;

  const OathChip({super.key, this.isCompleted = false, this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(
          horizontal: WarriorTheme.spaceMd,
          vertical: WarriorTheme.spaceSm,
        ),
        decoration: BoxDecoration(
          color: isCompleted
              ? WarriorTheme.bronze.withValues(alpha: 0.2)
              : WarriorTheme.surface,
          border: Border.all(
            color: isCompleted ? WarriorTheme.bronze : WarriorTheme.outline,
            width: 1,
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              isCompleted ? Icons.check_circle : Icons.shield_outlined,
              size: 16,
              color: isCompleted ? WarriorTheme.bronze : WarriorTheme.ash,
            ),
            const SizedBox(width: WarriorTheme.spaceSm),
            Text(
              isCompleted ? 'OATH BOUND' : 'SWEAR OATH',
              style: WarriorTheme.labelSmall.copyWith(
                color: isCompleted ? WarriorTheme.bronze : WarriorTheme.ash,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
