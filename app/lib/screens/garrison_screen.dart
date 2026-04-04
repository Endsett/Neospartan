import 'package:flutter/material.dart';
import '../theme.dart';
import '../services/armor_analytics_service.dart';
import '../models/armor_analytics.dart';

class GarrisonScreen extends StatefulWidget {
  const GarrisonScreen({super.key});

  @override
  State<GarrisonScreen> createState() => _GarrisonScreenState();
}

class _GarrisonScreenState extends State<GarrisonScreen> {
  final ArmorAnalyticsService _armorService = ArmorAnalyticsService();
  final FirebaseSyncService _firebase = FirebaseSyncService();

  Map<String, dynamic> _data = {
    'hrv': 0.0,
    'sleep': 0.0,
    'rhr': 0.0,
    'score': 0,
  };
  bool _isLoading = true;
  ArmorAnalyticsResult? _armorResult;

  @override
  void initState() {
    super.initState();
    _refreshData();
  }

  Future<void> _refreshData() async {
    setState(() => _isLoading = true);
    // TODO: Implement health service
    // await _healthService.requestPermissions();
    // final data = await _healthService.fetchReadinessData();

    // Use mock data for now
    final data = {'hrv': 65.0, 'sleep': 7.5, 'rhr': 55, 'score': 85};

    // Load Armor Analytics
    final microCycle = await _firebase.buildMicroCycle();
    final armorResult = _armorService.analyze(microCycle);

    if (mounted) {
      setState(() {
        _data = data;
        _armorResult = armorResult;
        _isLoading = false;
      });
    }
  }

  String _getReadinessLabel(int score) {
    if (score >= 90) return "OPTIMAL";
    if (score >= 80) return "ELITE";
    if (score >= 60) return "COMBAT READY";
    if (score >= 40) return "FATIGUED";
    return "RECOVERY REQUIRED";
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("G A R R I S O N"),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh, color: LaconicTheme.spartanBronze),
            onPressed: _refreshData,
          ),
        ],
      ),
      body: _isLoading
          ? const Center(
              child: CircularProgressIndicator(
                color: LaconicTheme.spartanBronze,
              ),
            )
          : RefreshIndicator(
              onRefresh: _refreshData,
              color: LaconicTheme.spartanBronze,
              child: SingleChildScrollView(
                physics: const AlwaysScrollableScrollPhysics(),
                child: Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const SizedBox(height: 20),
                      const Text(
                        "SHIELD READINESS SCORE",
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 14,
                          letterSpacing: 4.0,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 40),
                      _buildReadinessCircle(),
                      const SizedBox(height: 40),
                      _readinessMetric(
                        "HEART RATE VARIABILITY",
                        "${_data['hrv'].toStringAsFixed(1)}ms",
                        Icons.favorite,
                      ),
                      _readinessMetric(
                        "SLEEP ARCHITECTURE",
                        "${_data['sleep'].toStringAsFixed(1)}h",
                        Icons.nightlight_round,
                      ),
                      _readinessMetric(
                        "RESTING HEART RATE",
                        "${_data['rhr'].toStringAsFixed(0)}bpm",
                        Icons.speed,
                      ),
                      const SizedBox(height: 30),
                      _buildArmorAnalyticsSection(),
                      const SizedBox(height: 40),
                      _buildSimulationToggle(),
                    ],
                  ),
                ),
              ),
            ),
    );
  }

  Widget _buildReadinessCircle() {
    return Stack(
      alignment: Alignment.center,
      children: [
        SizedBox(
          width: 220,
          height: 220,
          child: CircularProgressIndicator(
            value: _data['score'] / 100,
            strokeWidth: 16,
            backgroundColor: LaconicTheme.ironGray.withValues(alpha: 0.3),
            color: LaconicTheme.spartanBronze,
          ),
        ),
        Column(
          children: [
            Text(
              "${_data['score']}",
              style: const TextStyle(
                fontSize: 64,
                fontWeight: FontWeight.w900,
                color: LaconicTheme.spartanBronze,
                letterSpacing: -2.0,
              ),
            ),
            Text(
              _getReadinessLabel(_data['score']),
              style: const TextStyle(
                fontSize: 12,
                letterSpacing: 2.0,
                color: Colors.white70,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildArmorAnalyticsSection() {
    if (_armorResult == null) return const SizedBox.shrink();

    final riskColor = _armorResult!.hasCriticalRisk
        ? Colors.red
        : _armorResult!.shouldModifyTraining
        ? Colors.orange
        : LaconicTheme.spartanBronze;

    return Container(
      width: double.infinity,
      margin: const EdgeInsets.symmetric(horizontal: 24),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: LaconicTheme.ironGray.withValues(alpha: 0.1),
        border: Border.all(color: riskColor.withValues(alpha: 0.3)),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.shield, color: riskColor, size: 20),
              const SizedBox(width: 12),
              Text(
                'ARMOR ANALYTICS',
                style: TextStyle(
                  color: riskColor,
                  fontSize: 12,
                  letterSpacing: 2.0,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Text(
            _armorResult!.summary,
            style: const TextStyle(color: Colors.white, fontSize: 14),
          ),
          if (_armorResult!.riskFlags.isNotEmpty) ...[
            const SizedBox(height: 16),
            const Text(
              'RISK FLAGS:',
              style: TextStyle(
                color: Colors.grey,
                fontSize: 10,
                letterSpacing: 1.0,
              ),
            ),
            const SizedBox(height: 8),
            ..._armorResult!.riskFlags.map(
              (flag) => Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: Row(
                  children: [
                    Container(
                      width: 8,
                      height: 8,
                      decoration: BoxDecoration(
                        color: flag.riskLevel == JointRiskLevel.critical
                            ? Colors.red
                            : flag.riskLevel == JointRiskLevel.high
                            ? Colors.orange
                            : Colors.yellow,
                        shape: BoxShape.circle,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        '${flag.joint.toUpperCase()}: ${flag.message}',
                        style: const TextStyle(
                          color: Colors.grey,
                          fontSize: 11,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
          if (_armorResult!.safeMovements.isNotEmpty &&
              _armorResult!.shouldModifyTraining) ...[
            const SizedBox(height: 16),
            const Text(
              'RECOMMENDED MOVEMENTS:',
              style: TextStyle(
                color: Colors.grey,
                fontSize: 10,
                letterSpacing: 1.0,
              ),
            ),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: _armorResult!.safeMovements
                  .take(4)
                  .map(
                    (exercise) => Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 6,
                      ),
                      decoration: BoxDecoration(
                        color: LaconicTheme.spartanBronze.withValues(
                          alpha: 0.2,
                        ),
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: Text(
                        exercise.name,
                        style: const TextStyle(
                          color: LaconicTheme.spartanBronze,
                          fontSize: 10,
                        ),
                      ),
                    ),
                  )
                  .toList(),
            ),
          ],
        ],
      ),
    );
  }

  Widget _readinessMetric(String label, String value, IconData icon) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 40, vertical: 12),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: LaconicTheme.ironGray.withValues(alpha: 0.2),
          border: Border.all(
            color: LaconicTheme.ironGray.withValues(alpha: 0.5),
          ),
          borderRadius: BorderRadius.circular(4),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Row(
              children: [
                Icon(icon, color: LaconicTheme.spartanBronze, size: 20),
                const SizedBox(width: 16),
                Text(
                  label,
                  style: const TextStyle(
                    color: Colors.grey,
                    fontSize: 12,
                    letterSpacing: 1.0,
                  ),
                ),
              ],
            ),
            Text(
              value,
              style: const TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.bold,
                fontSize: 14,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSimulationToggle() {
    return Padding(
      padding: const EdgeInsets.all(20.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Text(
            "SIMULATION MODE",
            style: TextStyle(
              color: Colors.grey,
              fontSize: 10,
              letterSpacing: 2.0,
            ),
          ),
          const SizedBox(width: 10),
          Switch(
            value: false, // TODO: Implement simulation toggle
            activeThumbColor: LaconicTheme.spartanBronze,
            onChanged: (val) {
              setState(() {
                // TODO: Implement simulation toggle
              });
            },
          ),
        ],
      ),
    );
  }
}
