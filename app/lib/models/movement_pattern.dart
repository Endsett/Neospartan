/// Movement patterns for exercise classification
/// Based on fundamental human movements used in combat sports
enum MovementPattern {
  // Lower Body Patterns
  squat('Squat', 'Bilateral lower body push', BodyRegion.lower),
  lunge('Lunge', 'Unilateral lower body movement', BodyRegion.lower),
  hinge('Hinge', 'Hip dominant posterior chain', BodyRegion.lower),
  stepUp('Step Up', 'Vertical stepping pattern', BodyRegion.lower),
  singleLegRdl('Single Leg RDL', 'Unilateral hip hinge', BodyRegion.lower),
  calfRaise('Calf Raise', 'Ankle plantarflexion', BodyRegion.lower),

  // Upper Body Push Patterns
  horizontalPush(
    'Horizontal Push',
    'Pressing away from body (bench/ pushup)',
    BodyRegion.upper,
  ),
  verticalPush('Vertical Push', 'Pressing overhead', BodyRegion.upper),
  dip('Dip', 'Vertical pushing with bodyweight', BodyRegion.upper),

  // Upper Body Pull Patterns
  horizontalPull('Horizontal Pull', 'Rowing toward body', BodyRegion.upper),
  verticalPull('Vertical Pull', 'Pulling from overhead', BodyRegion.upper),
  facePull(
    'Face Pull',
    'Scapular retraction with external rotation',
    BodyRegion.upper,
  ),

  // Core/Trunk Patterns
  antiExtension('Anti-Extension', 'Resisting trunk extension', BodyRegion.core),
  antiRotation('Anti-Rotation', 'Resisting trunk rotation', BodyRegion.core),
  antiLateralFlexion(
    'Anti-Lateral Flexion',
    'Resisting side bending',
    BodyRegion.core,
  ),
  rotation('Rotation', 'Controlled trunk rotation', BodyRegion.core),
  extension('Extension', 'Trunk/arch extension', BodyRegion.core),
  flexion('Flexion', 'Trunk/crunch flexion', BodyRegion.core),

  // Locomotion Patterns
  gait('Gait', 'Walking/running pattern', BodyRegion.full),
  crawl('Crawl', 'Quadruped locomotion', BodyRegion.full),
  carry('Carry', 'Loaded locomotion', BodyRegion.full),

  // Explosive Patterns
  jump('Jump', 'Vertical or horizontal takeoff', BodyRegion.lower),
  land('Land', 'Force absorption', BodyRegion.lower),
  medicineBallThrow(
    'Medicine Ball Throw',
    'Ballistic upper body extension',
    BodyRegion.full,
  ),
  slam('Slam', 'Overhead ballistic pattern', BodyRegion.full),

  // Isometric Patterns
  hold('Hold', 'Static position maintenance', BodyRegion.varies),
  hang('Hang', 'Suspension from overhead', BodyRegion.upper),
  wallSit('Wall Sit', 'Static squat position', BodyRegion.lower),
  plank('Plank', 'Prone bridge position', BodyRegion.core),
  balance('Balance', 'Equilibrium and stability control', BodyRegion.varies),
  pressure('Pressure', 'Top control weight distribution', BodyRegion.full),

  // Sport-Specific Patterns
  punch('Punch', 'Striking with upper extremity', BodyRegion.full),
  kick('Kick', 'Striking with lower extremity', BodyRegion.full),
  knee('Knee', 'Close-range striking', BodyRegion.full),
  elbow('Elbow', 'Short-range striking', BodyRegion.full),
  sprawl('Sprawl', 'Takedown defense', BodyRegion.full),
  shoot('Shoot', 'Penetration step for takedown', BodyRegion.lower),
  clinchDrive('Clinch Drive', 'Forward pressure in clinch', BodyRegion.full),
  pummel('Pummel', 'Inside arm fighting', BodyRegion.upper),
  bridge('Bridge', 'Hip extension from supine', BodyRegion.core),
  shrimp('Shrimp', 'Hip escape pattern', BodyRegion.core),
  technicalStandUp(
    'Technical Stand Up',
    'Ground to standing transition',
    BodyRegion.full,
  ),
  roll('Roll', 'Ground-based rotation', BodyRegion.full),
  granby('Granby', 'Inverted shoulder roll', BodyRegion.full),
  inversion('Inversion', 'Handstand or inverted position', BodyRegion.full),
  trip('Trip', 'Leg trip for takedown', BodyRegion.lower),
  lift('Lift', 'Lifting opponent for throw', BodyRegion.full),
  hipEscape('Hip Escape', 'Hip escape to guard or stand', BodyRegion.core),

  // Grappling-Specific
  grip('Grip', 'Hand/forearm isometric', BodyRegion.upper),
  pull('Pull', 'Toward body (clinch/grappling)', BodyRegion.upper),
  post('Post', 'Frame creation and maintenance', BodyRegion.varies),

  // Multi-joint Compound
  clean('Clean', 'Explosive pull from floor to shoulders', BodyRegion.full),
  snatch('Snatch', 'Explosive pull from floor to overhead', BodyRegion.full),
  muscleUp('Muscle Up', 'Pull to dip transition', BodyRegion.upper),
  burpee('Burpee', 'Ground to standing to ground', BodyRegion.full),
  turkishGetUp(
    'Turkish Get Up',
    'Ground to standing with load',
    BodyRegion.full,
  ),

  // Mobility Patterns
  hipMobility('Hip Mobility', 'Hip range of motion work', BodyRegion.lower),
  shoulderMobility(
    'Shoulder Mobility',
    'Shoulder range of motion',
    BodyRegion.upper,
  ),
  thoracicMobility(
    'Thoracic Mobility',
    'Mid-back range of motion',
    BodyRegion.core,
  ),
  ankleMobility('Ankle Mobility', 'Ankle range of motion', BodyRegion.lower),
  wristMobility('Wrist Mobility', 'Wrist range of motion', BodyRegion.upper),
  neckMobility('Neck Mobility', 'Neck range of motion', BodyRegion.core),

  // Cardio/Conditioning
  sprint('Sprint', 'Maximal speed effort', BodyRegion.lower),
  shuttle('Shuttle', 'Change of direction running', BodyRegion.lower),
  bike('Bike', 'Cycling ergometer', BodyRegion.lower),
  row('Row', 'Rowing ergometer', BodyRegion.full),
  ski('Ski', 'Ski ergometer', BodyRegion.full),
  rope('Rope', 'Rope climbing or undulation', BodyRegion.full),

  // Full Body
  totalBody('Total Body', 'Engages all major regions', BodyRegion.full),
  none('None', 'No specific pattern', BodyRegion.none);

  final String displayName;
  final String description;
  final BodyRegion primaryRegion;

  const MovementPattern(this.displayName, this.description, this.primaryRegion);

  /// Get patterns by body region
  static List<MovementPattern> byRegion(BodyRegion region) {
    return values.where((p) => p.primaryRegion == region).toList();
  }

  /// Get fundamental movement patterns
  static List<MovementPattern> get fundamentalPatterns => [
    squat,
    hinge,
    lunge,
    horizontalPush,
    horizontalPull,
    verticalPush,
    verticalPull,
    antiExtension,
    rotation,
    gait,
  ];

  /// Get sport-specific patterns for combat sports
  static List<MovementPattern> get combatSportPatterns => [
    punch,
    kick,
    knee,
    elbow,
    sprawl,
    shoot,
    clinchDrive,
    pummel,
    bridge,
    shrimp,
    technicalStandUp,
    roll,
    granby,
    grip,
    pull,
    post,
  ];

  /// Get explosive patterns
  static List<MovementPattern> get explosivePatterns => [
    jump,
    land,
    medicineBallThrow,
    slam,
    clean,
    snatch,
  ];

  /// Get isometric patterns
  static List<MovementPattern> get isometricPatterns => [
    hold,
    hang,
    wallSit,
    plank,
    grip,
  ];

  /// Check if this is a ground-based pattern
  bool get isGroundBased => [
    bridge,
    shrimp,
    technicalStandUp,
    roll,
    granby,
    burpee,
    turkishGetUp,
  ].contains(this);

  /// Check if this is a striking pattern
  bool get isStriking => [punch, kick, knee, elbow].contains(this);

  /// Check if this is a grappling pattern
  bool get isGrappling => [
    sprawl,
    shoot,
    clinchDrive,
    pummel,
    bridge,
    shrimp,
    technicalStandUp,
    roll,
    granby,
    grip,
    pull,
    post,
  ].contains(this);

  /// Get primary muscles targeted by this movement pattern
  List<String> get primaryMuscles {
    switch (this) {
      case MovementPattern.squat:
        return ['quads', 'glutes'];
      case MovementPattern.lunge:
        return ['quads', 'glutes', 'hamstrings'];
      case MovementPattern.hinge:
      case MovementPattern.singleLegRdl:
        return ['hamstrings', 'glutes', 'lower_back'];
      case MovementPattern.stepUp:
        return ['quads', 'glutes'];
      case MovementPattern.calfRaise:
        return ['calves'];
      case MovementPattern.horizontalPush:
      case MovementPattern.dip:
        return ['chest', 'triceps', 'front_delts'];
      case MovementPattern.verticalPush:
        return ['shoulders', 'triceps', 'traps'];
      case MovementPattern.horizontalPull:
        return ['lats', 'rhomboids', 'biceps'];
      case MovementPattern.verticalPull:
        return ['lats', 'biceps', 'teres_major'];
      case MovementPattern.facePull:
        return ['rear_delts', 'rhomboids', 'rotator_cuff'];
      case MovementPattern.antiExtension:
      case MovementPattern.flexion:
        return ['abs', 'hip_flexors'];
      case MovementPattern.antiRotation:
      case MovementPattern.rotation:
        return ['obliques', 'transverse_abdominis'];
      case MovementPattern.antiLateralFlexion:
        return ['quadratus_lumborum', 'obliques'];
      case MovementPattern.extension:
      case MovementPattern.bridge:
        return ['lower_back', 'glutes', 'hamstrings'];
      case MovementPattern.plank:
        return ['abs', 'shoulders', 'glutes'];
      case MovementPattern.punch:
      case MovementPattern.elbow:
        return ['chest', 'shoulders', 'triceps', 'core'];
      case MovementPattern.kick:
      case MovementPattern.knee:
        return ['hip_flexors', 'glutes', 'quads', 'core'];
      case MovementPattern.sprawl:
      case MovementPattern.shoot:
      case MovementPattern.shrimp:
      case MovementPattern.granby:
        return ['hips', 'core', 'shoulders'];
      case MovementPattern.clinchDrive:
      case MovementPattern.pummel:
      case MovementPattern.grip:
      case MovementPattern.pull:
        return ['upper_back', 'biceps', 'forearms'];
      case MovementPattern.gait:
      case MovementPattern.carry:
      case MovementPattern.sprint:
        return ['full_body'];
      case MovementPattern.crawl:
        return ['core', 'shoulders', 'hips'];
      case MovementPattern.jump:
      case MovementPattern.land:
      case MovementPattern.clean:
      case MovementPattern.snatch:
        return ['full_body', 'posterior_chain'];
      case MovementPattern.slam:
      case MovementPattern.medicineBallThrow:
        return ['core', 'shoulders', 'hips'];
      case MovementPattern.muscleUp:
        return ['lats', 'chest', 'triceps'];
      case MovementPattern.burpee:
      case MovementPattern.turkishGetUp:
        return ['full_body'];
      case MovementPattern.hipMobility:
        return ['hips', 'adductors'];
      case MovementPattern.shoulderMobility:
        return ['shoulders', 'rotator_cuff'];
      case MovementPattern.thoracicMobility:
        return ['spine', 'mid_back'];
      case MovementPattern.ankleMobility:
        return ['ankles', 'calves'];
      case MovementPattern.wristMobility:
        return ['wrists', 'forearms'];
      case MovementPattern.neckMobility:
        return ['neck'];
      default:
        return ['full_body'];
    }
  }
}

/// Body regions for movement classification
enum BodyRegion {
  upper('Upper Body'),
  lower('Lower Body'),
  core('Core/Trunk'),
  full('Full Body'),
  varies('Varies'),
  none('None');

  final String displayName;
  const BodyRegion(this.displayName);
}
