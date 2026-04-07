import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../theme.dart';

/// Phalanx Toggle Screen - Protocol Mode Selection
/// Based on the_phalanx_toggle_confirmation design
class PhalanxToggleScreen extends StatefulWidget {
  final VoidCallback? onComplete;

  const PhalanxToggleScreen({super.key, this.onComplete});

  @override
  State<PhalanxToggleScreen> createState() => _PhalanxToggleScreenState();
}

class _PhalanxToggleScreenState extends State<PhalanxToggleScreen> {
  bool _isAIAdaptive = true;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: LaconicTheme.background,
      appBar: AppBar(
        backgroundColor: LaconicTheme.background,
        elevation: 0,
        leading: const Icon(Icons.menu, color: LaconicTheme.primary),
        title: Text(
          'THE SOVEREIGN ATHLETE',
          style: GoogleFonts.spaceGrotesk(
            fontSize: 20,
            fontWeight: FontWeight.w700,
            color: LaconicTheme.primary,
            letterSpacing: -0.02,
          ),
        ),
        actions: [
          Container(
            width: 40,
            height: 40,
            margin: const EdgeInsets.only(right: 16),
            decoration: BoxDecoration(
              color: LaconicTheme.surfaceContainerHigh,
              border: Border.all(
                color: LaconicTheme.outlineVariant.withValues(alpha: 0.2),
              ),
            ),
            child: const Icon(
              Icons.person,
              color: LaconicTheme.secondary,
              size: 20,
            ),
          ),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header
            Text(
              'SELECT YOUR',
              style: GoogleFonts.spaceGrotesk(
                fontSize: 48,
                fontWeight: FontWeight.w700,
                color: LaconicTheme.onSurface,
                letterSpacing: -0.02,
                height: 1,
              ),
            ),
            Text(
              'PHALANX',
              style: GoogleFonts.spaceGrotesk(
                fontSize: 48,
                fontWeight: FontWeight.w700,
                color: LaconicTheme.secondary,
                letterSpacing: -0.02,
                height: 1,
              ),
            ),
            const SizedBox(height: 16),
            Text(
              'Final deployment configuration. Choose your level of technical intervention for the upcoming cycle.',
              style: GoogleFonts.inter(
                fontSize: 14,
                color: LaconicTheme.outline,
                height: 1.5,
              ),
            ),
            const SizedBox(height: 32),

            // Toggle Cards
            Row(
              children: [
                Expanded(
                  child: _buildToggleCard(
                    icon: Icons.lock_clock,
                    title: 'STRICT FOLLOW',
                    description:
                        'Direct adherence to source protocol. No AI intervention. For the athlete who values purity of methodology over adaptation.',
                    riskFactor: 'STATIC',
                    isSelected: !_isAIAdaptive,
                    onTap: () => setState(() => _isAIAdaptive = false),
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: _buildToggleCard(
                    icon: Icons.psychology,
                    title: 'AI ADAPTIVE',
                    description:
                        'Dynamic auto-regulation. AI adjusts volume and intensity based on daily readiness biometrics and historical fatigue levels.',
                    riskFactor: 'HIGH PERFORMANCE',
                    isSelected: _isAIAdaptive,
                    showProgressBar: true,
                    onTap: () => setState(() => _isAIAdaptive = true),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 32),

            // Protocol Summary
            Container(
              padding: const EdgeInsets.all(1),
              decoration: BoxDecoration(
                color: LaconicTheme.outlineVariant.withValues(alpha: 0.2),
              ),
              child: Row(
                children: [
                  Expanded(
                    child: _buildSummaryItem(
                      'Protocol',
                      'Spartan Foundations II',
                    ),
                  ),
                  Container(
                    width: 1,
                    height: 60,
                    color: LaconicTheme.outlineVariant.withValues(alpha: 0.2),
                  ),
                  Expanded(child: _buildSummaryItem('Duration', '12 Weeks')),
                  Container(
                    width: 1,
                    height: 60,
                    color: LaconicTheme.outlineVariant.withValues(alpha: 0.2),
                  ),
                  Expanded(
                    child: _buildSummaryItem(
                      'Primary Focus',
                      'Neural Adaptation',
                    ),
                  ),
                ],
              ),
            ),

            const Spacer(),

            // Commence Protocol Button
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: widget.onComplete,
                style: ElevatedButton.styleFrom(
                  backgroundColor: LaconicTheme.secondary,
                  foregroundColor: LaconicTheme.onSecondary,
                  elevation: 0,
                  padding: const EdgeInsets.symmetric(vertical: 20),
                  shape: const RoundedRectangleBorder(
                    borderRadius: BorderRadius.zero,
                  ),
                ),
                child: Text(
                  'COMMENCE PROTOCOL',
                  style: GoogleFonts.spaceGrotesk(
                    fontSize: 18,
                    fontWeight: FontWeight.w900,
                    letterSpacing: 0.1,
                  ),
                ),
              ),
            ),
            const SizedBox(height: 12),
            Center(
              child: Text(
                'By commencing, you acknowledge the physical rigors of the Agoge.',
                style: GoogleFonts.workSans(
                  fontSize: 10,
                  color: LaconicTheme.outline,
                  letterSpacing: 0.05,
                ),
              ),
            ),
            const SizedBox(height: 24),
          ],
        ),
      ),
    );
  }

  Widget _buildToggleCard({
    required IconData icon,
    required String title,
    required String description,
    required String riskFactor,
    required bool isSelected,
    required VoidCallback onTap,
    bool showProgressBar = false,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(
          color: isSelected
              ? LaconicTheme.surfaceContainerHigh
              : LaconicTheme.surfaceContainer,
          border: Border.all(
            color: isSelected
                ? LaconicTheme.secondary
                : LaconicTheme.outlineVariant.withValues(alpha: 0.2),
            width: isSelected ? 2 : 1,
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Icon(
                  icon,
                  color: isSelected
                      ? LaconicTheme.secondary
                      : LaconicTheme.outline,
                  size: 32,
                ),
                Container(
                  width: 24,
                  height: 24,
                  decoration: BoxDecoration(
                    border: Border.all(
                      color: isSelected
                          ? LaconicTheme.secondary
                          : LaconicTheme.outlineVariant,
                      width: 2,
                    ),
                    color: isSelected
                        ? LaconicTheme.secondary
                        : Colors.transparent,
                  ),
                  child: isSelected
                      ? const Icon(
                          Icons.check,
                          color: LaconicTheme.onSecondary,
                          size: 16,
                        )
                      : null,
                ),
              ],
            ),
            const SizedBox(height: 24),
            Text(
              title,
              style: GoogleFonts.spaceGrotesk(
                fontSize: 20,
                fontWeight: FontWeight.w700,
                color: LaconicTheme.onSurface,
                letterSpacing: -0.01,
              ),
            ),
            const SizedBox(height: 12),
            Text(
              description,
              style: GoogleFonts.inter(
                fontSize: 14,
                color: LaconicTheme.onSurfaceVariant,
                height: 1.5,
              ),
            ),
            const SizedBox(height: 24),
            if (showProgressBar && isSelected) ...[
              Container(
                height: 4,
                width: double.infinity,
                color: LaconicTheme.surfaceContainerHighest,
                child: FractionallySizedBox(
                  alignment: Alignment.centerLeft,
                  widthFactor: 0.75,
                  child: Container(
                    decoration: const BoxDecoration(
                      gradient: LaconicTheme.secondaryGradient,
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 8),
            ],
            Text(
              'Complexity: $riskFactor',
              style: GoogleFonts.workSans(
                fontSize: 10,
                fontWeight: FontWeight.w700,
                color: isSelected
                    ? LaconicTheme.secondary
                    : LaconicTheme.outline,
                letterSpacing: 0.1,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSummaryItem(String label, String value) {
    return Container(
      padding: const EdgeInsets.all(16),
      color: LaconicTheme.surface,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: GoogleFonts.workSans(
              fontSize: 10,
              color: LaconicTheme.outline,
              letterSpacing: 0.1,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            value,
            style: GoogleFonts.spaceGrotesk(
              fontSize: 16,
              fontWeight: FontWeight.w700,
              color: LaconicTheme.onSurface,
            ),
          ),
        ],
      ),
    );
  }
}
