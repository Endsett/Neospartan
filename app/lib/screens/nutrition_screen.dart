import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import '../theme.dart';
import '../providers/auth_provider.dart';
import '../models/fuel_log.dart';
import '../models/fuel_entry.dart';
import '../services/supabase_database_service.dart';

/// Nutrition Screen - Macro Tracking and Fuel Logs
class NutritionScreen extends StatefulWidget {
  const NutritionScreen({super.key});

  @override
  State<NutritionScreen> createState() => _NutritionScreenState();
}

class _NutritionScreenState extends State<NutritionScreen> {
  final SupabaseDatabaseService _database = SupabaseDatabaseService();

  FuelLog? _todayLog;
  bool _isLoading = true;
  String? _userId;

  @override
  void initState() {
    super.initState();
    _userId = Provider.of<AuthProvider>(context, listen: false).userId;
    _loadTodayLog();
  }

  Future<void> _loadTodayLog() async {
    if (_userId == null) {
      setState(() => _isLoading = false);
      return;
    }

    setState(() => _isLoading = true);

    try {
      final entries = await _database.getFuelLogsForDate(
        _userId!,
        DateTime.now(),
      );

      final fuelEntries = entries
          .map(
            (data) => FuelEntry(
              id: data['id']?.toString() ?? '',
              itemName: data['item_name']?.toString() ?? '',
              protein: (data['protein'] as num?)?.toDouble() ?? 0,
              carbs: (data['carbs'] as num?)?.toDouble() ?? 0,
              fat: (data['fat'] as num?)?.toDouble() ?? 0,
              calories: (data['calories'] as num?)?.toInt() ?? 0,
              timestamp: data['timestamp'] != null
                  ? DateTime.parse(data['timestamp'].toString())
                  : DateTime.now(),
            ),
          )
          .toList();

      setState(() {
        _todayLog = FuelLog(entries: fuelEntries, date: DateTime.now());
        _isLoading = false;
      });
    } catch (e) {
      debugPrint('Error loading fuel logs: $e');
      setState(() => _isLoading = false);
    }
  }

  Future<void> _showAddEntryDialog() async {
    final result = await showDialog<Map<String, dynamic>>(
      context: context,
      builder: (context) => const _AddFuelEntryDialog(),
    );

    if (result != null && _userId != null) {
      try {
        await _database.saveFuelLogEntry({
          'user_id': _userId!,
          'item_name': result['name'],
          'calories': result['calories'],
          'protein': result['protein'],
          'carbs': result['carbs'],
          'fat': result['fats'],
          'timestamp': DateTime.now().toIso8601String(),
        });
        await _loadTodayLog();

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Fuel entry saved'),
              backgroundColor: LaconicTheme.secondary,
            ),
          );
        }
      } catch (e) {
        debugPrint('Error saving fuel entry: $e');
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return Scaffold(
        backgroundColor: LaconicTheme.background,
        body: const Center(
          child: CircularProgressIndicator(color: LaconicTheme.secondary),
        ),
      );
    }

    final log = _todayLog;
    final hasEntries = log != null && log.entries.isNotEmpty;

    return Scaffold(
      backgroundColor: LaconicTheme.background,
      appBar: AppBar(
        backgroundColor: LaconicTheme.background,
        elevation: 0,
        title: Row(
          children: [
            const Icon(Icons.local_dining, color: LaconicTheme.secondary),
            const SizedBox(width: 12),
            Text(
              'THE MESS',
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
            icon: const Icon(Icons.refresh, color: LaconicTheme.secondary),
            onPressed: _loadTodayLog,
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header
            Text(
              'Nutrition',
              style: GoogleFonts.workSans(
                fontSize: 12,
                fontWeight: FontWeight.w700,
                color: LaconicTheme.secondary,
                letterSpacing: 0.2,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Fuel',
              style: GoogleFonts.spaceGrotesk(
                fontSize: 48,
                fontWeight: FontWeight.w900,
                color: LaconicTheme.onSurface,
                letterSpacing: -0.04,
                height: 1,
              ),
            ),
            Text(
              'Protocol',
              style: GoogleFonts.spaceGrotesk(
                fontSize: 48,
                fontWeight: FontWeight.w900,
                color: LaconicTheme.secondary,
                letterSpacing: -0.04,
                height: 1,
              ),
            ),
            const SizedBox(height: 32),

            // Macro Overview
            if (hasEntries) _buildMacroOverview(log) else _buildEmptyMacros(),
            const SizedBox(height: 32),

            // Today's Entries
            _buildTodayEntriesSection(log),
            const SizedBox(height: 32),

            // Quick Add Button
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: _showAddEntryDialog,
                icon: const Icon(Icons.add),
                label: Text(
                  'LOG FUEL',
                  style: GoogleFonts.spaceGrotesk(
                    fontSize: 16,
                    fontWeight: FontWeight.w900,
                    letterSpacing: 0.1,
                  ),
                ),
                style: ElevatedButton.styleFrom(
                  backgroundColor: LaconicTheme.secondary,
                  foregroundColor: LaconicTheme.onSecondary,
                  elevation: 0,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: const RoundedRectangleBorder(
                    borderRadius: BorderRadius.zero,
                  ),
                ),
              ),
            ),
            const SizedBox(height: 32),
          ],
        ),
      ),
    );
  }

  Widget _buildMacroOverview(FuelLog log) {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: const BoxDecoration(color: LaconicTheme.surfaceContainerLow),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            "TODAY'S MACROS",
            style: GoogleFonts.workSans(
              fontSize: 12,
              fontWeight: FontWeight.w700,
              color: LaconicTheme.secondary,
              letterSpacing: 0.1,
            ),
          ),
          const SizedBox(height: 24),

          // Calories
          _buildMacroBar(
            label: 'Calories',
            current: log.totalCalories.toDouble(),
            target: FuelLog.targetCalories.toDouble(),
            unit: 'kcal',
            color: LaconicTheme.secondary,
          ),
          const SizedBox(height: 20),

          // Protein
          _buildMacroBar(
            label: 'Protein',
            current: log.totalProtein,
            target: FuelLog.targetProtein,
            unit: 'g',
            color: LaconicTheme.primary,
          ),
          const SizedBox(height: 20),

          // Carbs
          _buildMacroBar(
            label: 'Carbohydrates',
            current: log.totalCarbs,
            target: FuelLog.targetCarbs,
            unit: 'g',
            color: LaconicTheme.outline,
          ),
          const SizedBox(height: 20),

          // Fats
          _buildMacroBar(
            label: 'Fats',
            current: log.totalFat,
            target: FuelLog.targetFat,
            unit: 'g',
            color: LaconicTheme.outlineVariant,
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyMacros() {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: const BoxDecoration(color: LaconicTheme.surfaceContainerLow),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            "TODAY'S MACROS",
            style: GoogleFonts.workSans(
              fontSize: 12,
              fontWeight: FontWeight.w700,
              color: LaconicTheme.secondary,
              letterSpacing: 0.1,
            ),
          ),
          const SizedBox(height: 24),
          Text(
            'No fuel logged today. Start tracking your nutrition.',
            style: GoogleFonts.inter(
              fontSize: 14,
              color: LaconicTheme.onSurfaceVariant,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMacroBar({
    required String label,
    required double current,
    required double target,
    required String unit,
    required Color color,
  }) {
    final progress = (current / target).clamp(0.0, 1.0);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              label,
              style: GoogleFonts.workSans(
                fontSize: 12,
                color: LaconicTheme.onSurfaceVariant,
              ),
            ),
            Text(
              '${current.toInt()} / ${target.toInt()} $unit',
              style: GoogleFonts.spaceGrotesk(
                fontSize: 14,
                fontWeight: FontWeight.w700,
                color: LaconicTheme.onSurface,
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        Container(
          height: 8,
          width: double.infinity,
          color: LaconicTheme.surfaceContainerHighest,
          child: FractionallySizedBox(
            alignment: Alignment.centerLeft,
            widthFactor: progress,
            child: Container(color: color),
          ),
        ),
      ],
    );
  }

  Widget _buildTodayEntriesSection(FuelLog? log) {
    final entries = log?.entries ?? [];

    if (entries.isEmpty) {
      return Container(
        padding: const EdgeInsets.all(24),
        decoration: const BoxDecoration(
          color: LaconicTheme.surfaceContainerLow,
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              "TODAY'S ENTRIES",
              style: GoogleFonts.workSans(
                fontSize: 12,
                fontWeight: FontWeight.w700,
                color: LaconicTheme.secondary,
                letterSpacing: 0.1,
              ),
            ),
            const SizedBox(height: 16),
            Text(
              'No entries yet. Log your first meal.',
              style: GoogleFonts.inter(
                fontSize: 14,
                color: LaconicTheme.onSurfaceVariant,
              ),
            ),
          ],
        ),
      );
    }

    return Container(
      padding: const EdgeInsets.all(24),
      decoration: const BoxDecoration(color: LaconicTheme.surfaceContainerLow),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            "TODAY'S ENTRIES",
            style: GoogleFonts.workSans(
              fontSize: 12,
              fontWeight: FontWeight.w700,
              color: LaconicTheme.secondary,
              letterSpacing: 0.1,
            ),
          ),
          const SizedBox(height: 16),
          ...entries.map(
            (entry) => Container(
              margin: const EdgeInsets.only(bottom: 12),
              padding: const EdgeInsets.all(16),
              decoration: const BoxDecoration(
                color: LaconicTheme.surfaceContainer,
              ),
              child: Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          entry.itemName,
                          style: GoogleFonts.spaceGrotesk(
                            fontSize: 14,
                            fontWeight: FontWeight.w700,
                            color: LaconicTheme.onSurface,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          '${entry.calories} kcal • P: ${entry.protein.toInt()}g • C: ${entry.carbs.toInt()}g • F: ${entry.fat.toInt()}g',
                          style: GoogleFonts.workSans(
                            fontSize: 10,
                            color: LaconicTheme.onSurfaceVariant,
                          ),
                        ),
                      ],
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 4,
                    ),
                    decoration: BoxDecoration(
                      color: LaconicTheme.secondary.withValues(alpha: 0.2),
                    ),
                    child: Text(
                      '${entry.timestamp.hour}:${entry.timestamp.minute.toString().padLeft(2, '0')}',
                      style: GoogleFonts.workSans(
                        fontSize: 10,
                        fontWeight: FontWeight.w700,
                        color: LaconicTheme.secondary,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// Add Fuel Entry Dialog
class _AddFuelEntryDialog extends StatefulWidget {
  const _AddFuelEntryDialog();

  @override
  State<_AddFuelEntryDialog> createState() => _AddFuelEntryDialogState();
}

class _AddFuelEntryDialogState extends State<_AddFuelEntryDialog> {
  final _nameController = TextEditingController();
  final _caloriesController = TextEditingController();
  final _proteinController = TextEditingController();
  final _carbsController = TextEditingController();
  final _fatsController = TextEditingController();

  @override
  void dispose() {
    _nameController.dispose();
    _caloriesController.dispose();
    _proteinController.dispose();
    _carbsController.dispose();
    _fatsController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: LaconicTheme.surfaceContainerLow,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.zero),
      child: Container(
        padding: const EdgeInsets.all(24),
        constraints: const BoxConstraints(maxWidth: 400),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'LOG FUEL',
              style: GoogleFonts.spaceGrotesk(
                fontSize: 20,
                fontWeight: FontWeight.w900,
                color: LaconicTheme.secondary,
                letterSpacing: 0.1,
              ),
            ),
            const SizedBox(height: 16),
            _buildTextField('Item Name', _nameController),
            const SizedBox(height: 12),
            _buildNumberField('Calories', _caloriesController),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: _buildNumberField('Protein (g)', _proteinController),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _buildNumberField('Carbs (g)', _carbsController),
                ),
                const SizedBox(width: 12),
                Expanded(child: _buildNumberField('Fats (g)', _fatsController)),
              ],
            ),
            const SizedBox(height: 24),
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                TextButton(
                  onPressed: () => Navigator.of(context).pop(),
                  child: Text(
                    'CANCEL',
                    style: GoogleFonts.spaceGrotesk(
                      color: LaconicTheme.onSurfaceVariant,
                    ),
                  ),
                ),
                const SizedBox(width: 16),
                ElevatedButton(
                  onPressed: () {
                    final calories =
                        int.tryParse(_caloriesController.text) ?? 0;
                    if (calories > 0 && _nameController.text.isNotEmpty) {
                      Navigator.of(context).pop({
                        'name': _nameController.text,
                        'calories': calories,
                        'protein':
                            double.tryParse(_proteinController.text) ?? 0,
                        'carbs': double.tryParse(_carbsController.text) ?? 0,
                        'fats': double.tryParse(_fatsController.text) ?? 0,
                      });
                    }
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: LaconicTheme.secondary,
                    foregroundColor: LaconicTheme.onSecondary,
                    elevation: 0,
                    shape: const RoundedRectangleBorder(
                      borderRadius: BorderRadius.zero,
                    ),
                  ),
                  child: Text(
                    'SAVE',
                    style: GoogleFonts.spaceGrotesk(
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTextField(String label, TextEditingController controller) {
    return TextField(
      controller: controller,
      decoration: InputDecoration(
        labelText: label,
        labelStyle: GoogleFonts.inter(color: LaconicTheme.outline),
        filled: true,
        fillColor: LaconicTheme.surfaceContainer,
        border: const OutlineInputBorder(
          borderRadius: BorderRadius.zero,
          borderSide: BorderSide.none,
        ),
      ),
      style: GoogleFonts.inter(color: LaconicTheme.onSurface),
    );
  }

  Widget _buildNumberField(String label, TextEditingController controller) {
    return TextField(
      controller: controller,
      keyboardType: TextInputType.number,
      decoration: InputDecoration(
        labelText: label,
        labelStyle: GoogleFonts.inter(
          color: LaconicTheme.outline,
          fontSize: 12,
        ),
        filled: true,
        fillColor: LaconicTheme.surfaceContainer,
        border: const OutlineInputBorder(
          borderRadius: BorderRadius.zero,
          borderSide: BorderSide.none,
        ),
      ),
      style: GoogleFonts.inter(color: LaconicTheme.onSurface),
    );
  }
}
