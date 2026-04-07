// ignore_for_file: unused_field, use_build_context_synchronously
import 'package:flutter/material.dart';
import '../models/workout_preferences.dart';
import '../models/exercise.dart';
import '../models/user_profile.dart';
import '../repositories/workout_preferences_repository.dart';
import '../config/supabase_config.dart';
import '../theme.dart';

/// Screen for configuring workout generation preferences
class WorkoutPreferencesScreen extends StatefulWidget {
  final UserProfile profile;
  final WorkoutPreferences? initialPreferences;
  final Function(WorkoutPreferences) onGenerate;

  const WorkoutPreferencesScreen({
    super.key,
    required this.profile,
    this.initialPreferences,
    required this.onGenerate,
  });

  @override
  State<WorkoutPreferencesScreen> createState() =>
      _WorkoutPreferencesScreenState();
}

class _WorkoutPreferencesScreenState extends State<WorkoutPreferencesScreen> {
  final WorkoutPreferencesRepository _prefsRepo =
      WorkoutPreferencesRepository();

  late int _intensity;
  late int _duration;
  late int _exerciseCount;
  late int _setsPerExercise;
  late TrainingFocus _trainingFocus;
  late List<ExerciseCategory> _selectedCategories;
  late bool _includeCardio;
  late bool _includeMobility;
  late String? _specificFocus;

  final TextEditingController _focusController = TextEditingController();
  bool _isLoading = false;

  final List<int> _durationOptions = [20, 30, 45, 60, 90];

  @override
  void initState() {
    super.initState();
    _loadPreferences();
  }

  void _loadPreferences() {
    final prefs = widget.initialPreferences;
    if (prefs != null) {
      _intensity = prefs.targetIntensity;
      _duration = prefs.targetDurationMinutes;
      _exerciseCount = prefs.preferredExerciseCount;
      _setsPerExercise = prefs.setsPerExercise;
      _trainingFocus = prefs.trainingFocus;
      _selectedCategories = List.from(prefs.preferredCategories);
      _includeCardio = prefs.includeCardio;
      _includeMobility = prefs.includeMobility;
      _specificFocus = prefs.specificFocus;
      _focusController.text = prefs.specificFocus ?? '';
    } else {
      _intensity = 7;
      _duration = 45;
      _exerciseCount = 5;
      _setsPerExercise = 3;
      _trainingFocus = TrainingFocus.mixed;
      _selectedCategories = [];
      _includeCardio = false;
      _includeMobility = true;
      _specificFocus = null;
    }
  }

  Future<void> _saveAndGenerate() async {
    setState(() => _isLoading = true);

    final userId = SupabaseConfig.userId ?? widget.profile.userId;
    final now = DateTime.now();

    final preferences = WorkoutPreferences(
      userId: userId,
      targetIntensity: _intensity,
      targetDurationMinutes: _duration,
      preferredCategories: _selectedCategories,
      trainingFocus: _trainingFocus,
      preferredExerciseCount: _exerciseCount,
      setsPerExercise: _setsPerExercise,
      includeCardio: _includeCardio,
      includeMobility: _includeMobility,
      specificFocus: _focusController.text.isNotEmpty
          ? _focusController.text
          : null,
      createdAt: now,
      updatedAt: now,
    );

    // Save preferences
    await _prefsRepo.savePreferences(preferences);

    setState(() => _isLoading = false);

    // Return preferences to caller
    widget.onGenerate(preferences);
    Navigator.pop(context);
  }

  String _getIntensityLabel(int value) {
    if (value <= 2) return 'Recovery';
    if (value <= 4) return 'Light';
    if (value <= 6) return 'Moderate';
    if (value <= 8) return 'Hard';
    return 'Maximum';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('CUSTOM WORKOUT'),
        actions: [
          if (_isLoading)
            const Padding(
              padding: EdgeInsets.all(16),
              child: SizedBox(
                width: 20,
                height: 20,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  color: LaconicTheme.spartanBronze,
                ),
              ),
            )
          else
            TextButton(
              onPressed: _saveAndGenerate,
              child: const Text(
                'GENERATE',
                style: TextStyle(
                  color: LaconicTheme.spartanBronze,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Intensity Section
            _buildSectionTitle('INTENSITY LEVEL'),
            const SizedBox(height: 8),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  '$_intensity/10',
                  style: const TextStyle(
                    color: LaconicTheme.spartanBronze,
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                Text(
                  _getIntensityLabel(_intensity),
                  style: TextStyle(color: Colors.grey[400], fontSize: 14),
                ),
              ],
            ),
            Slider(
              value: _intensity.toDouble(),
              min: 1,
              max: 10,
              divisions: 9,
              activeColor: LaconicTheme.spartanBronze,
              inactiveColor: LaconicTheme.ironGray,
              onChanged: (value) => setState(() => _intensity = value.round()),
            ),
            const SizedBox(height: 24),

            // Duration Section
            _buildSectionTitle('DURATION'),
            const SizedBox(height: 12),
            Wrap(
              spacing: 8,
              children: _durationOptions.map((duration) {
                final isSelected = _duration == duration;
                return ChoiceChip(
                  label: Text('${duration}min'),
                  selected: isSelected,
                  selectedColor: LaconicTheme.spartanBronze.withValues(
                    alpha: 0.3,
                  ),
                  backgroundColor: LaconicTheme.ironGray.withValues(alpha: 0.3),
                  labelStyle: TextStyle(
                    color: isSelected
                        ? LaconicTheme.spartanBronze
                        : Colors.grey[400],
                    fontWeight: isSelected
                        ? FontWeight.bold
                        : FontWeight.normal,
                  ),
                  side: BorderSide(
                    color: isSelected
                        ? LaconicTheme.spartanBronze
                        : Colors.transparent,
                  ),
                  onSelected: (_) => setState(() => _duration = duration),
                );
              }).toList(),
            ),
            const SizedBox(height: 24),

            // Training Focus Section
            _buildSectionTitle('TRAINING FOCUS'),
            const SizedBox(height: 12),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: TrainingFocus.values.map((focus) {
                final isSelected = _trainingFocus == focus;
                return ChoiceChip(
                  label: Text(_getFocusLabel(focus)),
                  selected: isSelected,
                  selectedColor: LaconicTheme.spartanBronze.withValues(
                    alpha: 0.3,
                  ),
                  backgroundColor: LaconicTheme.ironGray.withValues(alpha: 0.3),
                  labelStyle: TextStyle(
                    color: isSelected
                        ? LaconicTheme.spartanBronze
                        : Colors.grey[400],
                    fontWeight: isSelected
                        ? FontWeight.bold
                        : FontWeight.normal,
                  ),
                  side: BorderSide(
                    color: isSelected
                        ? LaconicTheme.spartanBronze
                        : Colors.transparent,
                  ),
                  onSelected: (_) => setState(() => _trainingFocus = focus),
                );
              }).toList(),
            ),
            const SizedBox(height: 24),

            // Exercise Count Section
            _buildSectionTitle('NUMBER OF EXERCISES'),
            const SizedBox(height: 8),
            Row(
              children: [
                IconButton(
                  onPressed: _exerciseCount > 3
                      ? () => setState(() => _exerciseCount--)
                      : null,
                  icon: const Icon(Icons.remove),
                  color: LaconicTheme.spartanBronze,
                ),
                Expanded(
                  child: Text(
                    '$_exerciseCount exercises',
                    textAlign: TextAlign.center,
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                IconButton(
                  onPressed: _exerciseCount < 8
                      ? () => setState(() => _exerciseCount++)
                      : null,
                  icon: const Icon(Icons.add),
                  color: LaconicTheme.spartanBronze,
                ),
              ],
            ),
            const SizedBox(height: 24),

            // Sets Per Exercise Section
            _buildSectionTitle('SETS PER EXERCISE'),
            const SizedBox(height: 8),
            Row(
              children: [
                IconButton(
                  onPressed: _setsPerExercise > 2
                      ? () => setState(() => _setsPerExercise--)
                      : null,
                  icon: const Icon(Icons.remove),
                  color: LaconicTheme.spartanBronze,
                ),
                Expanded(
                  child: Text(
                    '$_setsPerExercise sets',
                    textAlign: TextAlign.center,
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                IconButton(
                  onPressed: _setsPerExercise < 6
                      ? () => setState(() => _setsPerExercise++)
                      : null,
                  icon: const Icon(Icons.add),
                  color: LaconicTheme.spartanBronze,
                ),
              ],
            ),
            const SizedBox(height: 24),

            // Exercise Categories Section
            _buildSectionTitle('EXERCISE CATEGORIES'),
            const SizedBox(height: 12),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: ExerciseCategory.values.map((category) {
                final isSelected = _selectedCategories.contains(category);
                return FilterChip(
                  label: Text(_getCategoryLabel(category)),
                  selected: isSelected,
                  selectedColor: LaconicTheme.spartanBronze.withValues(
                    alpha: 0.3,
                  ),
                  backgroundColor: LaconicTheme.ironGray.withValues(alpha: 0.3),
                  checkmarkColor: LaconicTheme.spartanBronze,
                  labelStyle: TextStyle(
                    color: isSelected
                        ? LaconicTheme.spartanBronze
                        : Colors.grey[400],
                  ),
                  onSelected: (selected) {
                    setState(() {
                      if (selected) {
                        _selectedCategories.add(category);
                      } else {
                        _selectedCategories.remove(category);
                      }
                    });
                  },
                );
              }).toList(),
            ),
            const SizedBox(height: 24),

            // Additional Options Section
            _buildSectionTitle('ADDITIONAL OPTIONS'),
            const SizedBox(height: 12),
            SwitchListTile(
              title: const Text('Include Cardio'),
              subtitle: const Text('Add cardiovascular conditioning'),
              value: _includeCardio,
              activeThumbColor: LaconicTheme.spartanBronze,
              onChanged: (value) => setState(() => _includeCardio = value),
            ),
            SwitchListTile(
              title: const Text('Include Mobility'),
              subtitle: const Text('Add mobility and recovery work'),
              value: _includeMobility,
              activeThumbColor: LaconicTheme.spartanBronze,
              onChanged: (value) => setState(() => _includeMobility = value),
            ),
            const SizedBox(height: 24),

            // Specific Focus Section
            _buildSectionTitle('SPECIFIC FOCUS (OPTIONAL)'),
            const SizedBox(height: 8),
            TextField(
              controller: _focusController,
              decoration: InputDecoration(
                hintText: 'e.g., explosive legs, upper body, core stability...',
                hintStyle: TextStyle(color: Colors.grey[600]),
                filled: true,
                fillColor: LaconicTheme.ironGray.withValues(alpha: 0.2),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                  borderSide: BorderSide.none,
                ),
              ),
              style: const TextStyle(color: Colors.white),
              maxLines: 2,
            ),
            const SizedBox(height: 32),

            // Summary Card
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: LaconicTheme.spartanBronze.withValues(alpha: 0.1),
                border: Border.all(
                  color: LaconicTheme.spartanBronze.withValues(alpha: 0.3),
                ),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'WORKOUT SUMMARY',
                    style: TextStyle(
                      color: LaconicTheme.spartanBronze,
                      fontSize: 12,
                      letterSpacing: 1.5,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 12),
                  Text(
                    '${_exerciseCount * _setsPerExercise} total sets • ~${_duration}min • ${_getIntensityLabel(_intensity)} intensity',
                    style: const TextStyle(color: Colors.white70, fontSize: 14),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Focus: ${_getFocusLabel(_trainingFocus)}',
                    style: TextStyle(color: Colors.grey[400], fontSize: 12),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 32),

            // Generate Button
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: _isLoading ? null : _saveAndGenerate,
                style: ElevatedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 16),
                ),
                child: _isLoading
                    ? const SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: Colors.black,
                        ),
                      )
                    : const Text(
                        'GENERATE CUSTOM WORKOUT',
                        style: TextStyle(
                          fontSize: 14,
                          letterSpacing: 1.5,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSectionTitle(String title) {
    return Text(
      title,
      style: const TextStyle(
        color: LaconicTheme.spartanBronze,
        fontSize: 12,
        letterSpacing: 1.5,
        fontWeight: FontWeight.bold,
      ),
    );
  }

  String _getFocusLabel(TrainingFocus focus) {
    switch (focus) {
      case TrainingFocus.strength:
        return 'Strength';
      case TrainingFocus.conditioning:
        return 'Conditioning';
      case TrainingFocus.mixed:
        return 'Mixed Training';
      case TrainingFocus.technique:
        return 'Technique';
      case TrainingFocus.hypertrophy:
        return 'Muscle Building';
      case TrainingFocus.power:
        return 'Power';
      case TrainingFocus.endurance:
        return 'Endurance';
    }
  }

  String _getCategoryLabel(ExerciseCategory category) {
    switch (category) {
      case ExerciseCategory.plyometric:
        return 'Plyometric';
      case ExerciseCategory.isometric:
        return 'Isometric';
      case ExerciseCategory.combat:
        return 'Combat';
      case ExerciseCategory.strength:
        return 'Strength';
      case ExerciseCategory.mobility:
        return 'Mobility';
      case ExerciseCategory.sprint:
        return 'Sprint';
    }
  }

  @override
  void dispose() {
    _focusController.dispose();
    super.dispose();
  }
}
