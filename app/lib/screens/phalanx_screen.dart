// ignore_for_file: unused_field, unused_element, unused_local_variable
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import '../theme.dart';
import '../providers/ingestion_provider.dart';
import '../providers/workout_provider.dart';
import '../providers/auth_provider.dart';
import '../models/workout_protocol.dart';
import '../models/workout_tracking.dart';
import '../services/phalanx_ingestion_service.dart';
import '../services/dom_rl_engine.dart';
import '../services/supabase_database_service.dart';
import '../repositories/imported_plan_repository.dart';
import 'workout_session_screen.dart';
import 'pre_battle_primer_screen.dart';

/// The Armory - Routines & Protocol Management
/// Based on the_armory_routines design
class PhalanxScreen extends StatefulWidget {
  const PhalanxScreen({super.key});

  @override
  State<PhalanxScreen> createState() => _PhalanxScreenState();
}

class _PhalanxScreenState extends State<PhalanxScreen> {
  final TextEditingController _controller = TextEditingController();
  final PhalanxIngestionService _ingestionService = PhalanxIngestionService();
  final DomRlEngine _domRlEngine = DomRlEngine();
  final ImportedPlanRepository _planRepo = ImportedPlanRepository();
  final SupabaseDatabaseService _database = SupabaseDatabaseService();

  bool _autopilotMode = true;
  List<ImportedPlan> _importedPlans = [];
  IngestionResult? _pendingVerification;
  bool _isLoading = false;
  String? _userId;
  List<Map<String, dynamic>> _workoutCalendar = [];

  @override
  void initState() {
    super.initState();
    _userId = Provider.of<AuthProvider>(context, listen: false).userId;
    _loadImportedPlans();
    _loadWorkoutCalendar();
  }

  Future<void> _loadImportedPlans() async {
    if (_userId == null) return;

    setState(() => _isLoading = true);
    try {
      final plans = await _planRepo.getUserPlans(_userId!);
      setState(() {
        _importedPlans = plans;
        _isLoading = false;
      });
    } catch (e) {
      debugPrint('Error loading imported plans: $e');
      setState(() => _isLoading = false);
    }
  }

  Future<void> _loadWorkoutCalendar() async {
    if (_userId == null) return;

    try {
      // Get the current week's calendar
      final now = DateTime.now();
      final weekStart = now.subtract(Duration(days: now.weekday - 1));
      final calendar = await _database.getWorkoutCalendarForWeek(weekStart);
      setState(() => _workoutCalendar = calendar);
    } catch (e) {
      debugPrint('Error loading workout calendar: $e');
    }
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
    if (_userId == null) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('User not authenticated')));
      return;
    }

    final plan = ImportedPlan(
      id: 'plan_${DateTime.now().millisecondsSinceEpoch}',
      userId: _userId!,
      planName: protocol.title,
      description: protocol.subtitle,
      protocol: protocol,
      autopilotEnabled: _autopilotMode,
      source: 'text_import',
    );

    setState(() => _isLoading = true);

    try {
      final success = await _planRepo.savePlan(plan);

      if (success) {
        setState(() => _pendingVerification = null);
        await _loadImportedPlans();

        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              "PLAN IMPORTED SUCCESSFULLY",
              style: GoogleFonts.spaceGrotesk(fontWeight: FontWeight.w700),
            ),
            backgroundColor: LaconicTheme.secondary,
          ),
        );
      } else {
        throw Exception('Failed to save plan');
      }
    } catch (e) {
      debugPrint('Error saving imported plan: $e');
      if (mounted) {
        setState(() => _isLoading = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to import plan: $e'),
            backgroundColor: LaconicTheme.error,
          ),
        );
      }
    }
  }

  void _startImportedPlan(ImportedPlan plan) async {
    final protocol = plan.protocol;
    final useAutopilot = plan.autopilotEnabled || _autopilotMode;

    WorkoutProtocol finalProtocol = protocol;

    if (useAutopilot) {
      final microCycle = MicroCycle(
        days: [],
        startDate: DateTime.now(),
        endDate: DateTime.now().add(const Duration(days: 7)),
      );
      final result = _domRlEngine.optimize(microCycle, protocol);
      finalProtocol = result.optimizedProtocol;
    }

    if (!mounted) return;
    final workoutProvider = Provider.of<WorkoutProvider>(
      context,
      listen: false,
    );
    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    final userProfile = authProvider.userProfile;

    if (userProfile == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please complete your profile first')),
      );
      return;
    }

    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => PreBattlePrimerScreen(
          userProfile: userProfile,
          readinessScore: 80,
          onWorkoutLoaded: (protocol, readinessScore) {
            workoutProvider.startWorkout(protocol, readinessScore);
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

  @override
  Widget build(BuildContext context) {
    final ingestionProvider = Provider.of<IngestionProvider>(context);

    return Scaffold(
      backgroundColor: LaconicTheme.background,
      appBar: AppBar(
        backgroundColor: LaconicTheme.background,
        elevation: 0,
        title: Row(
          children: [
            const Icon(Icons.fitness_center, color: LaconicTheme.secondary),
            const SizedBox(width: 12),
            Text(
              'THE ARMORY',
              style: GoogleFonts.spaceGrotesk(
                fontSize: 24,
                fontWeight: FontWeight.w900,
                color: LaconicTheme.secondary,
                letterSpacing: -0.02,
              ),
            ),
          ],
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.add, color: LaconicTheme.secondary),
            onPressed: _importFromText,
            tooltip: 'Import Workout',
          ),
        ],
      ),
      body: _isLoading
          ? const Center(
              child: CircularProgressIndicator(color: LaconicTheme.secondary),
            )
          : _pendingVerification != null
          ? _buildVerificationInterface()
          : SingleChildScrollView(
              padding: const EdgeInsets.all(24.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Header
                  Text(
                    'Routine Management',
                    style: GoogleFonts.workSans(
                      fontSize: 12,
                      fontWeight: FontWeight.w700,
                      color: LaconicTheme.secondary,
                      letterSpacing: 0.2,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Macro Cycle',
                    style: GoogleFonts.spaceGrotesk(
                      fontSize: 48,
                      fontWeight: FontWeight.w900,
                      color: LaconicTheme.onSurface,
                      letterSpacing: -0.04,
                      height: 1,
                    ),
                  ),
                  Text(
                    'Overview',
                    style: GoogleFonts.spaceGrotesk(
                      fontSize: 48,
                      fontWeight: FontWeight.w900,
                      color: LaconicTheme.primary,
                      letterSpacing: -0.04,
                      height: 1,
                    ),
                  ),
                  const SizedBox(height: 32),

                  // Weekly Calendar Grid
                  _buildWeeklyCalendar(),
                  const SizedBox(height: 32),

                  // Tactical Ingestion Cards
                  _buildTacticalIngestionSection(),
                  const SizedBox(height: 32),

                  // Protocol History
                  _buildProtocolHistorySection(),
                  const SizedBox(height: 32),

                  // Phalanx Toggle
                  _buildPhalanxToggle(),
                  const SizedBox(height: 32),
                ],
              ),
            ),
    );
  }

  Widget _buildWeeklyCalendar() {
    final days = ['M', 'T', 'W', 'T', 'F', 'S', 'S'];
    final weekDays = ['MON', 'TUE', 'WED', 'THU', 'FRI', 'SAT', 'SUN'];
    final now = DateTime.now();
    final todayIndex = now.weekday - 1; // 0-6

    // Calculate week status from workout calendar data
    List<bool> hasWorkout = List.filled(7, false);
    List<bool> isCompleted = List.filled(7, false);

    for (final entry in _workoutCalendar) {
      final entryDate = DateTime.tryParse(entry['date']?.toString() ?? '');
      if (entryDate != null) {
        final diff = entryDate
            .difference(now.subtract(Duration(days: todayIndex)))
            .inDays;
        if (diff >= 0 && diff < 7) {
          hasWorkout[diff] = true;
          isCompleted[diff] =
              entry['completed'] == true || entry['status'] == 'completed';
        }
      }
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              'Current Macro-Cycle',
              style: GoogleFonts.spaceGrotesk(
                fontSize: 16,
                fontWeight: FontWeight.w700,
                color: LaconicTheme.onSurface,
              ),
            ),
            Text(
              'Week 1 of 4',
              style: GoogleFonts.workSans(
                fontSize: 10,
                color: LaconicTheme.secondary,
                letterSpacing: 0.1,
              ),
            ),
          ],
        ),
        const SizedBox(height: 16),
        Container(
          decoration: const BoxDecoration(
            color: LaconicTheme.surfaceContainerLow,
          ),
          child: Row(
            children: List.generate(7, (index) {
              final isToday = index == todayIndex;
              final hasWorkoutToday = hasWorkout[index];
              final isCompletedToday = isCompleted[index];

              return Expanded(
                child: Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: isToday
                        ? LaconicTheme.primary.withValues(alpha: 0.1)
                        : Colors.transparent,
                    border: Border(
                      right: index < 6
                          ? const BorderSide(
                              color: LaconicTheme.surfaceContainer,
                            )
                          : BorderSide.none,
                    ),
                  ),
                  child: Column(
                    children: [
                      Text(
                        weekDays[index],
                        style: GoogleFonts.workSans(
                          fontSize: 10,
                          color: isToday
                              ? LaconicTheme.primary
                              : LaconicTheme.onSurfaceVariant,
                          letterSpacing: 0.1,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Container(
                        width: 32,
                        height: 32,
                        decoration: BoxDecoration(
                          color: isCompletedToday
                              ? LaconicTheme.secondary
                              : hasWorkoutToday
                              ? LaconicTheme.primary.withValues(alpha: 0.3)
                              : isToday
                              ? LaconicTheme.primary.withValues(alpha: 0.2)
                              : LaconicTheme.surfaceContainerHighest,
                        ),
                        child: Center(
                          child: isCompletedToday
                              ? const Icon(
                                  Icons.check,
                                  color: LaconicTheme.onSecondary,
                                  size: 16,
                                )
                              : hasWorkoutToday
                              ? const Icon(
                                  Icons.fitness_center,
                                  color: LaconicTheme.primary,
                                  size: 16,
                                )
                              : Text(
                                  days[index],
                                  style: GoogleFonts.spaceGrotesk(
                                    fontSize: 14,
                                    fontWeight: FontWeight.w700,
                                    color: isToday
                                        ? LaconicTheme.primary
                                        : LaconicTheme.onSurface,
                                  ),
                                ),
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        isCompletedToday
                            ? 'Done'
                            : hasWorkoutToday
                            ? 'Planned'
                            : isToday
                            ? 'Today'
                            : 'Rest',
                        style: GoogleFonts.workSans(
                          fontSize: 8,
                          color: isCompletedToday || hasWorkoutToday
                              ? LaconicTheme.secondary
                              : LaconicTheme.onSurfaceVariant,
                        ),
                      ),
                    ],
                  ),
                ),
              );
            }),
          ),
        ),
      ],
    );
  }

  Widget _buildTacticalIngestionSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Tactical Data Ingestion',
          style: GoogleFonts.spaceGrotesk(
            fontSize: 16,
            fontWeight: FontWeight.w700,
            color: LaconicTheme.onSurface,
          ),
        ),
        const SizedBox(height: 16),
        Row(
          children: [
            Expanded(
              child: _buildIngestionCard(
                icon: Icons.document_scanner,
                title: 'Scan Journal',
                description: 'OCR-based workout log ingestion',
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _buildIngestionCard(
                icon: Icons.upload_file,
                title: 'Upload Doc',
                description: 'CSV, TXT, or PDF protocol files',
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildIngestionCard({
    required IconData icon,
    required String title,
    required String description,
  }) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: const BoxDecoration(color: LaconicTheme.surfaceContainerLow),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: LaconicTheme.secondary, size: 32),
          const SizedBox(height: 16),
          Text(
            title,
            style: GoogleFonts.spaceGrotesk(
              fontSize: 16,
              fontWeight: FontWeight.w700,
              color: LaconicTheme.onSurface,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            description,
            style: GoogleFonts.inter(
              fontSize: 12,
              color: LaconicTheme.onSurfaceVariant,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildProtocolHistorySection() {
    if (_importedPlans.isEmpty) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Protocol History',
            style: GoogleFonts.spaceGrotesk(
              fontSize: 16,
              fontWeight: FontWeight.w700,
              color: LaconicTheme.onSurface,
            ),
          ),
          const SizedBox(height: 16),
          Container(
            padding: const EdgeInsets.all(16),
            decoration: const BoxDecoration(
              color: LaconicTheme.surfaceContainerLow,
            ),
            child: Text(
              'No imported plans yet. Use the + button to import a workout plan.',
              style: GoogleFonts.inter(
                fontSize: 12,
                color: LaconicTheme.onSurfaceVariant,
              ),
            ),
          ),
        ],
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Protocol History',
          style: GoogleFonts.spaceGrotesk(
            fontSize: 16,
            fontWeight: FontWeight.w700,
            color: LaconicTheme.onSurface,
          ),
        ),
        const SizedBox(height: 16),
        ..._importedPlans.map((plan) {
          final isActive = plan.isActive;
          return GestureDetector(
            onTap: () => _startImportedPlan(plan),
            child: Container(
              margin: const EdgeInsets.only(bottom: 12),
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: LaconicTheme.surfaceContainerLow,
                border: Border(
                  left: BorderSide(
                    color: isActive
                        ? LaconicTheme.secondary
                        : LaconicTheme.outline,
                    width: 4,
                  ),
                ),
              ),
              child: Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          plan.planName,
                          style: GoogleFonts.spaceGrotesk(
                            fontSize: 14,
                            fontWeight: FontWeight.w700,
                            color: LaconicTheme.onSurface,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          isActive
                              ? 'ACTIVE'
                              : 'ARCHIVED: ${plan.createdAt.toIso8601String().split('T')[0]}',
                          style: GoogleFonts.workSans(
                            fontSize: 10,
                            color: isActive
                                ? LaconicTheme.secondary
                                : LaconicTheme.outline,
                            letterSpacing: 0.1,
                          ),
                        ),
                      ],
                    ),
                  ),
                  if (plan.autopilotEnabled)
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 4,
                      ),
                      decoration: BoxDecoration(
                        color: LaconicTheme.secondary.withValues(alpha: 0.2),
                      ),
                      child: Text(
                        'AI',
                        style: GoogleFonts.workSans(
                          fontSize: 10,
                          fontWeight: FontWeight.w700,
                          color: LaconicTheme.secondary,
                        ),
                      ),
                    ),
                  const SizedBox(width: 12),
                  const Icon(
                    Icons.arrow_forward_ios,
                    color: LaconicTheme.outlineVariant,
                    size: 16,
                  ),
                ],
              ),
            ),
          );
        }),
      ],
    );
  }

  Widget _buildPhalanxToggle() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: LaconicTheme.surfaceContainerLow,
        border: Border.all(
          color: _autopilotMode
              ? LaconicTheme.secondary.withValues(alpha: 0.3)
              : LaconicTheme.outlineVariant.withValues(alpha: 0.2),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'PHALANX TOGGLE',
                style: GoogleFonts.workSans(
                  fontSize: 12,
                  fontWeight: FontWeight.w700,
                  color: LaconicTheme.secondary,
                  letterSpacing: 0.2,
                ),
              ),
              Switch(
                value: _autopilotMode,
                activeThumbColor: LaconicTheme.secondary,
                onChanged: (val) => setState(() => _autopilotMode = val),
              ),
            ],
          ),
          Text(
            _autopilotMode ? 'AI ADAPTIVE' : 'STRICT FOLLOW',
            style: GoogleFonts.spaceGrotesk(
              fontSize: 18,
              fontWeight: FontWeight.w700,
              color: LaconicTheme.onSurface,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            _autopilotMode
                ? 'The Agoge AI will optimize imported plans based on your recovery metrics, joint stress, and readiness.'
                : 'Execute imported plans exactly as written. No AI modifications. Lock shields with your baseline.',
            style: GoogleFonts.inter(
              fontSize: 12,
              color: LaconicTheme.onSurfaceVariant,
              height: 1.5,
            ),
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
            const Icon(Icons.error, color: LaconicTheme.error, size: 48),
            const SizedBox(height: 16),
            Text(
              result.errorMessage ?? 'Import failed',
              style: GoogleFonts.inter(color: LaconicTheme.onSurface),
            ),
            const SizedBox(height: 24),
            ElevatedButton(
              onPressed: () => setState(() => _pendingVerification = null),
              style: ElevatedButton.styleFrom(
                backgroundColor: LaconicTheme.secondary,
              ),
              child: Text(
                'BACK',
                style: GoogleFonts.spaceGrotesk(fontWeight: FontWeight.w700),
              ),
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
                icon: const Icon(Icons.arrow_back, color: LaconicTheme.outline),
                onPressed: () => setState(() => _pendingVerification = null),
              ),
              Expanded(
                child: Text(
                  'VERIFY IMPORT',
                  textAlign: TextAlign.center,
                  style: GoogleFonts.spaceGrotesk(
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                    color: LaconicTheme.secondary,
                    letterSpacing: 0.1,
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
                  ? LaconicTheme.secondary.withValues(alpha: 0.1)
                  : LaconicTheme.primary.withValues(alpha: 0.1),
              border: Border.all(
                color: (result.confidence ?? 0) > 0.7
                    ? LaconicTheme.secondary.withValues(alpha: 0.3)
                    : LaconicTheme.primary.withValues(alpha: 0.3),
              ),
            ),
            child: Column(
              children: [
                Text(
                  'CONFIDENCE: ${((result.confidence ?? 0) * 100).toStringAsFixed(0)}%',
                  style: GoogleFonts.spaceGrotesk(
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
                    color: (result.confidence ?? 0) > 0.7
                        ? LaconicTheme.secondary
                        : LaconicTheme.primary,
                    letterSpacing: 0.1,
                  ),
                ),
                if (warnings.isNotEmpty) ...[
                  const SizedBox(height: 8),
                  ...warnings.map(
                    (w) => Text(
                      '• $w',
                      style: GoogleFonts.inter(
                        color: LaconicTheme.onSurfaceVariant,
                        fontSize: 11,
                      ),
                    ),
                  ),
                ],
              ],
            ),
          ),
          const SizedBox(height: 24),

          Text(
            protocol.title,
            style: GoogleFonts.spaceGrotesk(
              fontSize: 20,
              fontWeight: FontWeight.w700,
              color: LaconicTheme.onSurface,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            protocol.subtitle,
            style: GoogleFonts.inter(
              color: LaconicTheme.onSurfaceVariant,
              fontSize: 12,
            ),
          ),
          const SizedBox(height: 20),

          Text(
            'EXERCISES:',
            style: GoogleFonts.workSans(
              fontSize: 12,
              fontWeight: FontWeight.w700,
              color: LaconicTheme.secondary,
              letterSpacing: 0.2,
            ),
          ),
          const SizedBox(height: 12),
          ...protocol.entries.map(
            (entry) => Container(
              margin: const EdgeInsets.only(bottom: 8),
              padding: const EdgeInsets.all(12),
              decoration: const BoxDecoration(
                color: LaconicTheme.surfaceContainerLow,
              ),
              child: Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          entry.exercise.name,
                          style: GoogleFonts.spaceGrotesk(
                            fontSize: 14,
                            fontWeight: FontWeight.w700,
                            color: LaconicTheme.onSurface,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          '${entry.sets} sets × ${entry.reps > 0 ? entry.reps : 'MAX'} reps @ RPE ${entry.intensityRpe.toStringAsFixed(1)}',
                          style: GoogleFonts.inter(
                            color: LaconicTheme.onSurfaceVariant,
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

          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: () => _confirmImport(protocol),
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
                'CONFIRM IMPORT',
                style: GoogleFonts.spaceGrotesk(
                  fontSize: 16,
                  fontWeight: FontWeight.w900,
                  letterSpacing: 0.1,
                ),
              ),
            ),
          ),
          const SizedBox(height: 12),
          Center(
            child: TextButton(
              onPressed: () => setState(() => _pendingVerification = null),
              child: Text(
                'CANCEL',
                style: GoogleFonts.workSans(
                  color: LaconicTheme.outline,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
          ),
        ],
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
      backgroundColor: LaconicTheme.surfaceContainer,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.zero),
      title: Text(
        'IMPORT WORKOUT',
        style: GoogleFonts.spaceGrotesk(
          color: LaconicTheme.onSurface,
          fontSize: 16,
          fontWeight: FontWeight.w900,
          letterSpacing: 0.1,
        ),
      ),
      content: SizedBox(
        width: double.maxFinite,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Paste workout text:',
              style: GoogleFonts.inter(
                color: LaconicTheme.onSurfaceVariant,
                fontSize: 12,
              ),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _controller,
              maxLines: 8,
              style: GoogleFonts.inter(
                color: LaconicTheme.onSurface,
                fontSize: 12,
              ),
              decoration: InputDecoration(
                hintText: '''Day 1: Push
3x10 Bench Press @8 RPE
4x8 Overhead Press @7 RPE''',
                hintStyle: GoogleFonts.inter(color: LaconicTheme.outline),
                filled: true,
                fillColor: LaconicTheme.surfaceContainerLow,
                border: InputBorder.none,
                enabledBorder: const UnderlineInputBorder(
                  borderSide: BorderSide(color: LaconicTheme.outlineVariant),
                ),
                focusedBorder: const UnderlineInputBorder(
                  borderSide: BorderSide(
                    color: LaconicTheme.secondary,
                    width: 2,
                  ),
                ),
              ),
            ),
            const SizedBox(height: 12),
            Text(
              'Supports: CSV, shorthand (3x10), full text',
              style: GoogleFonts.workSans(
                color: LaconicTheme.outline,
                fontSize: 10,
              ),
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: Text(
            'CANCEL',
            style: GoogleFonts.workSans(
              color: LaconicTheme.outline,
              fontWeight: FontWeight.w700,
            ),
          ),
        ),
        ElevatedButton(
          onPressed: () => Navigator.pop(context, _controller.text),
          style: ElevatedButton.styleFrom(
            backgroundColor: LaconicTheme.secondary,
            foregroundColor: LaconicTheme.onSecondary,
            shape: const RoundedRectangleBorder(
              borderRadius: BorderRadius.zero,
            ),
          ),
          child: Text(
            'IMPORT',
            style: GoogleFonts.spaceGrotesk(
              fontWeight: FontWeight.w900,
              letterSpacing: 0.1,
            ),
          ),
        ),
      ],
    );
  }
}
