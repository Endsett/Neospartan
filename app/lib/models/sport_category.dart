/// Combat-focused sport categories for the workout library
enum SportCategory {
  // Combat Sports
  mma(
    'MMA',
    'Mixed Martial Arts',
    'Full-contact combat combining striking and grappling',
  ),
  boxing('Boxing', 'Boxing', 'Striking sport focusing on punches and footwork'),
  muayThai(
    'Muay Thai',
    'Muay Thai',
    'Thai striking with kicks, knees, elbows, and clinch',
  ),
  wrestling(
    'Wrestling',
    'Wrestling',
    'Grappling focused on takedowns and control',
  ),
  bjj('BJJ', 'Brazilian Jiu-Jitsu', 'Ground-based grappling with submissions'),
  judo('Judo', 'Judo', 'Throws and grappling with gi emphasis'),
  kickboxing(
    'Kickboxing',
    'Kickboxing',
    'Stand-up striking with kicks and punches',
  ),
  sambo('Sambo', 'Sambo', 'Russian grappling with leg locks and throws'),
  karate('Karate', 'Karate', 'Striking with linear movements and kata'),
  taekwondo('Taekwondo', 'Taekwondo', 'Korean striking with emphasis on kicks'),

  // Combat Conditioning
  generalCombat(
    'General Combat',
    'General Combat Fitness',
    'Non-specific combat conditioning',
  ),
  striking('Striking', 'Striking Arts', 'Punch and kick focused training'),
  grappling('Grappling', 'Grappling Arts', 'Wrestling and ground fighting'),
  clinch('Clinch', 'Clinch Work', 'Close-range striking and control'),

  // Strength & Conditioning for Fighters
  fightStrength(
    'Fight Strength',
    'Fight Strength',
    'Maximal strength for combat sports',
  ),
  fightConditioning(
    'Fight Conditioning',
    'Fight Conditioning',
    'Work capacity for combat sports',
  ),
  fightPower('Fight Power', 'Fight Power', 'Explosive power for combat sports'),
  fightEndurance(
    'Fight Endurance',
    'Fight Endurance',
    'Aerobic/anaerobic capacity for fighting',
  ),

  // General
  strength('Strength', 'Pure Strength', 'Pure strength and power development'),
  conditioning(
    'Conditioning',
    'Pure Conditioning',
    'Cardiovascular and work capacity',
  ),
  general('General', 'General Fitness', 'Non-specific fitness training');

  final String shortName;
  final String displayName;
  final String description;

  const SportCategory(this.shortName, this.displayName, this.description);

  /// Get sport categories by group
  static List<SportCategory> get combatSports => [
    mma,
    boxing,
    muayThai,
    wrestling,
    bjj,
    judo,
    kickboxing,
    sambo,
    karate,
    taekwondo,
    striking,
    grappling,
    clinch,
    generalCombat,
  ];

  static List<SportCategory> get fightConditioningCategories => [
    fightStrength,
    fightConditioning,
    fightPower,
    fightEndurance,
  ];

  static List<SportCategory> get generalCategories => [
    strength,
    conditioning,
    general,
  ];

  /// Get primary training focus for this sport
  TrainingFocus get primaryFocus {
    switch (this) {
      case SportCategory.mma:
        return TrainingFocus.mmaSpecific;
      case SportCategory.boxing:
        return TrainingFocus.boxingSpecific;
      case SportCategory.muayThai:
        return TrainingFocus.muayThaiSpecific;
      case SportCategory.wrestling:
        return TrainingFocus.wrestlingSpecific;
      case SportCategory.bjj:
        return TrainingFocus.bjjSpecific;
      case SportCategory.judo:
        return TrainingFocus.judoSpecific;
      case SportCategory.kickboxing:
        return TrainingFocus.kickboxingSpecific;
      case SportCategory.sambo:
        return TrainingFocus.samboSpecific;
      case SportCategory.karate:
        return TrainingFocus.karateSpecific;
      case SportCategory.taekwondo:
        return TrainingFocus.taekwondoSpecific;
      case SportCategory.striking:
        return TrainingFocus.strikingPower;
      case SportCategory.grappling:
        return TrainingFocus.grapplingStrength;
      case SportCategory.clinch:
        return TrainingFocus.clinchStrength;
      case SportCategory.generalCombat:
        return TrainingFocus.powerEndurance;
      case SportCategory.fightStrength:
        return TrainingFocus.maximalStrength;
      case SportCategory.fightConditioning:
        return TrainingFocus.workCapacity;
      case SportCategory.fightPower:
        return TrainingFocus.explosivePower;
      case SportCategory.fightEndurance:
        return TrainingFocus.aerobicCapacity;
      case SportCategory.strength:
        return TrainingFocus.maximalStrength;
      case SportCategory.conditioning:
        return TrainingFocus.aerobicCapacity;
      case SportCategory.general:
        return TrainingFocus.generalFitness;
    }
  }

  /// Get recommended exercise categories for this sport
  List<ExerciseCategory> get recommendedExerciseCategories {
    switch (this) {
      case SportCategory.mma:
      case SportCategory.boxing:
      case SportCategory.muayThai:
      case SportCategory.kickboxing:
      case SportCategory.karate:
      case SportCategory.taekwondo:
      case SportCategory.striking:
        return [
          ExerciseCategory.combat,
          ExerciseCategory.plyometric,
          ExerciseCategory.strength,
          ExerciseCategory.sprint,
          ExerciseCategory.isometric,
        ];
      case SportCategory.wrestling:
      case SportCategory.bjj:
      case SportCategory.judo:
      case SportCategory.sambo:
      case SportCategory.grappling:
        return [
          ExerciseCategory.combat,
          ExerciseCategory.isometric,
          ExerciseCategory.strength,
          ExerciseCategory.mobility,
          ExerciseCategory.plyometric,
        ];
      case SportCategory.clinch:
        return [
          ExerciseCategory.combat,
          ExerciseCategory.isometric,
          ExerciseCategory.plyometric,
          ExerciseCategory.mobility,
        ];
      case SportCategory.generalCombat:
        return [
          ExerciseCategory.combat,
          ExerciseCategory.plyometric,
          ExerciseCategory.strength,
          ExerciseCategory.sprint,
          ExerciseCategory.isometric,
          ExerciseCategory.mobility,
        ];
      case SportCategory.fightStrength:
        return [
          ExerciseCategory.strength,
          ExerciseCategory.isometric,
          ExerciseCategory.plyometric,
        ];
      case SportCategory.fightConditioning:
        return [
          ExerciseCategory.sprint,
          ExerciseCategory.plyometric,
          ExerciseCategory.combat,
        ];
      case SportCategory.fightPower:
        return [
          ExerciseCategory.plyometric,
          ExerciseCategory.strength,
          ExerciseCategory.sprint,
        ];
      case SportCategory.fightEndurance:
        return [
          ExerciseCategory.sprint,
          ExerciseCategory.isometric,
          ExerciseCategory.combat,
        ];
      case SportCategory.strength:
        return [ExerciseCategory.strength, ExerciseCategory.isometric];
      case SportCategory.conditioning:
        return [ExerciseCategory.sprint, ExerciseCategory.plyometric];
      case SportCategory.general:
        return [
          ExerciseCategory.strength,
          ExerciseCategory.plyometric,
          ExerciseCategory.mobility,
        ];
    }
  }
}

/// Primary training focus areas for combat sports
enum TrainingFocus {
  // Sport Specific
  mmaSpecific,
  boxingSpecific,
  muayThaiSpecific,
  wrestlingSpecific,
  bjjSpecific,
  judoSpecific,
  kickboxingSpecific,
  samboSpecific,
  karateSpecific,
  taekwondoSpecific,

  // Physical Qualities
  maximalStrength,
  explosivePower,
  powerEndurance,
  aerobicCapacity,
  anaerobicCapacity,
  hypertrophy,
  relativeStrength,
  workCapacity,
  grapplingStrength,
  clinchStrength,
  strikingPower,
  rotationalPower,
  agility,
  speed,
  mobility,
  recovery,
  generalFitness,
}

/// Exercise categories for movement classification
enum ExerciseCategory {
  plyometric,
  isometric,
  combat,
  strength,
  mobility,
  sprint,
  technique,
}
