import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import '../theme.dart';
import '../models/user_profile.dart';
import '../providers/auth_provider.dart';
import '../services/ai_plan_service.dart';

/// Baseline Establishment - Onboarding Screen
/// Based on baseline_establishment design
class OnboardingScreen extends StatefulWidget {
  final VoidCallback onComplete;

  const OnboardingScreen({super.key, required this.onComplete});

  @override
  State<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends State<OnboardingScreen> {
  bool _isLoading = false;
  String? _error;

  // Form data
  final _nameController = TextEditingController();
  final _ageController = TextEditingController();
  final _weightController = TextEditingController();
  final _heightController = TextEditingController();
  
  String? _selectedDiscipline;
  String? _selectedPhase;
  FitnessLevel? _selectedLevel;
  int _trainingDays = 4;

  final _aiService = AIPlanService();

  final List<Map<String, dynamic>> _disciplines = [
    {
      'name': 'Boxing',
      'category': 'Striking',
      'icon': Icons.sports_mma,
    },
    {
      'name': 'Wrestling',
      'category': 'Grappling',
      'icon': Icons.sports_kabaddi,
    },
    {
      'name': 'MMA',
      'category': 'Combined',
      'icon': Icons.sports_martial_arts,
    },
  ];

  final List<Map<String, dynamic>> _phases = [
    {
      'name': 'Fight Camp',
      'description': 'Peak performance, metabolic conditioning, and tactical specificity. High intensity, high strain.',
    },
    {
      'name': 'Off-Season',
      'description': 'Technical refinement, recovery optimization, and structural balance. Moderate intensity.',
    },
    {
      'name': 'Functional Hypertrophy',
      'description': 'Absolute strength and lean tissue accrual. Focused on force production and armor building.',
    },
  ];

  @override
  void dispose() {
    _nameController.dispose();
    _ageController.dispose();
    _weightController.dispose();
    _heightController.dispose();
    super.dispose();
  }

  Future<void> _completeOnboarding() async {
    if (!_validateForm()) return;

    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      final authProvider = context.read<AuthProvider>();
      final userId = authProvider.userId;

      if (userId == null) {
        throw Exception('You must be logged in to complete onboarding.');
      }

      final profile = UserProfile(
        userId: userId,
        displayName: _nameController.text.isNotEmpty ? _nameController.text : null,
        bodyComposition: BodyComposition(
          weight: double.parse(_weightController.text),
          height: double.parse(_heightController.text),
          age: int.parse(_ageController.text),
        ),
        fitnessLevel: _selectedLevel ?? FitnessLevel.intermediate,
        trainingGoal: _getGoalFromDiscipline(),
        trainingDaysPerWeek: _trainingDays,
        preferredWorkoutDuration: 60,
        createdAt: DateTime.now(),
        hasCompletedOnboarding: true,
      );

      final saved = await authProvider.saveOnboardingProfile(profile);
      if (!saved) {
        throw Exception(authProvider.error ?? 'Failed to save profile');
      }

      await _aiService.generateInitialTrainingPlan(profile);
      widget.onComplete();
    } catch (e) {
      setState(() {
        _error = e.toString();
        _isLoading = false;
      });
    }
  }

  TrainingGoal _getGoalFromDiscipline() {
    switch (_selectedDiscipline) {
      case 'Boxing':
        return TrainingGoal.boxing;
      case 'Wrestling':
        return TrainingGoal.wrestling;
      case 'MMA':
        return TrainingGoal.mma;
      default:
        return TrainingGoal.generalCombat;
    }
  }

  bool _validateForm() {
    if (_nameController.text.isEmpty) {
      _showError('Please enter your name');
      return false;
    }
    if (_ageController.text.isEmpty || int.tryParse(_ageController.text) == null) {
      _showError('Please enter a valid age');
      return false;
    }
    if (_weightController.text.isEmpty || double.tryParse(_weightController.text) == null) {
      _showError('Please enter a valid weight');
      return false;
    }
    if (_heightController.text.isEmpty || double.tryParse(_heightController.text) == null) {
      _showError('Please enter a valid height');
      return false;
    }
    if (_selectedDiscipline == null) {
      _showError('Please select your primary discipline');
      return false;
    }
    if (_selectedPhase == null) {
      _showError('Please select your training phase');
      return false;
    }
    return true;
  }

  void _showError(String message) {
    setState(() => _error = message);
    HapticFeedback.heavyImpact();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: LaconicTheme.background,
      appBar: AppBar(
        backgroundColor: LaconicTheme.background,
        elevation: 0,
        leading: const Icon(Icons.shield, color: LaconicTheme.primary),
        title: Text(
          'THE AGOGE',
          style: GoogleFonts.spaceGrotesk(
            fontSize: 24,
            fontWeight: FontWeight.w900,
            color: LaconicTheme.secondary,
            letterSpacing: -0.02,
          ),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.account_circle, color: LaconicTheme.surfaceBright),
            onPressed: () {},
          ),
        ],
      ),
      body: _isLoading
          ? const Center(
              child: CircularProgressIndicator(color: LaconicTheme.secondary),
            )
          : SingleChildScrollView(
              padding: const EdgeInsets.all(24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Header
                  Text(
                    'Initiation Protocol',
                    style: GoogleFonts.workSans(
                      fontSize: 12,
                      fontWeight: FontWeight.w700,
                      color: LaconicTheme.secondary,
                      letterSpacing: 0.2,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Baseline',
                    style: GoogleFonts.spaceGrotesk(
                      fontSize: 56,
                      fontWeight: FontWeight.w900,
                      color: LaconicTheme.onSurface,
                      letterSpacing: -0.04,
                      height: 1,
                    ),
                  ),
                  Text(
                    'Establishment',
                    style: GoogleFonts.spaceGrotesk(
                      fontSize: 56,
                      fontWeight: FontWeight.w900,
                      color: LaconicTheme.primary,
                      letterSpacing: -0.04,
                      height: 1,
                    ),
                  ),
                  const SizedBox(height: 32),

                  // Error message
                  if (_error != null)
                    Container(
                      padding: const EdgeInsets.all(16),
                      margin: const EdgeInsets.only(bottom: 24),
                      decoration: const BoxDecoration(
                        color: LaconicTheme.errorContainer,
                      ),
                      child: Row(
                        children: [
                          const Icon(Icons.error, color: LaconicTheme.error),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Text(
                              _error!,
                              style: const TextStyle(color: LaconicTheme.onError),
                            ),
                          ),
                        ],
                      ),
                    ),

                  // Personal Info Section
                  _buildSectionHeader('Personal Data', 'Required'),
                  const SizedBox(height: 16),
                  _buildTextField(
                    controller: _nameController,
                    label: 'WARRIOR DESIGNATION',
                    hint: 'Enter your name',
                  ),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      Expanded(
                        child: _buildTextField(
                          controller: _ageController,
                          label: 'AGE',
                          hint: 'Years',
                          keyboardType: TextInputType.number,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: _buildTextField(
                          controller: _weightController,
                          label: 'WEIGHT (KG)',
                          hint: 'kg',
                          keyboardType: TextInputType.number,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: _buildTextField(
                          controller: _heightController,
                          label: 'HEIGHT (CM)',
                          hint: 'cm',
                          keyboardType: TextInputType.number,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 32),

                  // Primary Discipline Section
                  _buildSectionHeader('Primary Discipline', 'Select One (01)'),
                  const SizedBox(height: 16),
                  Row(
                    children: _disciplines.map((discipline) {
                      final isSelected = _selectedDiscipline == discipline['name'];
                      return Expanded(
                        child: GestureDetector(
                          onTap: () => setState(() => _selectedDiscipline = discipline['name']),
                          child: Container(
                            margin: const EdgeInsets.only(right: 12),
                            padding: const EdgeInsets.all(16),
                            decoration: BoxDecoration(
                              color: LaconicTheme.surfaceContainer,
                              border: Border.all(
                                color: isSelected ? LaconicTheme.secondary : Colors.transparent,
                                width: 2,
                              ),
                            ),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                if (isSelected)
                                  Align(
                                    alignment: Alignment.topRight,
                                    child: Icon(
                                      Icons.check_circle,
                                      color: LaconicTheme.secondary,
                                      size: 20,
                                    ),
                                  ),
                                const SizedBox(height: 8),
                                Icon(
                                  discipline['icon'] as IconData,
                                  color: isSelected ? LaconicTheme.secondary : LaconicTheme.outline,
                                  size: 32,
                                ),
                                const SizedBox(height: 12),
                                Text(
                                  discipline['category'] as String,
                                  style: GoogleFonts.workSans(
                                    fontSize: 10,
                                    color: isSelected ? LaconicTheme.secondary : LaconicTheme.outline,
                                    letterSpacing: 0.05,
                                  ),
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  discipline['name'] as String,
                                  style: GoogleFonts.spaceGrotesk(
                                    fontSize: 18,
                                    fontWeight: FontWeight.w900,
                                    color: LaconicTheme.onSurface,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      );
                    }).toList(),
                  ),
                  const SizedBox(height: 32),

                  // Training Phase Section
                  _buildSectionHeader('Current Training Phase', ''),
                  const SizedBox(height: 16),
                  ..._phases.map((phase) {
                    final isSelected = _selectedPhase == phase['name'];
                    return GestureDetector(
                      onTap: () => setState(() => _selectedPhase = phase['name']),
                      child: Container(
                        margin: const EdgeInsets.only(bottom: 12),
                        padding: const EdgeInsets.all(20),
                        decoration: BoxDecoration(
                          color: LaconicTheme.surfaceContainer,
                          border: Border(
                            left: BorderSide(
                              color: isSelected ? LaconicTheme.secondary : Colors.transparent,
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
                                    phase['name'] as String,
                                    style: GoogleFonts.spaceGrotesk(
                                      fontSize: 16,
                                      fontWeight: FontWeight.w700,
                                      color: isSelected ? LaconicTheme.secondary : LaconicTheme.onSurface,
                                    ),
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    phase['description'] as String,
                                    style: GoogleFonts.inter(
                                      fontSize: 12,
                                      color: LaconicTheme.onSurfaceVariant,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            Container(
                              width: 24,
                              height: 24,
                              decoration: BoxDecoration(
                                border: Border.all(
                                  color: isSelected ? LaconicTheme.secondary : LaconicTheme.outlineVariant,
                                  width: 2,
                                ),
                              ),
                              child: isSelected
                                  ? Container(
                                      color: LaconicTheme.secondary,
                                      child: const Icon(
                                        Icons.check,
                                        color: LaconicTheme.onSecondary,
                                        size: 16,
                                      ),
                                    )
                                  : null,
                            ),
                          ],
                        ),
                      ),
                    );
                  }),
                  const SizedBox(height: 32),

                  // Training Days
                  _buildSectionHeader('Training Frequency', 'Days per week'),
                  const SizedBox(height: 16),
                  Row(
                    children: [3, 4, 5, 6].map((days) {
                      final isSelected = _trainingDays == days;
                      return Expanded(
                        child: GestureDetector(
                          onTap: () => setState(() => _trainingDays = days),
                          child: Container(
                            margin: const EdgeInsets.only(right: 8),
                            padding: const EdgeInsets.symmetric(vertical: 16),
                            decoration: BoxDecoration(
                              color: isSelected ? LaconicTheme.secondary : LaconicTheme.surfaceContainer,
                            ),
                            child: Center(
                              child: Text(
                                '$days',
                                style: GoogleFonts.spaceGrotesk(
                                  fontSize: 24,
                                  fontWeight: FontWeight.w900,
                                  color: isSelected ? LaconicTheme.onSecondary : LaconicTheme.onSurface,
                                ),
                              ),
                            ),
                          ),
                        ),
                      );
                    }).toList(),
                  ),
                  const SizedBox(height: 48),

                  // Establish Baseline Button
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: _completeOnboarding,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: LaconicTheme.primary,
                        foregroundColor: LaconicTheme.onPrimary,
                        elevation: 0,
                        padding: const EdgeInsets.symmetric(vertical: 24),
                        shape: const RoundedRectangleBorder(borderRadius: BorderRadius.zero),
                      ),
                      child: Text(
                        'ESTABLISH BASELINE',
                        style: GoogleFonts.spaceGrotesk(
                          fontSize: 20,
                          fontWeight: FontWeight.w900,
                          letterSpacing: 0.1,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                  Center(
                    child: Text(
                      'All data is encrypted via protocol 09-S. Precision is mandatory.',
                      style: GoogleFonts.workSans(
                        fontSize: 10,
                        color: LaconicTheme.onSurfaceVariant,
                        letterSpacing: 0.1,
                      ),
                    ),
                  ),
                  const SizedBox(height: 32),
                ],
              ),
            ),
    );
  }

  Widget _buildSectionHeader(String title, String subtitle) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          title,
          style: GoogleFonts.spaceGrotesk(
            fontSize: 20,
            fontWeight: FontWeight.w700,
            color: LaconicTheme.onSurface,
          ),
        ),
        if (subtitle.isNotEmpty)
          Text(
            subtitle,
            style: GoogleFonts.workSans(
              fontSize: 10,
              color: LaconicTheme.onSurfaceVariant,
              letterSpacing: 0.1,
            ),
          ),
      ],
    );
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required String label,
    required String hint,
    TextInputType? keyboardType,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: GoogleFonts.workSans(
            fontSize: 10,
            fontWeight: FontWeight.w700,
            color: LaconicTheme.secondary,
            letterSpacing: 0.1,
          ),
        ),
        const SizedBox(height: 8),
        Container(
          decoration: const BoxDecoration(
            color: LaconicTheme.surfaceContainerHighest,
          ),
          child: TextField(
            controller: controller,
            keyboardType: keyboardType,
            style: GoogleFonts.spaceGrotesk(
              fontSize: 16,
              color: LaconicTheme.onSurface,
            ),
            decoration: InputDecoration(
              hintText: hint,
              hintStyle: GoogleFonts.inter(
                color: LaconicTheme.outline,
              ),
              contentPadding: const EdgeInsets.all(16),
              border: InputBorder.none,
              enabledBorder: const UnderlineInputBorder(
                borderSide: BorderSide(color: LaconicTheme.outlineVariant),
              ),
              focusedBorder: const UnderlineInputBorder(
                borderSide: BorderSide(color: LaconicTheme.secondary, width: 2),
              ),
            ),
          ),
        ),
      ],
    );
  }
}
