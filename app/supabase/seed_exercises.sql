-- Seed exercises table with core NeoSpartan exercise library
-- This migration populates the exercises table with the hardcoded exercises from the Flutter app

INSERT INTO exercises (
  id, name, category, youtube_id, target_metaphor, instructions, 
  intensity_level, primary_muscles, joint_stress, ideal_goals, 
  min_fitness_level, max_fitness_level, workout_tags
) VALUES 
-- PLYOMETRIC - Explosive Power
(
  'ex_001', 'LEONIDAS LUNGES', 'strength', 'QOVaHwknd2w', 'The Shield of Archidamus',
  'Weighted lunges with a vertical posture. Keep your core tight like a phalanx.',
  7, ARRAY['quads', 'glutes', 'hamstrings'],
  '{"knees": 6, "hips": 5}'::jsonb,
  ARRAY['strength', 'generalCombat'],
  'beginner', 'advanced',
  ARRAY['strength', 'legs', 'compound']
),
(
  'ex_002', 'PHALANX PUSH-UPS', 'plyometric', 'IODxDxX7oi4', 'Unbreakable Wall',
  'Explosive push-ups with a narrow hand placement.',
  8, ARRAY['chest', 'triceps', 'shoulders'],
  '{"wrists": 6, "shoulders": 7, "elbows": 5}'::jsonb,
  ARRAY['strength', 'generalCombat', 'mma'],
  'intermediate', 'elite',
  ARRAY['plyometric', 'upper_body', 'explosive']
),
(
  'ex_003', 'STOIC PLANK', 'isometric', 'pSHjTRCQxIw', 'The Pillars of Hercules',
  'Low plank held with absolute stillness. Focus on the breath.',
  6, ARRAY['core', 'shoulders'],
  '{"shoulders": 4, "lower_back": 5}'::jsonb,
  ARRAY['generalCombat', 'conditioning'],
  'beginner', 'advanced',
  ARRAY['core', 'isometric', 'endurance']
),
(
  'ex_004', 'STADION SPRINTS', 'sprint', 'm_Z9yKkU2N8', 'Swift as Hermes',
  '30-second max effort sprints followed by 60-second recovery.',
  10, ARRAY['legs', 'core'],
  '{"knees": 7, "ankles": 6, "hips": 5}'::jsonb,
  ARRAY['conditioning', 'generalCombat', 'boxing'],
  'intermediate', 'elite',
  ARRAY['cardio', 'sprint', 'hiit']
),
(
  'ex_005', 'HELLENIC DEADLIFTS', 'strength', 'ytGaGIn6SjE', 'The Weight of the World',
  'Conventional deadlifts focusing on posterior chain engagement.',
  9, ARRAY['hamstrings', 'glutes', 'back', 'traps'],
  '{"lower_back": 8, "knees": 5}'::jsonb,
  ARRAY['strength', 'generalCombat', 'wrestling'],
  'intermediate', 'elite',
  ARRAY['strength', 'posterior_chain', 'compound']
),
(
  'ex_006', 'THERMOPYLAE THRUSTERS', 'plyometric', 'rZ_9GzNUP_M', 'Defy the Odds',
  'Full squat into overhead press. Maximum explosive power.',
  9, ARRAY['quads', 'glutes', 'shoulders', 'traps'],
  '{"knees": 8, "shoulders": 7, "hips": 6}'::jsonb,
  ARRAY['strength', 'mma', 'boxing'],
  'advanced', 'elite',
  ARRAY['plyometric', 'full_body', 'explosive']
),
(
  'ex_007', 'PLIO SPARTAN BURPEE', 'plyometric', 'L61p2B9M2wo', 'Rise from the Ash',
  'Explosive burpee with tuck jump. Triple extension focus.',
  10, ARRAY['full_body'],
  '{"knees": 9, "wrists": 6, "ankles": 7}'::jsonb,
  ARRAY['conditioning', 'generalCombat', 'mma'],
  'advanced', 'elite',
  ARRAY['plyometric', 'full_body', 'hiit']
),
(
  'ex_008', 'BOX JUMP ASCENSION', 'plyometric', 'xFfhlTjNJL8', 'Mount Olympus',
  'Explosive box jumps focusing on soft landings.',
  9, ARRAY['quads', 'glutes', 'calves'],
  '{"knees": 8, "ankles": 7}'::jsonb,
  ARRAY['strength', 'conditioning', 'boxing'],
  'intermediate', 'elite',
  ARRAY['plyometric', 'legs', 'power']
),
-- ISOMETRIC - Endurance & Stability
(
  'ex_009', 'IRON ISO SHADOWBOX', 'isometric', 'WpYm78WJ2U0', 'Unmoving Spear',
  'Hold boxing guard position with light weights. Isometric shoulder endurance.',
  7, ARRAY['shoulders', 'traps', 'core'],
  '{"shoulders": 6, "wrists": 4}'::jsonb,
  ARRAY['boxing', 'mma', 'generalCombat'],
  'beginner', 'advanced',
  ARRAY['isometric', 'combat', 'endurance']
),
(
  'ex_010', 'WALL SIT AEGIS', 'isometric', 'y-wV4et0t0o', 'The Shield Wall',
  'Wall sit with weights held at shoulder height.',
  7, ARRAY['quads', 'shoulders'],
  '{"knees": 6}'::jsonb,
  ARRAY['strength', 'generalCombat'],
  'beginner', 'advanced',
  ARRAY['isometric', 'legs', 'endurance']
),
(
  'ex_011', 'L-SIT HANG', 'isometric', 'IUZ25V9s6zw', 'Suspend in Void',
  'L-sit position on parallettes or floor. Core compression.',
  8, ARRAY['core', 'hip_flexors', 'triceps'],
  '{"wrists": 6, "shoulders": 5}'::jsonb,
  ARRAY['strength', 'generalCombat', 'gymnastics'],
  'intermediate', 'elite',
  ARRAY['isometric', 'core', 'gymnastics']
),
-- COMBAT - Fighting Specific
(
  'ex_012', 'ROTATIONAL MED BALL SLAM', 'combat', 'XJzBLNE_1Q0', 'The Spear Throw',
  'Explosive rotational med ball slams. Hip drive through core.',
  9, ARRAY['core', 'obliques', 'shoulders'],
  '{"spine": 6, "shoulders": 6}'::jsonb,
  ARRAY['mma', 'boxing', 'muayThai'],
  'intermediate', 'elite',
  ARRAY['combat', 'power', 'rotation']
),
(
  'ex_013', 'BATTLE ROPE TITAN', 'combat', 'A5ZeaEElWjY', 'Wrath of Poseidon',
  'Alternating battle rope waves with squat stance.',
  8, ARRAY['shoulders', 'core', 'legs'],
  '{"shoulders": 7}'::jsonb,
  ARRAY['conditioning', 'generalCombat', 'boxing'],
  'beginner', 'advanced',
  ARRAY['combat', 'endurance', 'hiit']
),
(
  'ex_014', 'SLED PUSH PHALANX', 'combat', 'pASwB0fmoOM', 'Drive the Line',
  'Heavy sled push for distance. Low stance, driving legs.',
  9, ARRAY['legs', 'core', 'upper_back'],
  '{"knees": 7, "hips": 6}'::jsonb,
  ARRAY['strength', 'wrestling', 'football'],
  'intermediate', 'elite',
  ARRAY['combat', 'strength', 'power']
),
-- MOBILITY - Recovery
(
  'ex_015', 'THORACIC BRIDGE FLOW', 'mobility', 's8A7hZ2nQ9M', 'Open the Gates',
  'Bridge position with thoracic spine rotation. Hip flexor release.',
  5, ARRAY['spine', 'hip_flexors', 'shoulders'],
  '{"spine": 3, "wrists": 4}'::jsonb,
  ARRAY['generalCombat', 'conditioning'],
  'beginner', 'advanced',
  ARRAY['mobility', 'recovery', 'flexibility']
),
(
  'ex_016', 'HINDU PUSH-UP FLOW', 'mobility', 'v8JhyyZ3nK1', 'The Cobra Dance',
  'Push-up to pike to cobra. Spinal articulation.',
  6, ARRAY['chest', 'shoulders', 'spine'],
  '{"wrists": 5, "shoulders": 5}'::jsonb,
  ARRAY['generalCombat', 'mobility', 'yoga'],
  'beginner', 'advanced',
  ARRAY['mobility', 'flow', 'recovery']
),
(
  'ex_017', '90/90 HIP SWITCH', 'mobility', 't4Mhyk8PqR7', 'Unlock the Hips',
  'Seated hip rotation drill. Combat-ready hip mobility.',
  4, ARRAY['hips', 'glutes'],
  '{"hips": 2, "knees": 3}'::jsonb,
  ARRAY['generalCombat', 'bjj', 'wrestling'],
  'beginner', 'advanced',
  ARRAY['mobility', 'hips', 'recovery']
),
-- STRENGTH - Building Power
(
  'ex_018', 'AGOGÉ SQUATS', 'strength', 'h7KjL9mP3vW', 'Forge the Foundation',
  'High-volume squat protocol with tempo control.',
  8, ARRAY['quads', 'glutes', 'hamstrings'],
  '{"knees": 7, "hips": 5}'::jsonb,
  ARRAY['strength', 'generalCombat', 'wrestling'],
  'intermediate', 'elite',
  ARRAY['strength', 'legs', 'volume']
),
(
  'ex_019', 'GLADIATOR ROWS', 'strength', 'c3NfG8hJ5kL', 'Pull the Chariot',
  'Heavy bent-over rows. Posterior chain dominance.',
  7, ARRAY['back', 'biceps', 'core'],
  '{"lower_back": 6, "shoulders": 5}'::jsonb,
  ARRAY['strength', 'generalCombat'],
  'beginner', 'advanced',
  ARRAY['strength', 'back', 'pulling']
),
(
  'ex_020', 'SHIELD CARRY', 'strength', 'n9BqR4tY7hF', 'Hold the Line',
  'Farmer carry with offset load. Core anti-rotation.',
  6, ARRAY['core', 'grip', 'traps'],
  '{"wrists": 4, "shoulders": 4}'::jsonb,
  ARRAY['strength', 'generalCombat', 'mma'],
  'beginner', 'advanced',
  ARRAY['strength', 'grip', 'carry']
)
ON CONFLICT (id) DO UPDATE SET
  name = EXCLUDED.name,
  category = EXCLUDED.category,
  youtube_id = EXCLUDED.youtube_id,
  target_metaphor = EXCLUDED.target_metaphor,
  instructions = EXCLUDED.instructions,
  intensity_level = EXCLUDED.intensity_level,
  primary_muscles = EXCLUDED.primary_muscles,
  joint_stress = EXCLUDED.joint_stress,
  ideal_goals = EXCLUDED.ideal_goals,
  min_fitness_level = EXCLUDED.min_fitness_level,
  max_fitness_level = EXCLUDED.max_fitness_level,
  workout_tags = EXCLUDED.workout_tags,
  updated_at = NOW();
