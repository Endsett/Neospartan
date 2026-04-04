import 'dart:math';

import 'user_profile.dart';

class StoicQuote {
  final String text;
  final String author;
  final List<TrainingGoal> goals;
  final List<String> tags;

  const StoicQuote({
    required this.text,
    required this.author,
    this.goals = const [],
    this.tags = const [],
  });

  Map<String, dynamic> toMap() {
    return {
      'text': text,
      'author': author,
      'goals': goals.map((g) => g.name).toList(),
      'tags': tags,
    };
  }

  static final List<StoicQuote> library = [
    ..._coreQuotes,
    ..._buildExpandedLibrary(),
  ];

  static StoicQuote forUser(
    UserProfile profile, {
    String? workoutType,
    int? readinessScore,
  }) {
    final normalizedWorkoutType = workoutType?.toLowerCase() ?? '';

    final candidates = library.where((quote) {
      final goalMatch =
          quote.goals.isEmpty || quote.goals.contains(profile.trainingGoal);
      final workoutMatch =
          normalizedWorkoutType.isEmpty ||
          quote.tags.any(
            (tag) => normalizedWorkoutType.contains(tag.toLowerCase()),
          );
      return goalMatch && workoutMatch;
    }).toList();

    if (candidates.isEmpty) {
      return library.first;
    }

    final recoveryBias = readinessScore != null && readinessScore < 45;
    final highDriveBias = readinessScore != null && readinessScore >= 80;

    final biased = candidates.where((quote) {
      if (recoveryBias) {
        return quote.tags.contains('recovery') ||
            quote.tags.contains('discipline');
      } else if (highDriveBias) {
        return quote.tags.contains('courage') || quote.tags.contains('action');
      } else {
        return true;
      }
    }).toList();

    final pool = biased.isNotEmpty ? biased : candidates;
    final random = Random();
    return pool[random.nextInt(pool.length)];
  }

  static List<StoicQuote> libraryForUser(
    UserProfile profile, {
    String? workoutType,
    int? readinessScore,
    int limit = 120,
  }) {
    final normalizedWorkoutType = workoutType?.toLowerCase() ?? '';
    final recoveryBias = readinessScore != null && readinessScore < 45;
    final highDriveBias = readinessScore != null && readinessScore >= 80;

    final goalMatched = library.where((quote) {
      return quote.goals.isEmpty || quote.goals.contains(profile.trainingGoal);
    }).toList();

    final workoutMatched = goalMatched.where((quote) {
      return normalizedWorkoutType.isEmpty ||
          quote.tags.any(
            (tag) => normalizedWorkoutType.contains(tag.toLowerCase()),
          );
    }).toList();

    final readinessMatched = workoutMatched.where((quote) {
      if (recoveryBias) {
        return quote.tags.contains('recovery') ||
            quote.tags.contains('discipline');
      }
      if (highDriveBias) {
        return quote.tags.contains('courage') || quote.tags.contains('action');
      }
      return true;
    }).toList();

    final selected = readinessMatched.isNotEmpty
        ? readinessMatched
        : (workoutMatched.isNotEmpty ? workoutMatched : goalMatched);

    return selected.take(limit).toList();
  }

  static List<StoicQuote> _buildExpandedLibrary() {
    final expanded = <StoicQuote>[];
    final themes = _themeFragments;

    for (final goal in TrainingGoal.values) {
      for (final fragment in themes) {
        expanded.add(
          StoicQuote(
            text:
                '${fragment.opening} ${_goalMessage(goal)} ${fragment.closing}',
            author: fragment.author,
            goals: [goal],
            tags: fragment.tags,
          ),
        );
      }
    }

    return expanded;
  }

  static String _goalMessage(TrainingGoal goal) {
    switch (goal) {
      case TrainingGoal.mma:
        return 'In every exchange, choose composure over chaos.';
      case TrainingGoal.boxing:
        return 'Let each round refine your precision and restraint.';
      case TrainingGoal.muayThai:
        return 'Meet pressure with structure and measured intent.';
      case TrainingGoal.wrestling:
        return 'Win the position before chasing the finish.';
      case TrainingGoal.bjj:
        return 'Patience creates openings where force cannot.';
      case TrainingGoal.generalCombat:
        return 'Master fundamentals and confidence will follow.';
      case TrainingGoal.strength:
        return 'Build strength as a long discipline, not a single moment.';
      case TrainingGoal.conditioning:
        return 'Steady effort becomes extraordinary capacity over time.';
    }
  }

  static const List<StoicQuote> _coreQuotes = [
    StoicQuote(
      text: 'We suffer more often in imagination than in reality.',
      author: 'Seneca',
      tags: ['mindset', 'discipline'],
    ),
    StoicQuote(
      text: 'You have power over your mind, not outside events.',
      author: 'Marcus Aurelius',
      tags: ['mindset', 'focus'],
    ),
    StoicQuote(
      text: 'Waste no more time arguing what a good person should be. Be one.',
      author: 'Marcus Aurelius',
      tags: ['action', 'discipline'],
    ),
    StoicQuote(
      text: 'No person is free who is not master of oneself.',
      author: 'Epictetus',
      tags: ['discipline', 'self-control'],
    ),
    StoicQuote(
      text: 'Difficulties strengthen the mind, as labor does the body.',
      author: 'Seneca',
      tags: ['resilience', 'conditioning'],
    ),
    StoicQuote(
      text: 'The obstacle in the path becomes the path.',
      author: 'Marcus Aurelius',
      tags: ['resilience', 'action'],
    ),
    StoicQuote(
      text:
          'First say to yourself what you would be; then do what you have to do.',
      author: 'Epictetus',
      tags: ['action', 'focus'],
    ),
    StoicQuote(
      text:
          'How long are you going to wait before you demand the best for yourself?',
      author: 'Epictetus',
      tags: ['action', 'courage'],
    ),
    StoicQuote(
      text:
          'If it is not right, do not do it; if it is not true, do not say it.',
      author: 'Marcus Aurelius',
      tags: ['discipline', 'integrity'],
    ),
    StoicQuote(
      text:
          'It is not because things are difficult that we do not dare; it is because we do not dare that they are difficult.',
      author: 'Seneca',
      tags: ['courage', 'action'],
    ),
    StoicQuote(
      text: 'To bear trials with a calm mind robs misfortune of its strength.',
      author: 'Seneca',
      tags: ['recovery', 'resilience'],
    ),
    StoicQuote(
      text:
          'The wise person is neither raised up by prosperity nor cast down by adversity.',
      author: 'Seneca',
      tags: ['recovery', 'mindset'],
    ),
  ];

  static const List<_ThemeFragment> _themeFragments = [
    _ThemeFragment(
      opening: 'Discipline is a daily vote for your future self.',
      closing: 'Return tomorrow and cast it again.',
      author: 'NeoSpartan Stoic Canon',
      tags: ['discipline', 'action'],
    ),
    _ThemeFragment(
      opening: 'Do not negotiate with your lower impulses.',
      closing: 'Lead them with reason.',
      author: 'NeoSpartan Stoic Canon',
      tags: ['discipline', 'focus'],
    ),
    _ThemeFragment(
      opening: 'Courage is not the absence of strain.',
      closing: 'It is ordered action within strain.',
      author: 'NeoSpartan Stoic Canon',
      tags: ['courage', 'action'],
    ),
    _ThemeFragment(
      opening: 'The body complains where the will is undecided.',
      closing: 'Decide, then proceed.',
      author: 'NeoSpartan Stoic Canon',
      tags: ['mindset', 'action'],
    ),
    _ThemeFragment(
      opening: 'Recovery is not retreat from growth.',
      closing: 'It is growth made possible.',
      author: 'NeoSpartan Stoic Canon',
      tags: ['recovery', 'discipline'],
    ),
    _ThemeFragment(
      opening: 'Focus is moral force directed to one task.',
      closing: 'Protect it from distraction.',
      author: 'NeoSpartan Stoic Canon',
      tags: ['focus', 'discipline'],
    ),
    _ThemeFragment(
      opening: 'You are not training for applause.',
      closing: 'You are training for character.',
      author: 'NeoSpartan Stoic Canon',
      tags: ['integrity', 'discipline'],
    ),
    _ThemeFragment(
      opening: 'A clear plan removes most fear.',
      closing: 'Follow the plan with patience.',
      author: 'NeoSpartan Stoic Canon',
      tags: ['focus', 'recovery'],
    ),
    _ThemeFragment(
      opening: 'Intensity without wisdom burns quickly.',
      closing: 'Train hard, then restore harder.',
      author: 'NeoSpartan Stoic Canon',
      tags: ['recovery', 'conditioning'],
    ),
    _ThemeFragment(
      opening: 'The disciplined athlete accepts repetition.',
      closing: 'Repetition forges reliability.',
      author: 'NeoSpartan Stoic Canon',
      tags: ['discipline', 'conditioning'],
    ),
    _ThemeFragment(
      opening: 'Do the simple thing with full intention.',
      closing: 'Mastery is accumulated simplicity.',
      author: 'NeoSpartan Stoic Canon',
      tags: ['focus', 'mindset'],
    ),
    _ThemeFragment(
      opening: 'When fatigue speaks loudly, principles must speak louder.',
      closing: 'Hold to what you chose in clarity.',
      author: 'NeoSpartan Stoic Canon',
      tags: ['resilience', 'discipline'],
    ),
    _ThemeFragment(
      opening: 'Control your response and you control the day.',
      closing: 'Everything else is weather.',
      author: 'NeoSpartan Stoic Canon',
      tags: ['mindset', 'focus'],
    ),
    _ThemeFragment(
      opening: 'Action is the cure for anxious speculation.',
      closing: 'Begin the next set.',
      author: 'NeoSpartan Stoic Canon',
      tags: ['action', 'courage'],
    ),
    _ThemeFragment(
      opening: 'The standard is not perfection.',
      closing: 'The standard is honest effort repeated.',
      author: 'NeoSpartan Stoic Canon',
      tags: ['discipline', 'recovery'],
    ),
  ];
}

class _ThemeFragment {
  final String opening;
  final String closing;
  final String author;
  final List<String> tags;

  const _ThemeFragment({
    required this.opening,
    required this.closing,
    required this.author,
    required this.tags,
  });
}
