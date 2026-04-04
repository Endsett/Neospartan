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
            const Icon(Icons.psychology_outlined, color: LaconicTheme.spartanBronze, size: 64),
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
            _buildActionItem("PRE-BATTLE PRIMER", "5 MIN MEDITATION", Icons.timer),
            const SizedBox(height: 20),
            _buildActionItem("MEMENTO MORI", "REFLECT ON TRANSITION", Icons.hourglass_empty),
            const SizedBox(height: 20),
            _buildActionItem("VOLUNTARY DISCOMFORT", "DAILY CHALLENGE", Icons.ac_unit),
          ],
        ),
      ),
    );
  }

  Widget _buildActionItem(String title, String subtitle, IconData icon) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: LaconicTheme.ironGray.withValues(alpha: 0.1),
        border: Border.all(color: LaconicTheme.ironGray.withValues(alpha: 0.3)),
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
          const Icon(Icons.chevron_right, color: LaconicTheme.spartanBronze, size: 16),
        ],
      ),
    );
  }
}
