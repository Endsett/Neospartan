import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../theme.dart';
import '../models/user_profile.dart';
import '../services/ai_plan_service.dart';

/// Multi-step onboarding screen for first-time users
class OnboardingScreen extends StatefulWidget {
  final VoidCallback onComplete;

  const OnboardingScreen({super.key, required this.onComplete});

  @override
  State<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends State<OnboardingScreen> {
  int _currentStep = 0;
  bool _isLoading = false;
  String? _error;

  // Form data
  final _nameController = TextEditingController();
  final _ageController = TextEditingController();
  final _weightController = TextEditingController();
  final _heightController = TextEditingController();
  final _bodyFatController = TextEditingController();
  String? _selectedGender;
  FitnessLevel? _selectedLevel;
  TrainingGoal? _selectedGoal;
  int _trainingDays = 3;
  int _workoutDuration = 45;
  final List<String> _injuries = [];

  final _firebase = FirebaseSyncService();
  final _aiService = AIPlanService();

  @override
  void dispose() {
    _nameController.dispose();
    _ageController.dispose();
    _weightController.dispose();
    _heightController.dispose();
    _bodyFatController.dispose();
    super.dispose();
  }

  Future<void> _completeOnboarding() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      // Create user profile
      final profile = UserProfile(
        userId: 'anonymous',
        displayName: _nameController.text.isNotEmpty
            ? _nameController.text
            : null,
        bodyComposition: BodyComposition(
          weight: double.parse(_weightController.text),
          height: double.parse(_heightController.text),
          bodyFatPercentage: _bodyFatController.text.isNotEmpty
              ? double.parse(_bodyFatController.text)
              : null,
          age: int.parse(_ageController.text),
          gender: _selectedGender,
        ),
        fitnessLevel: _selectedLevel!,
        trainingGoal: _selectedGoal!,
        trainingDaysPerWeek: _trainingDays,
        preferredWorkoutDuration: _workoutDuration,
        injuriesOrLimitations: _injuries.isNotEmpty ? _injuries : null,
        createdAt: DateTime.now(),
        hasCompletedOnboarding: true,
      );

      // Save profile to Firebase
      await _firebase.saveUserProfile(profile);

      // Generate AI training plan
      await _aiService.generateInitialTrainingPlan(profile);

      widget.onComplete();
    } catch (e) {
      setState(() {
        _error = e.toString();
        _isLoading = false;
      });
    }
  }

  void _nextStep() {
    if (_validateCurrentStep()) {
      HapticFeedback.lightImpact();
      if (_currentStep < 4) {
        setState(() => _currentStep++);
      } else {
        _completeOnboarding();
      }
    }
  }

  void _previousStep() {
    if (_currentStep > 0) {
      HapticFeedback.lightImpact();
      setState(() => _currentStep--);
    }
  }

  bool _validateCurrentStep() {
    switch (_currentStep) {
      case 0:
        if (_nameController.text.isEmpty) {
          _showError('Please enter your name');
          return false;
        }
        if (_ageController.text.isEmpty ||
            int.tryParse(_ageController.text) == null) {
          _showError('Please enter a valid age');
          return false;
        }
        if (_selectedGender == null) {
          _showError('Please select your gender');
          return false;
        }
        return true;
      case 1:
        if (_weightController.text.isEmpty ||
            double.tryParse(_weightController.text) == null) {
          _showError('Please enter a valid weight');
          return false;
        }
        if (_heightController.text.isEmpty ||
            double.tryParse(_heightController.text) == null) {
          _showError('Please enter a valid height');
          return false;
        }
        return true;
      case 2:
        if (_selectedLevel == null) {
          _showError('Please select your fitness level');
          return false;
        }
        return true;
      case 3:
        if (_selectedGoal == null) {
          _showError('Please select your training goal');
          return false;
        }
        return true;
      case 4:
        return true;
      default:
        return false;
    }
  }

  void _showError(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message), backgroundColor: Colors.red),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: LaconicTheme.deepBlack,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            children: [
              // Progress indicator
              LinearProgressIndicator(
                value: (_currentStep + 1) / 5,
                backgroundColor: LaconicTheme.ironGray,
                color: LaconicTheme.spartanBronze,
              ),
              const SizedBox(height: 24),

              // Step counter
              Text(
                'STEP ${_currentStep + 1} OF 5',
                style: const TextStyle(
                  color: LaconicTheme.spartanBronze,
                  fontSize: 12,
                  letterSpacing: 3.0,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 32),

              // Step title
              Text(
                _getStepTitle(),
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  letterSpacing: 2.0,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 8),
              Text(
                _getStepSubtitle(),
                style: const TextStyle(color: Colors.grey, fontSize: 14),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 32),

              // Step content
              Expanded(
                child: SingleChildScrollView(child: _buildStepContent()),
              ),

              // Error message
              if (_error != null)
                Container(
                  padding: const EdgeInsets.all(12),
                  margin: const EdgeInsets.only(bottom: 16),
                  decoration: BoxDecoration(
                    color: Colors.red.withValues(alpha: 0.1),
                    border: Border.all(color: Colors.red),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    _error!,
                    style: const TextStyle(color: Colors.red),
                    textAlign: TextAlign.center,
                  ),
                ),

              // Loading indicator
              if (_isLoading)
                const Column(
                  children: [
                    CircularProgressIndicator(
                      color: LaconicTheme.spartanBronze,
                    ),
                    SizedBox(height: 16),
                    Text(
                      'GENERATING YOUR CUSTOM TRAINING PLAN...',
                      style: TextStyle(
                        color: Colors.grey,
                        fontSize: 12,
                        letterSpacing: 1.0,
                      ),
                    ),
                    SizedBox(height: 24),
                  ],
                )
              else
                // Navigation buttons
                Row(
                  children: [
                    if (_currentStep > 0)
                      Expanded(
                        child: OutlinedButton(
                          onPressed: _previousStep,
                          child: const Text('BACK'),
                        ),
                      ),
                    if (_currentStep > 0) const SizedBox(width: 16),
                    Expanded(
                      flex: 2,
                      child: ElevatedButton(
                        onPressed: _nextStep,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: LaconicTheme.spartanBronze,
                          foregroundColor: Colors.black,
                          padding: const EdgeInsets.symmetric(vertical: 16),
                        ),
                        child: Text(
                          _currentStep == 4 ? 'GENERATE PLAN' : 'CONTINUE',
                          style: const TextStyle(
                            fontWeight: FontWeight.bold,
                            letterSpacing: 2.0,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
            ],
          ),
        ),
      ),
    );
  }

  String _getStepTitle() {
    switch (_currentStep) {
      case 0:
        return 'BASIC INFO';
      case 1:
        return 'BODY COMPOSITION';
      case 2:
        return 'FITNESS LEVEL';
      case 3:
        return 'TRAINING GOAL';
      case 4:
        return 'PREFERENCES';
      default:
        return '';
    }
  }

  String _getStepSubtitle() {
    switch (_currentStep) {
      case 0:
        return 'Let\'s get to know you';
      case 1:
        return 'Your body metrics for personalized planning';
      case 2:
        return 'How experienced are you?';
      case 3:
        return 'What are you training for?';
      case 4:
        return 'Fine-tune your training schedule';
      default:
        return '';
    }
  }

  Widget _buildStepContent() {
    switch (_currentStep) {
      case 0:
        return _buildBasicInfoStep();
      case 1:
        return _buildBodyCompositionStep();
      case 2:
        return _buildFitnessLevelStep();
      case 3:
        return _buildTrainingGoalStep();
      case 4:
        return _buildPreferencesStep();
      default:
        return const SizedBox.shrink();
    }
  }

  Widget _buildBasicInfoStep() {
    return Column(
      children: [
        _buildTextInput('YOUR NAME', _nameController, hint: 'Enter your name'),
        const SizedBox(height: 20),
        _buildTextInput(
          'AGE',
          _ageController,
          hint: '25',
          keyboardType: TextInputType.number,
        ),
        const SizedBox(height: 20),
        _buildGenderSelector(),
      ],
    );
  }

  Widget _buildBodyCompositionStep() {
    return Column(
      children: [
        _buildTextInput(
          'WEIGHT (kg)',
          _weightController,
          hint: '75',
          keyboardType: const TextInputType.numberWithOptions(decimal: true),
        ),
        const SizedBox(height: 20),
        _buildTextInput(
          'HEIGHT (cm)',
          _heightController,
          hint: '175',
          keyboardType: TextInputType.number,
        ),
        const SizedBox(height: 20),
        _buildTextInput(
          'BODY FAT % (optional)',
          _bodyFatController,
          hint: '15',
          keyboardType: const TextInputType.numberWithOptions(decimal: true),
        ),
      ],
    );
  }

  Widget _buildFitnessLevelStep() {
    return Column(
      children: [
        _buildLevelCard(
          FitnessLevel.beginner,
          'BEGINNER',
          'New to training or returning after a long break',
          Icons.fitness_center,
        ),
        const SizedBox(height: 12),
        _buildLevelCard(
          FitnessLevel.intermediate,
          'INTERMEDIATE',
          'Consistent training for 6+ months',
          Icons.trending_up,
        ),
        const SizedBox(height: 12),
        _buildLevelCard(
          FitnessLevel.advanced,
          'ADVANCED',
          'Years of consistent, intense training',
          Icons.local_fire_department,
        ),
      ],
    );
  }

  Widget _buildTrainingGoalStep() {
    return Column(
      children: [
        _buildGoalCard(TrainingGoal.mma, 'MMA', 'Mixed Martial Arts'),
        const SizedBox(height: 10),
        _buildGoalCard(TrainingGoal.boxing, 'BOXING', 'Striking & Footwork'),
        const SizedBox(height: 10),
        _buildGoalCard(TrainingGoal.muayThai, 'MUAY THAI', '8-Point Striking'),
        const SizedBox(height: 10),
        _buildGoalCard(
          TrainingGoal.wrestling,
          'WRESTLING',
          'Grappling & Takedowns',
        ),
        const SizedBox(height: 10),
        _buildGoalCard(TrainingGoal.bjj, 'BJJ', 'Brazilian Jiu-Jitsu'),
        const SizedBox(height: 10),
        _buildGoalCard(
          TrainingGoal.generalCombat,
          'COMBAT SPORTS',
          'General Conditioning',
        ),
        const SizedBox(height: 10),
        _buildGoalCard(TrainingGoal.strength, 'STRENGTH', 'Raw Power Building'),
        const SizedBox(height: 10),
        _buildGoalCard(
          TrainingGoal.conditioning,
          'CONDITIONING',
          'Endurance & Stamina',
        ),
      ],
    );
  }

  Widget _buildPreferencesStep() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'TRAINING DAYS PER WEEK',
          style: TextStyle(
            color: Colors.grey,
            fontSize: 12,
            letterSpacing: 1.5,
          ),
        ),
        const SizedBox(height: 12),
        _buildTrainingDaysSlider(),
        const SizedBox(height: 32),
        const Text(
          'WORKOUT DURATION (minutes)',
          style: TextStyle(
            color: Colors.grey,
            fontSize: 12,
            letterSpacing: 1.5,
          ),
        ),
        const SizedBox(height: 12),
        _buildDurationSlider(),
        const SizedBox(height: 32),
        _buildInjuriesInput(),
      ],
    );
  }

  Widget _buildTextInput(
    String label,
    TextEditingController controller, {
    String? hint,
    TextInputType keyboardType = TextInputType.text,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(
            color: Colors.grey,
            fontSize: 12,
            letterSpacing: 1.5,
          ),
        ),
        const SizedBox(height: 8),
        TextField(
          controller: controller,
          keyboardType: keyboardType,
          style: const TextStyle(color: Colors.white, fontSize: 18),
          decoration: InputDecoration(
            hintText: hint,
            hintStyle: TextStyle(color: Colors.grey.withValues(alpha: 0.5)),
            filled: true,
            fillColor: LaconicTheme.ironGray.withValues(alpha: 0.2),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
              borderSide: BorderSide.none,
            ),
            contentPadding: const EdgeInsets.symmetric(
              horizontal: 16,
              vertical: 16,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildGenderSelector() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'GENDER',
          style: TextStyle(
            color: Colors.grey,
            fontSize: 12,
            letterSpacing: 1.5,
          ),
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            Expanded(child: _buildGenderOption('Male', Icons.male)),
            const SizedBox(width: 12),
            Expanded(child: _buildGenderOption('Female', Icons.female)),
          ],
        ),
      ],
    );
  }

  Widget _buildGenderOption(String gender, IconData icon) {
    final isSelected = _selectedGender == gender;
    return GestureDetector(
      onTap: () => setState(() => _selectedGender = gender),
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 16),
        decoration: BoxDecoration(
          color: isSelected
              ? LaconicTheme.spartanBronze.withValues(alpha: 0.2)
              : LaconicTheme.ironGray.withValues(alpha: 0.2),
          border: Border.all(
            color: isSelected ? LaconicTheme.spartanBronze : Colors.transparent,
          ),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Column(
          children: [
            Icon(
              icon,
              color: isSelected ? LaconicTheme.spartanBronze : Colors.grey,
            ),
            const SizedBox(height: 8),
            Text(
              gender.toUpperCase(),
              style: TextStyle(
                color: isSelected ? Colors.white : Colors.grey,
                fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildLevelCard(
    FitnessLevel level,
    String title,
    String description,
    IconData icon,
  ) {
    final isSelected = _selectedLevel == level;
    return GestureDetector(
      onTap: () => setState(() => _selectedLevel = level),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: isSelected
              ? LaconicTheme.spartanBronze.withValues(alpha: 0.15)
              : LaconicTheme.ironGray.withValues(alpha: 0.1),
          border: Border.all(
            color: isSelected
                ? LaconicTheme.spartanBronze
                : LaconicTheme.ironGray.withValues(alpha: 0.3),
            width: isSelected ? 2 : 1,
          ),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Row(
          children: [
            Container(
              width: 48,
              height: 48,
              decoration: BoxDecoration(
                color: isSelected
                    ? LaconicTheme.spartanBronze.withValues(alpha: 0.3)
                    : LaconicTheme.ironGray.withValues(alpha: 0.3),
                shape: BoxShape.circle,
              ),
              child: Icon(
                icon,
                color: isSelected ? LaconicTheme.spartanBronze : Colors.grey,
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: TextStyle(
                      color: isSelected
                          ? LaconicTheme.spartanBronze
                          : Colors.white,
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      letterSpacing: 1.0,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    description,
                    style: const TextStyle(color: Colors.grey, fontSize: 12),
                  ),
                ],
              ),
            ),
            if (isSelected)
              const Icon(Icons.check_circle, color: LaconicTheme.spartanBronze),
          ],
        ),
      ),
    );
  }

  Widget _buildGoalCard(TrainingGoal goal, String title, String subtitle) {
    final isSelected = _selectedGoal == goal;
    return GestureDetector(
      onTap: () => setState(() => _selectedGoal = goal),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        decoration: BoxDecoration(
          color: isSelected
              ? LaconicTheme.spartanBronze.withValues(alpha: 0.15)
              : LaconicTheme.ironGray.withValues(alpha: 0.1),
          border: Border.all(
            color: isSelected
                ? LaconicTheme.spartanBronze
                : LaconicTheme.ironGray.withValues(alpha: 0.3),
            width: isSelected ? 2 : 1,
          ),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: TextStyle(
                      color: isSelected
                          ? LaconicTheme.spartanBronze
                          : Colors.white,
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      letterSpacing: 1.0,
                    ),
                  ),
                  Text(
                    subtitle,
                    style: const TextStyle(color: Colors.grey, fontSize: 12),
                  ),
                ],
              ),
            ),
            if (isSelected)
              const Icon(Icons.check_circle, color: LaconicTheme.spartanBronze),
          ],
        ),
      ),
    );
  }

  Widget _buildTrainingDaysSlider() {
    return Column(
      children: [
        Slider(
          value: _trainingDays.toDouble(),
          min: 2,
          max: 7,
          divisions: 5,
          activeColor: LaconicTheme.spartanBronze,
          inactiveColor: LaconicTheme.ironGray,
          label: '$_trainingDays days',
          onChanged: (value) => setState(() => _trainingDays = value.round()),
        ),
        Text(
          '$_trainingDays DAYS PER WEEK',
          style: const TextStyle(
            color: LaconicTheme.spartanBronze,
            fontWeight: FontWeight.bold,
          ),
        ),
      ],
    );
  }

  Widget _buildDurationSlider() {
    return Column(
      children: [
        Slider(
          value: _workoutDuration.toDouble(),
          min: 30,
          max: 120,
          divisions: 6,
          activeColor: LaconicTheme.spartanBronze,
          inactiveColor: LaconicTheme.ironGray,
          label: '$_workoutDuration min',
          onChanged: (value) =>
              setState(() => _workoutDuration = value.round()),
        ),
        Text(
          '$_workoutDuration MINUTES PER SESSION',
          style: const TextStyle(
            color: LaconicTheme.spartanBronze,
            fontWeight: FontWeight.bold,
          ),
        ),
      ],
    );
  }

  Widget _buildInjuriesInput() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'INJURIES OR LIMITATIONS (optional)',
          style: TextStyle(
            color: Colors.grey,
            fontSize: 12,
            letterSpacing: 1.5,
          ),
        ),
        const SizedBox(height: 12),
        TextField(
          maxLines: 3,
          style: const TextStyle(color: Colors.white),
          onChanged: (value) {
            if (value.isNotEmpty) {
              _injuries.clear();
              _injuries.addAll(value.split(',').map((e) => e.trim()));
            }
          },
          decoration: InputDecoration(
            hintText: 'e.g., shoulder injury, lower back pain',
            hintStyle: TextStyle(color: Colors.grey.withValues(alpha: 0.5)),
            filled: true,
            fillColor: LaconicTheme.ironGray.withValues(alpha: 0.2),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
              borderSide: BorderSide.none,
            ),
            contentPadding: const EdgeInsets.all(16),
          ),
        ),
      ],
    );
  }
}
