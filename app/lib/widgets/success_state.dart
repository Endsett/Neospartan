import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../theme.dart';

/// Success State Widget - Animated success feedback
class SuccessState extends StatelessWidget {
  final String message;
  final String? submessage;
  final VoidCallback? onContinue;
  final String? continueLabel;

  const SuccessState({
    super.key,
    required this.message,
    this.submessage,
    this.onContinue,
    this.continueLabel,
  });

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [LaconicTheme.spartanBronze, LaconicTheme.warmGold],
                ),
                borderRadius: BorderRadius.circular(50),
                boxShadow: [
                  BoxShadow(
                    color: LaconicTheme.spartanBronze.withOpacity(0.3),
                    blurRadius: 20,
                    offset: const Offset(0, 8),
                  ),
                ],
              ),
              child: const Icon(
                Icons.check,
                size: 48,
                color: LaconicTheme.deepBlack,
              ),
            )
                .animate()
                .scale(duration: 400.ms, curve: Curves.easeOutBack)
                .then(delay: 100.ms)
                .shake(duration: 300.ms),
            const SizedBox(height: 24),
            Text(
              message,
              style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                color: LaconicTheme.warmGold,
              ),
              textAlign: TextAlign.center,
            ),
            if (submessage != null) ...[
              const SizedBox(height: 8),
              Text(
                submessage!,
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: LaconicTheme.mistGray,
                ),
                textAlign: TextAlign.center,
              ),
            ],
            if (onContinue != null) ...[
              const SizedBox(height: 32),
              ElevatedButton.icon(
                onPressed: onContinue,
                icon: const Icon(Icons.arrow_forward),
                label: Text(continueLabel ?? 'Continue'),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
