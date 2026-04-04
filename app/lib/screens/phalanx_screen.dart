import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../theme.dart';
import '../providers/ingestion_provider.dart';
import '../providers/workout_provider.dart';
import '../models/fuel_log.dart';
import '../models/workout_protocol.dart';
import '../services/phalanx_ingestion_service.dart';
import '../services/dom_rl_engine.dart';

import 'workout_session_screen.dart';
import 'pre_battle_primer_screen.dart';

/// Phalanx Screen - Tactical Ingestion & Plan Management
/// Features: Workout import, verification interface, autopilot toggle
class PhalanxScreen extends StatefulWidget {
  const PhalanxScreen({super.key});

  @override
  State<PhalanxScreen> createState() => _PhalanxScreenState();
}

class _PhalanxScreenState extends State<PhalanxScreen> {
  final TextEditingController _controller = TextEditingController();
  final PhalanxIngestionService _ingestionService = PhalanxIngestionService();
  // final FirebaseSyncService _firebase = FirebaseSyncService(); // Removed
  final DomRlEngine _domRlEngine = DomRlEngine();

  bool _autopilotMode = true;
  List<Map<String, dynamic>> _importedPlans = [];
  IngestionResult? _pendingVerification;
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _loadImportedPlans();
  }

  Future<void> _loadImportedPlans() async {
    // final plans = await _firebase.getImportedPlans(); // TODO: Implement with Supabase
    final plans = <Map<String, dynamic>>[]; // Placeholder
    setState(() => _importedPlans = plans);
  }

  Future<void> _importFromText() async {
    final text = await showDialog<String>(
      context: context,
      builder: (context) => const _ImportTextDialog(),
    );

    if (text != null && text.isNotEmpty) {
      setState(() => _isLoading = true);
      final result = _ingestionService.parseWorkoutText(text);
      setState(() {
        _pendingVerification = result;
        _isLoading = false;
      });
    }
  }

  void _confirmImport(WorkoutProtocol protocol) async {
    final planId = 'plan_${DateTime.now().millisecondsSinceEpoch}';
    // await _firebase.saveImportedPlan(planId, { // TODO: Implement with Supabase
    final planData = {
      'id': planId,
      'protocol': protocol,
      'autopilot': _autopilotMode,
    };
    // });

    setState(() => _pendingVerification = null);
    await _loadImportedPlans();

    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text("PLAN IMPORTED SUCCESSFULLY"),
        backgroundColor: LaconicTheme.spartanBronze,
      ),
    );
  }

  void _startImportedPlan(Map<String, dynamic> plan) async {
    final protocol = plan['protocol'] as WorkoutProtocol?;
    final useAutopilot = plan['autopilot'] as bool? ?? _autopilotMode;

    if (protocol == null) return;

    WorkoutProtocol finalProtocol = protocol;

    if (useAutopilot) {
      // final microCycle = await _firebase.buildMicroCycle(); // TODO: Implement with Supabase
      final microCycle = <Map<String, dynamic>>[]; // Placeholder
      final result = _domRlEngine.optimize(microCycle, protocol);
      finalProtocol = result.optimizedProtocol;
    }

    if (!mounted) return;
    final workoutProvider = Provider.of<WorkoutProvider>(
      context,
      listen: false,
    );

    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => PreBattlePrimerScreen(
          onAcknowledged: () {
            workoutProvider.startWorkout(
              finalProtocol,
              80,
            ); // Default readiness score
            Navigator.pushReplacement(
              context,
              MaterialPageRoute(
                builder: (context) => const WorkoutSessionScreen(),
              ),
            );
          },
        ),
      ),
    );
  }

  void _submitLog(IngestionProvider provider) {
    if (_controller.text.isNotEmpty) {
      final success = provider.logFuel(_controller.text);
      if (success) {
        _controller.clear();
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text("INGESTION LOGGED"),
            backgroundColor: LaconicTheme.spartanBronze,
            duration: Duration(seconds: 1),
          ),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text("INVALID COMMAND"),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final ingestionProvider = Provider.of<IngestionProvider>(context);
    final log = ingestionProvider.todayLog;

    return Scaffold(
      appBar: AppBar(
        title: const Text("P H A L A N X"),
        actions: [
          IconButton(
            icon: const Icon(Icons.add, color: LaconicTheme.spartanBronze),
            onPressed: _importFromText,
            tooltip: 'Import Workout',
          ),
        ],
      ),
      body: _isLoading
          ? const Center(
              child: CircularProgressIndicator(
                color: LaconicTheme.spartanBronze,
              ),
            )
          : _pendingVerification != null
          ? _buildVerificationInterface()
          : SingleChildScrollView(
              padding: const EdgeInsets.all(24.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildPhalanxToggle(),
                  const SizedBox(height: 30),
                  _buildImportedPlansSection(),
                  const SizedBox(height: 30),
                  const Text(
                    "TACTICAL INGESTION",
                    style: TextStyle(
                      color: LaconicTheme.spartanBronze,
                      fontSize: 12,
                      letterSpacing: 2.0,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 20),
                  _buildMacroSummary(log),
                  const SizedBox(height: 30),
                  const Text(
                    "COMMAND INPUT",
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 16,
                      letterSpacing: 1.0,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: _controller,
                    style: const TextStyle(
                      color: Colors.white,
                      fontFamily: "Courier",
                    ),
                    decoration: InputDecoration(
                      hintText: "e.g., 300g chicken or 2e",
                      hintStyle: TextStyle(
                        color: Colors.grey.withValues(alpha: 0.5),
                      ),
                      filled: true,
                      fillColor: LaconicTheme.ironGray.withValues(alpha: 0.1),
                      border: const OutlineInputBorder(
                        borderSide: BorderSide.none,
                      ),
                      suffixIcon: IconButton(
                        icon: const Icon(
                          Icons.send,
                          color: LaconicTheme.spartanBronze,
                        ),
                        onPressed: () => _submitLog(ingestionProvider),
                      ),
                    ),
                    onSubmitted: (_) => _submitLog(ingestionProvider),
                  ),
                  const SizedBox(height: 30),
                  const Text(
                    "RECENT LOGS",
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 14,
                      letterSpacing: 1.0,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 12),
                  if (ingestionProvider.todayEntries.isEmpty)
                    const Center(
                      child: Padding(
                        padding: EdgeInsets.symmetric(vertical: 40),
                        child: Text(
                          "NO LOGS DETECTED.",
                          style: TextStyle(
                            color: Colors.grey,
                            fontSize: 10,
                            letterSpacing: 2.0,
                          ),
                        ),
                      ),
                    ),
                  ...ingestionProvider.todayEntries.map(
                    (entry) => _buildEntryTile(entry, ingestionProvider),
                  ),
                ],
              ),
            ),
    );
  }

  Widget _buildPhalanxToggle() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: LaconicTheme.ironGray.withValues(alpha: 0.1),
        border: Border.all(
          color: LaconicTheme.spartanBronze.withValues(alpha: 0.3),
        ),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'PHALANX TOGGLE',
                style: TextStyle(
                  color: LaconicTheme.spartanBronze,
                  fontSize: 12,
                  letterSpacing: 2.0,
                  fontWeight: FontWeight.bold,
                ),
              ),
              Switch(
                value: _autopilotMode,
                activeThumbColor: LaconicTheme.spartanBronze,
                onChanged: (val) => setState(() => _autopilotMode = val),
              ),
            ],
          ),
          Text(
            _autopilotMode
                ? 'AUTOPILOT (AI-OPTIMIZED)'
                : 'LOCK SHIELDS (STRICT)',
            style: const TextStyle(
              color: Colors.white,
              fontSize: 14,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            _autopilotMode
                ? 'The Agoge AI will optimize imported plans based on your recovery metrics, joint stress, and readiness.'
                : 'Execute imported plans exactly as written. No AI modifications. Lock shields with your baseline.',
            style: const TextStyle(
              color: Colors.grey,
              fontSize: 12,
              height: 1.4,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildImportedPlansSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const Text(
              "IMPORTED PLANS",
              style: TextStyle(
                color: LaconicTheme.spartanBronze,
                fontSize: 12,
                letterSpacing: 2.0,
                fontWeight: FontWeight.bold,
              ),
            ),
            IconButton(
              icon: const Icon(
                Icons.add,
                color: LaconicTheme.spartanBronze,
                size: 20,
              ),
              onPressed: _importFromText,
              tooltip: 'Import from text',
            ),
          ],
        ),
        const SizedBox(height: 12),
        if (_importedPlans.isEmpty)
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: LaconicTheme.ironGray.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(4),
            ),
            child: const Text(
              "NO PLANS IMPORTED.\nTap + to import from text, image, or CSV.",
              textAlign: TextAlign.center,
              style: TextStyle(
                color: Colors.grey,
                fontSize: 12,
                letterSpacing: 1.0,
              ),
            ),
          )
        else
          ..._importedPlans.map((plan) => _buildPlanCard(plan)),
      ],
    );
  }

  Widget _buildPlanCard(Map<String, dynamic> plan) {
    final protocol = plan['protocol'] as WorkoutProtocol?;
    final isAutopilot = plan['autopilot'] as bool? ?? true;

    if (protocol == null) return const SizedBox.shrink();

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: LaconicTheme.ironGray.withValues(alpha: 0.1),
        border: Border.all(color: LaconicTheme.ironGray.withValues(alpha: 0.4)),
        borderRadius: BorderRadius.circular(4),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Text(
                  protocol.title,
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                    fontSize: 14,
                  ),
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: isAutopilot
                      ? LaconicTheme.spartanBronze.withValues(alpha: 0.2)
                      : Colors.grey.withValues(alpha: 0.2),
                  borderRadius: BorderRadius.circular(4),
                ),
                child: Text(
                  isAutopilot ? 'AI' : 'STRICT',
                  style: TextStyle(
                    color: isAutopilot
                        ? LaconicTheme.spartanBronze
                        : Colors.grey,
                    fontSize: 10,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            '${protocol.entries.length} exercises • ${protocol.estimatedDurationMinutes} min',
            style: const TextStyle(color: Colors.grey, fontSize: 12),
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: ElevatedButton(
                  onPressed: () => _startImportedPlan(plan),
                  style: ElevatedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 12),
                  ),
                  child: const Text(
                    'EXECUTE',
                    style: TextStyle(letterSpacing: 2.0),
                  ),
                ),
              ),
              const SizedBox(width: 8),
              IconButton(
                icon: const Icon(Icons.delete, color: Colors.grey, size: 20),
                onPressed: () async {
                  // await _firebase.deleteImportedPlan(plan['id'] as String); // TODO: Implement with Supabase
                  await _loadImportedPlans();
                },
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildVerificationInterface() {
    final result = _pendingVerification!;

    if (!result.success || result.protocol == null) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.error, color: Colors.red, size: 48),
            const SizedBox(height: 16),
            Text(
              result.errorMessage ?? 'Import failed',
              style: const TextStyle(color: Colors.white),
            ),
            const SizedBox(height: 24),
            ElevatedButton(
              onPressed: () => setState(() => _pendingVerification = null),
              child: const Text('BACK'),
            ),
          ],
        ),
      );
    }

    final protocol = result.protocol!;
    final warnings = result.warnings ?? [];

    return SingleChildScrollView(
      padding: const EdgeInsets.all(24.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              IconButton(
                icon: const Icon(Icons.arrow_back, color: Colors.grey),
                onPressed: () => setState(() => _pendingVerification = null),
              ),
              const Expanded(
                child: Text(
                  'VERIFY IMPORT',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: LaconicTheme.spartanBronze,
                    fontSize: 14,
                    letterSpacing: 2.0,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              const SizedBox(width: 48),
            ],
          ),
          const SizedBox(height: 20),

          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: (result.confidence ?? 0) > 0.7
                  ? LaconicTheme.spartanBronze.withValues(alpha: 0.1)
                  : Colors.orange.withValues(alpha: 0.1),
              border: Border.all(
                color: (result.confidence ?? 0) > 0.7
                    ? LaconicTheme.spartanBronze.withValues(alpha: 0.3)
                    : Colors.orange.withValues(alpha: 0.3),
              ),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Column(
              children: [
                Text(
                  'CONFIDENCE: ${((result.confidence ?? 0) * 100).toStringAsFixed(0)}%',
                  style: TextStyle(
                    color: (result.confidence ?? 0) > 0.7
                        ? LaconicTheme.spartanBronze
                        : Colors.orange,
                    fontWeight: FontWeight.bold,
                    letterSpacing: 1.0,
                  ),
                ),
                if (warnings.isNotEmpty) ...[
                  const SizedBox(height: 8),
                  ...warnings.map(
                    (w) => Text(
                      '• $w',
                      style: const TextStyle(color: Colors.grey, fontSize: 11),
                    ),
                  ),
                ],
              ],
            ),
          ),
          const SizedBox(height: 24),

          Text(
            protocol.title,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            protocol.subtitle,
            style: const TextStyle(color: Colors.grey, fontSize: 12),
          ),
          const SizedBox(height: 20),

          const Text(
            'EXERCISES:',
            style: TextStyle(
              color: LaconicTheme.spartanBronze,
              fontSize: 12,
              letterSpacing: 2.0,
            ),
          ),
          const SizedBox(height: 12),
          ...protocol.entries.map(
            (entry) => Container(
              margin: const EdgeInsets.only(bottom: 8),
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: LaconicTheme.ironGray.withValues(alpha: 0.1),
                border: Border.all(
                  color: LaconicTheme.ironGray.withValues(alpha: 0.3),
                ),
                borderRadius: BorderRadius.circular(4),
              ),
              child: Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          entry.exercise.name,
                          style: const TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                            fontSize: 14,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          '${entry.sets} sets × ${entry.reps > 0 ? entry.reps : 'MAX'} reps @ RPE ${entry.intensityRpe.toStringAsFixed(1)}',
                          style: const TextStyle(
                            color: Colors.grey,
                            fontSize: 12,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),

          const SizedBox(height: 30),
          _buildPhalanxToggle(),
          const SizedBox(height: 30),

          Row(
            children: [
              Expanded(
                child: ElevatedButton(
                  onPressed: () => _confirmImport(protocol),
                  style: ElevatedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 16),
                  ),
                  child: const Text(
                    'CONFIRM IMPORT',
                    style: TextStyle(letterSpacing: 2.0),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Center(
            child: TextButton(
              onPressed: () => setState(() => _pendingVerification = null),
              child: const Text('CANCEL', style: TextStyle(color: Colors.grey)),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMacroSummary(FuelLog log) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: LaconicTheme.ironGray.withValues(alpha: 0.2),
        border: Border.all(
          color: LaconicTheme.spartanBronze.withValues(alpha: 0.3),
        ),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(
        children: [
          _macroRow(
            "PROTEIN",
            log.totalProtein,
            FuelLog.targetProtein,
            LaconicTheme.spartanBronze,
          ),
          const SizedBox(height: 12),
          _macroRow(
            "CARBS",
            log.totalCarbs,
            FuelLog.targetCarbs,
            Colors.blueGrey,
          ),
          const SizedBox(height: 12),
          _macroRow(
            "FAT",
            log.totalFat,
            FuelLog.targetFat,
            Colors.orangeAccent,
          ),
          const Divider(height: 32, color: LaconicTheme.ironGray),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                "TOTAL CALORIES",
                style: TextStyle(color: Colors.grey, fontSize: 12),
              ),
              Text(
                "${log.totalCalories} / ${FuelLog.targetCalories} kcal",
                style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _macroRow(String label, double current, double target, Color color) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              label,
              style: const TextStyle(
                color: Colors.grey,
                fontSize: 10,
                letterSpacing: 1.0,
              ),
            ),
            Text(
              "${current.toInt()}g / ${target.toInt()}g",
              style: const TextStyle(
                color: Colors.white,
                fontSize: 10,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
        const SizedBox(height: 4),
        LinearProgressIndicator(
          value: (current / target).clamp(0.0, 1.0),
          backgroundColor: Colors.black,
          color: color,
          minHeight: 4,
        ),
      ],
    );
  }

  Widget _buildEntryTile(dynamic entry, IngestionProvider provider) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8.0),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        decoration: BoxDecoration(
          color: LaconicTheme.ironGray.withValues(alpha: 0.1),
          border: Border.all(
            color: LaconicTheme.ironGray.withValues(alpha: 0.4),
          ),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  entry.itemName,
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                    fontSize: 12,
                  ),
                ),
                Text(
                  "${entry.calories} kcal | P: ${entry.protein.toInt()}g",
                  style: const TextStyle(color: Colors.grey, fontSize: 10),
                ),
              ],
            ),
            IconButton(
              icon: const Icon(Icons.close, size: 16, color: Colors.grey),
              onPressed: () => provider.removeEntry(entry.id),
            ),
          ],
        ),
      ),
    );
  }
}

class _ImportTextDialog extends StatefulWidget {
  const _ImportTextDialog();

  @override
  State<_ImportTextDialog> createState() => _ImportTextDialogState();
}

class _ImportTextDialogState extends State<_ImportTextDialog> {
  final _controller = TextEditingController();

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      backgroundColor: LaconicTheme.deepBlack,
      title: const Text(
        'IMPORT WORKOUT',
        style: TextStyle(color: Colors.white, fontSize: 16, letterSpacing: 2.0),
      ),
      content: SizedBox(
        width: double.maxFinite,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Paste workout text:',
              style: TextStyle(color: Colors.grey, fontSize: 12),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _controller,
              maxLines: 8,
              style: const TextStyle(
                color: Colors.white,
                fontFamily: 'Courier',
                fontSize: 12,
              ),
              decoration: InputDecoration(
                hintText: '''Day 1: Push
3x10 Bench Press @8 RPE
4x8 Overhead Press @7 RPE''',
                hintStyle: TextStyle(color: Colors.grey.withValues(alpha: 0.5)),
                filled: true,
                fillColor: LaconicTheme.ironGray.withValues(alpha: 0.2),
                border: const OutlineInputBorder(borderSide: BorderSide.none),
              ),
            ),
            const SizedBox(height: 12),
            const Text(
              'Supports: CSV, shorthand (3x10), full text',
              style: TextStyle(color: Colors.grey, fontSize: 10),
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('CANCEL', style: TextStyle(color: Colors.grey)),
        ),
        ElevatedButton(
          onPressed: () => Navigator.pop(context, _controller.text),
          child: const Text('IMPORT', style: TextStyle(letterSpacing: 2.0)),
        ),
      ],
    );
  }
}
