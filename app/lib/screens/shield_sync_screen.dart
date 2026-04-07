import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../theme.dart';

/// Shield Sync Screen - Health Data Integration
/// Based on equip_your_shield_sync design
class ShieldSyncScreen extends StatelessWidget {
  final VoidCallback? onComplete;

  const ShieldSyncScreen({super.key, this.onComplete});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: LaconicTheme.background,
      appBar: AppBar(
        backgroundColor: LaconicTheme.background,
        elevation: 0,
        title: Row(
          children: [
            const Icon(Icons.shield, color: LaconicTheme.primary),
            const SizedBox(width: 12),
            Text(
              'THE AGOGE',
              style: GoogleFonts.spaceGrotesk(
                fontSize: 24,
                fontWeight: FontWeight.w900,
                color: LaconicTheme.secondary,
                letterSpacing: -0.02,
              ),
            ),
          ],
        ),
      ),
      body: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header
            Text(
              'EQUIP YOUR',
              style: GoogleFonts.spaceGrotesk(
                fontSize: 48,
                fontWeight: FontWeight.w700,
                color: LaconicTheme.onSurface,
                letterSpacing: -0.02,
                height: 1,
              ),
            ),
            Text(
              'SHIELD',
              style: GoogleFonts.spaceGrotesk(
                fontSize: 48,
                fontWeight: FontWeight.w700,
                color: LaconicTheme.secondary,
                letterSpacing: -0.02,
                height: 1,
              ),
            ),
            const SizedBox(height: 16),
            Container(height: 4, width: 96, color: LaconicTheme.primary),
            const SizedBox(height: 24),
            Text(
              'Data is the foundation of discipline. Integrate your biometrics to synchronize HRV trends and sleep recovery protocols with the command center.',
              style: GoogleFonts.inter(
                fontSize: 16,
                color: LaconicTheme.onSurfaceVariant,
                height: 1.6,
              ),
            ),
            const SizedBox(height: 32),

            // Connectivity Options
            Row(
              children: [
                Expanded(
                  child: _buildSyncOption(
                    icon: Icons.favorite,
                    label: 'Apple Health',
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _buildSyncOption(
                    icon: Icons.watch,
                    label: 'Google Connect',
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _buildSyncOption(
                    icon: Icons.watch_outlined,
                    label: 'Garmin Connect',
                  ),
                ),
              ],
            ),
            const SizedBox(height: 32),

            // Requirement Protocol
            Container(
              padding: const EdgeInsets.all(20),
              decoration: const BoxDecoration(
                color: LaconicTheme.surfaceContainerLow,
                border: Border(
                  left: BorderSide(color: LaconicTheme.secondary, width: 4),
                ),
              ),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Icon(
                    Icons.info,
                    color: LaconicTheme.secondary,
                    size: 24,
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'REQUIREMENT PROTOCOL',
                          style: GoogleFonts.workSans(
                            fontSize: 12,
                            fontWeight: FontWeight.w700,
                            color: LaconicTheme.secondary,
                            letterSpacing: 0.1,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          'The Agoge requires read access to Heart Rate Variability and Sleep Duration to calculate your daily strain capacity.',
                          style: GoogleFonts.inter(
                            fontSize: 14,
                            color: LaconicTheme.onSurfaceVariant,
                            height: 1.5,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),

            const Spacer(),

            // Initialize Sync Button
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: onComplete,
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
                  'INITIALIZE SYNC',
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
                'Secure encrypted link via OAuth 2.0 protocol',
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

  Widget _buildSyncOption({required IconData icon, required String label}) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: LaconicTheme.surfaceContainer,
        border: Border.all(
          color: LaconicTheme.outlineVariant.withValues(alpha: 0.2),
        ),
      ),
      child: Column(
        children: [
          Icon(icon, color: LaconicTheme.onSurface, size: 40),
          const SizedBox(height: 16),
          Text(
            label,
            style: GoogleFonts.workSans(
              fontSize: 10,
              fontWeight: FontWeight.w700,
              color: LaconicTheme.onSurfaceVariant,
              letterSpacing: 0.1,
            ),
          ),
        ],
      ),
    );
  }
}
