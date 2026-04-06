import 'package:flutter/material.dart';
import '../theme.dart';

class StoicScreen extends StatelessWidget {
  const StoicScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("S T O I C")),
      body: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 40),
        child: Column(
          children: [
            const Icon(
              Icons.psychology_outlined,
              color: LaconicTheme.spartanBronze,
              size: 64,
            ),
            const SizedBox(height: 48),
            const Text(
              "\"WE SUFFER MORE OFTEN IN IMAGINATION THAN IN REALITY\"",
              textAlign: TextAlign.center,
              style: TextStyle(
                color: Colors.white,
                fontSize: 22,
                fontWeight: FontWeight.w900,
                letterSpacing: 1.0,
                height: 1.4,
              ),
            ),
            const SizedBox(height: 16),
            const Text(
              "— SENECA THE YOUNGER",
              style: TextStyle(
                color: LaconicTheme.spartanBronze,
                fontSize: 12,
                letterSpacing: 2.0,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 64),
            _buildActionItem(
              context,
              "PRE-BATTLE PRIMER",
              "5 MIN MEDITATION",
              Icons.timer,
              onTap: () => _showComingSoon(context, "Pre-Battle Primer"),
            ),
            const SizedBox(height: 20),
            _buildActionItem(
              context,
              "MEMENTO MORI",
              "REFLECT ON TRANSITION",
              Icons.hourglass_empty,
              onTap: () => _showComingSoon(context, "Memento Mori"),
            ),
            const SizedBox(height: 20),
            _buildActionItem(
              context,
              "VOLUNTARY DISCOMFORT",
              "DAILY CHALLENGE",
              Icons.ac_unit,
              onTap: () => _showComingSoon(context, "Voluntary Discomfort"),
            ),
          ],
        ),
      ),
    );
  }

  void _showComingSoon(BuildContext context, String feature) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: LaconicTheme.deepBlack,
        title: Text(
          feature.toUpperCase(),
          style: const TextStyle(color: LaconicTheme.spartanBronze),
        ),
        content: const Text(
          'This feature is coming soon.\n\n"The obstacle is the way."',
          style: TextStyle(color: Colors.white),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text(
              'UNDERSTOOD',
              style: TextStyle(color: LaconicTheme.spartanBronze),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildActionItem(
    BuildContext context,
    String title,
    String subtitle,
    IconData icon, {
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: LaconicTheme.ironGray.withValues(alpha: 0.1),
          border: Border.all(
            color: LaconicTheme.ironGray.withValues(alpha: 0.3),
          ),
        ),
        child: Row(
          children: [
            Icon(icon, color: Colors.grey, size: 24),
            const SizedBox(width: 20),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                    letterSpacing: 1.0,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  subtitle,
                  style: const TextStyle(color: Colors.grey, fontSize: 10),
                ),
              ],
            ),
            const Spacer(),
            const Icon(
              Icons.chevron_right,
              color: LaconicTheme.spartanBronze,
              size: 16,
            ),
          ],
        ),
      ),
    );
  }
}
