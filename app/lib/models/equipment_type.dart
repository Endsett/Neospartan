/// Equipment types available for exercises
enum EquipmentType {
  // Free Weights
  barbell('Barbell', EquipmentGroup.freeWeights),
  dumbbell('Dumbbell', EquipmentGroup.freeWeights),
  kettlebell('Kettlebell', EquipmentGroup.freeWeights),
  ezBar('EZ-Bar', EquipmentGroup.freeWeights),
  trapBar('Trap Bar', EquipmentGroup.freeWeights),
  
  // Bodyweight/Calisthenics
  bodyweight('Bodyweight', EquipmentGroup.bodyweight),
  pullUpBar('Pull-up Bar', EquipmentGroup.bodyweight),
  dipStation('Dip Station', EquipmentGroup.bodyweight),
  parallettes('Parallettes', EquipmentGroup.bodyweight),
  rings('Gymnastic Rings', EquipmentGroup.bodyweight),
  
  // Machines
  squatRack('Squat Rack', EquipmentGroup.machines),
  bench('Bench Press', EquipmentGroup.machines),
  cableMachine('Cable Machine', EquipmentGroup.machines),
  smithMachine('Smith Machine', EquipmentGroup.machines),
  legPress('Leg Press', EquipmentGroup.machines),
  legExtension('Leg Extension', EquipmentGroup.machines),
  legCurl('Leg Curl', EquipmentGroup.machines),
  latPulldown('Lat Pulldown', EquipmentGroup.machines),
  rowMachine('Row Machine', EquipmentGroup.machines),
  chestPress('Chest Press Machine', EquipmentGroup.machines),
  shoulderPress('Shoulder Press Machine', EquipmentGroup.machines),
  calfRaise('Calf Raise Machine', EquipmentGroup.machines),
  hackSquat('Hack Squat', EquipmentGroup.machines),
  
  // Cardio/Conditioning
  treadmill('Treadmill', EquipmentGroup.conditioning),
  exerciseBike('Exercise Bike', EquipmentGroup.conditioning),
  rowingErg('Rowing Ergometer', EquipmentGroup.conditioning),
  assaultBike('Assault Bike', EquipmentGroup.conditioning),
  skiErg('Ski Ergometer', EquipmentGroup.conditioning),
  stairClimber('Stair Climber', EquipmentGroup.conditioning),
  jumpRope('Jump Rope', EquipmentGroup.conditioning),
  
  // Plyometric/Agility
  plyoBox('Plyo Box', EquipmentGroup.plyometric),
  agilityLadder('Agility Ladder', EquipmentGroup.plyometric),
  cones('Cones', EquipmentGroup.plyometric),
  hurdles('Hurdles', EquipmentGroup.plyometric),
  rebounder('Rebounder/Mini Trampoline', EquipmentGroup.plyometric),
  
  // Combat Training
  heavyBag('Heavy Bag', EquipmentGroup.combat),
  speedBag('Speed Bag', EquipmentGroup.combat),
  doubleEndBag('Double-End Bag', EquipmentGroup.combat),
  thaiPads('Thai Pads', EquipmentGroup.combat),
  focusMitts('Focus Mitts', EquipmentGroup.combat),
  grapplingDummy('Grappling Dummy', EquipmentGroup.combat),
  resistanceBands('Resistance Bands', EquipmentGroup.combat),
  battleRopes('Battle Ropes', EquipmentGroup.combat),
  sledgehammer('Sledgehammer', EquipmentGroup.combat),
  tire('Tire (for flipping)', EquipmentGroup.combat),
  prowler('Prowler/Sled', EquipmentGroup.combat),
  
  // Sport Specific
  basketball('Basketball', EquipmentGroup.sportSpecific),
  medicineBall('Medicine Ball', EquipmentGroup.sportSpecific),
  slamBall('Slam Ball', EquipmentGroup.sportSpecific),
  wallBall('Wall Ball', EquipmentGroup.sportSpecific),
  trapBarDeadlift('Trap Bar', EquipmentGroup.sportSpecific),
  landmine('Landmine', EquipmentGroup.sportSpecific),
  gluteHam('Glute-Ham Developer', EquipmentGroup.sportSpecific),
  reverseHyper('Reverse Hyperextension', EquipmentGroup.sportSpecific),
  
  // Mobility/Recovery
  foamRoller('Foam Roller', EquipmentGroup.mobility),
  lacrosseBall('Lacrosse Ball', EquipmentGroup.mobility),
  resistanceBand('Resistance Band', EquipmentGroup.mobility),
  yogaMat('Yoga Mat', EquipmentGroup.mobility),
  yogaBlock('Yoga Block', EquipmentGroup.mobility),
  yogaStrap('Yoga Strap', EquipmentGroup.mobility),
  massageGun('Massage Gun', EquipmentGroup.mobility),
  
  // Accessories
  weightVest('Weight Vest', EquipmentGroup.accessories),
  weightBelt('Weight Belt', EquipmentGroup.accessories),
  wristWraps('Wrist Wraps', EquipmentGroup.accessories),
  liftingStraps('Lifting Straps', EquipmentGroup.accessories),
  chalk('Chalk', EquipmentGroup.accessories),
  timer('Timer', EquipmentGroup.accessories),
  heartRateMonitor('Heart Rate Monitor', EquipmentGroup.accessories);

  final String displayName;
  final EquipmentGroup group;

  const EquipmentType(this.displayName, this.group);

  /// Get all equipment in a specific group
  static List<EquipmentType> byGroup(EquipmentGroup group) {
    return values.where((e) => e.group == group).toList();
  }

  /// Equipment required for different training locations
  static List<EquipmentType> get homeGymEssentials => [
    bodyweight, dumbbell, kettlebell, pullUpBar, resistanceBands,
    jumpRope, yogaMat, foamRoller,
  ];

  static List<EquipmentType> get commercialGym => [
    barbell, dumbbell, squatRack, bench, cableMachine,
    legPress, latPulldown, rowMachine, chestPress,
    treadmill, exerciseBike, rowingErg,
  ];

  static List<EquipmentType> get outdoorTraining => [
    bodyweight, pullUpBar, jumpRope, cones, plyoBox,
    resistanceBands, medicineBall,
  ];

  static List<EquipmentType> get combatGym => [
    heavyBag, speedBag, thaiPads, focusMitts, battleRopes,
    resistanceBands, medicineBall, sledgehammer,
  ];

  /// Check if this equipment requires a partner
  bool get requiresPartner {
    return group == EquipmentGroup.combat && 
      [thaiPads, focusMitts].contains(this);
  }

  /// Check if this is bodyweight only
  bool get isBodyweight => group == EquipmentGroup.bodyweight;

  /// Check if this requires gym access
  bool get requiresGym => group == EquipmentGroup.machines;
}

/// Equipment groups for organization
enum EquipmentGroup {
  freeWeights,
  bodyweight,
  machines,
  conditioning,
  plyometric,
  combat,
  sportSpecific,
  mobility,
  accessories,
}

/// Equipment requirements for a workout
class EquipmentRequirements {
  final List<EquipmentType> required;
  final List<EquipmentType> optional;
  final List<EquipmentType> alternatives;

  const EquipmentRequirements({
    this.required = const [],
    this.optional = const [],
    this.alternatives = const [],
  });

  /// Check if user has all required equipment
  bool canPerform(List<EquipmentType> available) {
    return required.every((e) => available.contains(e) || 
      alternatives.any((alt) => available.contains(alt)));
  }

  /// Get missing equipment
  List<EquipmentType> getMissing(List<EquipmentType> available) {
    return required.where((e) => 
      !available.contains(e) && 
      !alternatives.any((alt) => available.contains(alt))
    ).toList();
  }

  Map<String, dynamic> toMap() {
    return {
      'required': required.map((e) => e.name).toList(),
      'optional': optional.map((e) => e.name).toList(),
      'alternatives': alternatives.map((e) => e.name).toList(),
    };
  }

  factory EquipmentRequirements.fromMap(Map<String, dynamic> map) {
    return EquipmentRequirements(
      required: (map['required'] as List<dynamic>?)
          ?.map((e) => EquipmentType.values.firstWhere(
            (type) => type.name == e,
            orElse: () => EquipmentType.bodyweight,
          ))
          .toList() ?? [],
      optional: (map['optional'] as List<dynamic>?)
          ?.map((e) => EquipmentType.values.firstWhere(
            (type) => type.name == e,
            orElse: () => EquipmentType.bodyweight,
          ))
          .toList() ?? [],
      alternatives: (map['alternatives'] as List<dynamic>?)
          ?.map((e) => EquipmentType.values.firstWhere(
            (type) => type.name == e,
            orElse: () => EquipmentType.bodyweight,
          ))
          .toList() ?? [],
    );
  }
}
