import 'combat_exercise_library.dart';
import '../models/sport_category.dart';

/// Pre-defined workout templates for various combat sports training scenarios
class WorkoutTemplates {
  /// MMA Conditioning - 45 min high intensity
  static List<CombatExercise> get mmaConditioning => [
    CombatExerciseLibrary.getById('mma_001')!,
    CombatExerciseLibrary.getById('mma_005')!,
    CombatExerciseLibrary.getById('mma_010')!,
    CombatExerciseLibrary.getById('mma_015')!,
    CombatExerciseLibrary.getById('mma_020')!,
    CombatExerciseLibrary.getById('gc_016')!,
    CombatExerciseLibrary.getById('fs_001')!,
    CombatExerciseLibrary.getById('fc_005')!,
  ];

  /// Boxing Power - Focus on striking power
  static List<CombatExercise> get boxingPower => [
    CombatExerciseLibrary.getById('box_001')!,
    CombatExerciseLibrary.getById('box_005')!,
    CombatExerciseLibrary.getById('box_010')!,
    CombatExerciseLibrary.getById('box_015')!,
    CombatExerciseLibrary.getById('fp_001')!,
    CombatExerciseLibrary.getById('fp_005')!,
    CombatExerciseLibrary.getById('fp_010')!,
    CombatExerciseLibrary.getById('fs_005')!,
  ];

  /// Muay Thai Endurance - Cardio focused
  static List<CombatExercise> get muayThaiEndurance => [
    CombatExerciseLibrary.getById('mt_001')!,
    CombatExerciseLibrary.getById('mt_005')!,
    CombatExerciseLibrary.getById('mt_010')!,
    CombatExerciseLibrary.getById('fe_001')!,
    CombatExerciseLibrary.getById('fe_005')!,
    CombatExerciseLibrary.getById('fe_010')!,
    CombatExerciseLibrary.getById('fc_010')!,
  ];

  /// Wrestling Strength - Grappling power
  static List<CombatExercise> get wrestlingStrength => [
    CombatExerciseLibrary.getById('wres_001')!,
    CombatExerciseLibrary.getById('wres_005')!,
    CombatExerciseLibrary.getById('wres_010')!,
    CombatExerciseLibrary.getById('fs_010')!,
    CombatExerciseLibrary.getById('fs_015')!,
    CombatExerciseLibrary.getById('fc_015')!,
    CombatExerciseLibrary.getById('gc_010')!,
  ];

  /// BJJ Technique - Ground work focus
  static List<CombatExercise> get bjjTechnique => [
    CombatExerciseLibrary.getById('bjj_001')!,
    CombatExerciseLibrary.getById('bjj_005')!,
    CombatExerciseLibrary.getById('bjj_010')!,
    CombatExerciseLibrary.getById('bjj_015')!,
    CombatExerciseLibrary.getById('mob_005')!,
    CombatExerciseLibrary.getById('mob_010')!,
  ];

  /// Judo/Sambo Throws - Throwing techniques
  static List<CombatExercise> get judoThrows => [
    CombatExerciseLibrary.getById('judo_001')!,
    CombatExerciseLibrary.getById('judo_005')!,
    CombatExerciseLibrary.getById('sambo_001')!,
    CombatExerciseLibrary.getById('sambo_005')!,
    CombatExerciseLibrary.getById('fs_020')!,
    CombatExerciseLibrary.getById('fp_015')!,
  ];

  /// Kickboxing Agility - Speed and movement
  static List<CombatExercise> get kickboxingAgility => [
    CombatExerciseLibrary.getById('kb_001')!,
    CombatExerciseLibrary.getById('kb_005')!,
    CombatExerciseLibrary.getById('kb_010')!,
    CombatExerciseLibrary.getById('kb_015')!,
    CombatExerciseLibrary.getById('fc_020')!,
    CombatExerciseLibrary.getById('mob_001')!,
    CombatExerciseLibrary.getById('mob_015')!,
  ];

  /// Fight Strength - Pure strength building
  static List<CombatExercise> get fightStrength => [
    CombatExerciseLibrary.getById('fs_001')!,
    CombatExerciseLibrary.getById('fs_005')!,
    CombatExerciseLibrary.getById('fs_010')!,
    CombatExerciseLibrary.getById('fs_015')!,
    CombatExerciseLibrary.getById('fs_020')!,
    CombatExerciseLibrary.getById('gc_015')!,
    CombatExerciseLibrary.getById('gc_016')!,
  ];

  /// Fight Conditioning - Metabolic conditioning
  static List<CombatExercise> get fightConditioning => [
    CombatExerciseLibrary.getById('fc_001')!,
    CombatExerciseLibrary.getById('fc_005')!,
    CombatExerciseLibrary.getById('fc_010')!,
    CombatExerciseLibrary.getById('fc_015')!,
    CombatExerciseLibrary.getById('fc_020')!,
    CombatExerciseLibrary.getById('fe_005')!,
    CombatExerciseLibrary.getById('fe_010')!,
  ];

  /// Mobility & Recovery - Active recovery
  static List<CombatExercise> get mobilityRecovery => [
    CombatExerciseLibrary.getById('mob_001')!,
    CombatExerciseLibrary.getById('mob_005')!,
    CombatExerciseLibrary.getById('mob_010')!,
    CombatExerciseLibrary.getById('mob_015')!,
    CombatExerciseLibrary.getById('mob_020')!,
    CombatExerciseLibrary.getById('breath_001')!,
  ];

  /// Taekwondo Tricking - Advanced kicking
  static List<CombatExercise> get taekwondoTricking => [
    CombatExerciseLibrary.getById('tkd_001')!,
    CombatExerciseLibrary.getById('tkd_002')!,
    CombatExerciseLibrary.getById('tkd_003')!,
    CombatExerciseLibrary.getById('tkd_004')!,
    CombatExerciseLibrary.getById('tkd_005')!,
    CombatExerciseLibrary.getById('kb_014')!,
    CombatExerciseLibrary.getById('kb_015')!,
  ];

  /// General Combat - All-around workout
  static List<CombatExercise> get generalCombat => [
    CombatExerciseLibrary.getById('gc_001')!,
    CombatExerciseLibrary.getById('gc_005')!,
    CombatExerciseLibrary.getById('gc_010')!,
    CombatExerciseLibrary.getById('gc_015')!,
    CombatExerciseLibrary.getById('mma_001')!,
    CombatExerciseLibrary.getById('box_001')!,
    CombatExerciseLibrary.getById('mt_001')!,
    CombatExerciseLibrary.getById('wres_001')!,
  ];

  /// Get template by sport category
  static List<CombatExercise> bySport(SportCategory sport) {
    switch (sport) {
      case SportCategory.mma:
        return mmaConditioning;
      case SportCategory.boxing:
        return boxingPower;
      case SportCategory.muayThai:
        return muayThaiEndurance;
      case SportCategory.wrestling:
        return wrestlingStrength;
      case SportCategory.bjj:
        return bjjTechnique;
      case SportCategory.judo:
      case SportCategory.sambo:
        return judoThrows;
      case SportCategory.kickboxing:
        return kickboxingAgility;
      case SportCategory.taekwondo:
        return taekwondoTricking;
      case SportCategory.fightStrength:
        return fightStrength;
      case SportCategory.fightConditioning:
        return fightConditioning;
      case SportCategory.fightPower:
        return [...boxingPower, ...fightStrength];
      case SportCategory.fightEndurance:
        return muayThaiEndurance;
      case SportCategory.generalCombat:
        return generalCombat;
      default:
        return generalCombat;
    }
  }

  /// Get all available templates
  static Map<String, List<CombatExercise>> get allTemplates => {
    'MMA Conditioning': mmaConditioning,
    'Boxing Power': boxingPower,
    'Muay Thai Endurance': muayThaiEndurance,
    'Wrestling Strength': wrestlingStrength,
    'BJJ Technique': bjjTechnique,
    'Judo/Sambo Throws': judoThrows,
    'Kickboxing Agility': kickboxingAgility,
    'Fight Strength': fightStrength,
    'Fight Conditioning': fightConditioning,
    'Mobility & Recovery': mobilityRecovery,
    'Taekwondo Tricking': taekwondoTricking,
    'General Combat': generalCombat,
  };
}
