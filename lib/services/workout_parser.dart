import '../models/exercise.dart';
import '../models/workout_template.dart';
import '../models/workout_schedule.dart';
import 'package:uuid/uuid.dart';

class WorkoutParser {
  static const _uuid = Uuid();

  static WorkoutSchedule parse(String text, String scheduleName) {
    final templates = <WorkoutTemplate>[];
    final importTime = DateTime.now();
    
    // Support "1st Day", "Day 1", and markdown headers like "### Day 1" or "**Day 1 - Chest**"
    final dayRegex = RegExp(r'((?:^|\n)(?:#+\s*)?(?:\*\*|__)?(?:day\s+\d+|\d+(?:st|nd|rd|th|d)?\s+day)(?:\*\*|__)?[^\n]*(?:\n|$))', caseSensitive: false);
    final sections = text.split(dayRegex);
    final dayMatches = dayRegex.allMatches(text).toList();

    for (var i = 1; i < sections.length; i++) {
      String dayName = dayMatches[i - 1].group(0)!.trim();
      // Clean markdown and extra characters from day name
      dayName = dayName.replaceAll(RegExp(r'[#\*_]'), '').trim();
      
      final content = sections[i].trim();
      
      final exercises = _parseExercises(content);
      if (exercises.isNotEmpty) {
        templates.add(WorkoutTemplate(
          id: _uuid.v4(),
          name: dayName,
          exercises: exercises,
          targetMuscleGroups: identifyMuscleGroups(exercises),
          createdAt: importTime,
        ));
      }
    }

    return WorkoutSchedule(
      id: _uuid.v4(),
      name: scheduleName,
      createdAt: importTime,
      templates: templates,
    );
  }

  static List<String> identifyMuscleGroups(List<Exercise> exercises) {
    final muscleGroups = <String>{};
    
    final mapping = {
      'Chest': ['chest', 'bench', 'fly', 'pec', 'press'],
      'Back': ['back', 'lat', 'row', 'pull', 'lats', 'deadlift'],
      'Shoulders': ['shoulder', 'delt', 'press', 'lateral', 'raise'],
      'Biceps': ['bicep', 'curl', 'hammer'],
      'Triceps': ['tricep', 'dip', 'extension', 'skull'],
      'Legs': ['leg', 'squat', 'quad', 'hamstring', 'glute', 'calf', 'press', 'extension', 'curl'],
      'Abs': ['abs', 'core', 'crunch', 'sit up', 'plank', 'stomach', 'waist', 'oblique'],
      'Cardio': ['treadmill', 'bike', 'bicycle', 'cycling', 'run', 'walk', 'elliptical', 'stair', 'rowing', 'cardio'],
    };

    // Refined press mapping to avoid confusion
    final pressMapping = {
      'bench': 'Chest',
      'incline': 'Chest',
      'decline': 'Chest',
      'overhead': 'Shoulders',
      'military': 'Shoulders',
      'shoulder': 'Shoulders',
      'arnold': 'Shoulders',
      'leg press': 'Legs',
    };

    for (final exercise in exercises) {
      final name = exercise.name.toLowerCase();
      
      // Also consider the exercise's category if it's already set and not 'Other'
      if (exercise.category != 'Other') {
        muscleGroups.add(exercise.category);
      }

      // Check specific press mappings
      for (final entry in pressMapping.entries) {
        if (name.contains(entry.key)) {
          muscleGroups.add(entry.value);
        }
      }

      // Check general mappings
      for (final entry in mapping.entries) {
        for (final keyword in entry.value) {
          if (name.contains(keyword)) {
            // Avoid adding 'Shoulders' for general 'press' if it's already caught by more specific press mappings or if it's clearly chest
            if (keyword == 'press') {
               if (name.contains('bench') || name.contains('chest')) {
                 muscleGroups.add('Chest');
                 continue;
               }
               if (name.contains('shoulder') || name.contains('overhead') || name.contains('military') || name.contains('arnold')) {
                 muscleGroups.add('Shoulders');
                 continue;
               }
               if (name.contains('leg')) {
                 muscleGroups.add('Legs');
                 continue;
               }
            }
            muscleGroups.add(entry.key);
            break;
          }
        }
      }
    }

    return muscleGroups.toList();
  }

  static List<Exercise> _parseExercises(String content) {
    // Break up multiple exercises that are on the same line
    content = content.replaceAllMapped(RegExp(r'(\(\d+\))\s+(?=\S)'), (match) {
      return '${match.group(1)}\n';
    });

    final exercises = <Exercise>[];
    final lines = content.split('\n');
    
    final exerciseLineRegex = RegExp(r'^(.+?)\s+([0-9\-\s]*(?:min|sec|minutes|seconds)?\s*(?:\(\d+\)))$', caseSensitive: false);
    String currentCategory = 'Other';

    for (var line in lines) {
      line = line.trim();
      if (line.isEmpty) continue;

      // Check if the line is a category header (e.g., # BICEPS or **[LEGS]**)
      // We look for patterns like # Category, [Category], or **[Category]**
      // Improved regex to support symbols like / and & (e.g., [ABS/CORE] or [BICEPS & TRICEPS])
      final categoryMatch = RegExp(r'^(?:#+|\*\*|__)?\s*\[?([a-zA-Z\s\/\&\-]+)\]?\s*(?:\*\*|__)?$').firstMatch(line);
      if (categoryMatch != null) {
        final rawCategory = categoryMatch.group(1)!.trim();
        // Normalize to Title Case (e.g., CHEST -> Chest)
        currentCategory = rawCategory[0].toUpperCase() + rawCategory.substring(1).toLowerCase();
        continue;
      }

      final match = exerciseLineRegex.firstMatch(line);
      if (match != null) {
        String name = match.group(1)!.trim();
        
        // Remove common AI formatting symbols like bullet points, hashtags, dots at start
        name = name.replaceAll(RegExp(r'^[•\-\*\#\d\.\s]+'), '').trim();
        // Also strip any internal asterisks AI might use for bolding
        name = name.replaceAll('*', '').trim();
        // Remove trailing dots which mess up GIF matching
        name = name.replaceAll(RegExp(r'\.+$'), '').trim();
        
        final setsString = match.group(2)!.trim();
        final targetReps = _parseTargetReps(setsString);

        // If no explicit category header was found recently, try to guess from name
        String detectedCategory = currentCategory;
        if (detectedCategory == 'Other') {
          detectedCategory = _guessCategory(name);
        }

        exercises.add(Exercise(
          id: _uuid.v4(),
          name: name,
          targetReps: targetReps,
          category: detectedCategory,
        ));
      }
    }

    return exercises;
  }

  static String _guessCategory(String name) {
    final lowerName = name.toLowerCase();
    
    // Check specific complex names first to avoid generic keyword matching
    if (lowerName.contains('leg press')) return 'Legs';
    if (lowerName.contains('bench press')) return 'Chest';
    if (lowerName.contains('chest press')) return 'Chest';
    if (lowerName.contains('shoulder press')) return 'Shoulders';
    if (lowerName.contains('overhead press')) return 'Shoulders';
    if (lowerName.contains('military press')) return 'Shoulders';
    if (lowerName.contains('arnold press')) return 'Shoulders';
    
    final mapping = {
      'Chest': ['chest', 'bench', 'fly', 'pec', 'press'],
      'Back': ['back', 'lat', 'row', 'pull', 'lats', 'deadlift'],
      'Shoulders': ['shoulder', 'delt', 'press', 'lateral', 'raise'],
      'Biceps': ['bicep', 'curl', 'hammer'],
      'Triceps': ['tricep', 'dip', 'extension', 'skull'],
      'Legs': ['leg', 'squat', 'quad', 'hamstring', 'glute', 'calf', 'press', 'extension', 'curl'],
      'Abs': ['abs', 'core', 'crunch', 'sit up', 'plank', 'stomach', 'waist', 'oblique'],
      'Cardio': ['treadmill', 'bike', 'bicycle', 'cycling', 'run', 'walk', 'elliptical', 'stair', 'rowing', 'cardio'],
    };

    for (final entry in mapping.entries) {
      for (final keyword in entry.value) {
        if (lowerName.contains(keyword)) {
          return entry.key;
        }
      }
    }

    return 'Other';
  }

  static List<int> _parseTargetReps(String setsString) {
    final targetReps = <int>[];
    
    int? trailingMultiplier;
    final endMultiplierMatch = RegExp(r'\((\d+)\)$').firstMatch(setsString.trim());
    if (endMultiplierMatch != null) {
      trailingMultiplier = int.parse(endMultiplierMatch.group(1)!);
      setsString = setsString.trim().replaceAll(RegExp(r'\(\d+\)$'), '');
    }

    final repNumbers = RegExp(r'\d+').allMatches(setsString).map((m) => int.parse(m.group(0)!)).toList();

    if (repNumbers.isEmpty) {
      if (trailingMultiplier != null) {
        for (int i = 0; i < trailingMultiplier; i++) targetReps.add(0);
      }
      return targetReps;
    }

    if (trailingMultiplier != null) {
      if (repNumbers.length == trailingMultiplier) {
        return repNumbers;
      } else {
        for (int i = 0; i < repNumbers.length - 1; i++) {
          targetReps.add(repNumbers[i]);
        }
        for (int i = 0; i < trailingMultiplier; i++) {
          targetReps.add(repNumbers.last);
        }
      }
    } else {
      targetReps.addAll(repNumbers);
    }

    return targetReps;
  }
}
