import '../models/exercise.dart';
import '../models/workout_template.dart';
import '../models/workout_schedule.dart';
import 'package:uuid/uuid.dart';

class WorkoutParser {
  static const _uuid = Uuid();

  static WorkoutSchedule parse(String text, String scheduleName) {
    final templates = <WorkoutTemplate>[];
    final importTime = DateTime.now();
    
    final dayRegex = RegExp(r'(\d+(?:st|nd|rd|th|d)?\s+day)', caseSensitive: false);
    final sections = text.split(dayRegex);
    final dayMatches = dayRegex.allMatches(text).toList();

    for (var i = 1; i < sections.length; i++) {
      final dayName = dayMatches[i - 1].group(0) ?? 'Workout ${templates.length + 1}';
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
      'Abs': ['abs', 'core', 'crunch', 'sit up', 'plank'],
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
               if (name.contains('shoulder') || name.contains('overhead') || name.contains('military')) {
                 muscleGroups.add('Shoulders');
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
    final exercises = <Exercise>[];
    final lines = content.split('\n');
    
    final exerciseLineRegex = RegExp(r'^(.+?)\s+((?:\d+(?:\(\d+\))?\s*)+)$');

    for (var line in lines) {
      line = line.trim();
      if (line.isEmpty) continue;

      final match = exerciseLineRegex.firstMatch(line);
      if (match != null) {
        final name = match.group(1)!.trim();
        final setsString = match.group(2)!.trim();
        final targetReps = _parseTargetReps(setsString);

        exercises.add(Exercise(
          id: _uuid.v4(),
          name: name,
          targetReps: targetReps,
        ));
      }
    }

    return exercises;
  }

  static List<int> _parseTargetReps(String setsString) {
    final targetReps = <int>[];
    final setPattern = RegExp(r'(\d+)(?:\((\d+)\))?');
    final matches = setPattern.allMatches(setsString);

    for (final match in matches) {
      final reps = int.parse(match.group(1)!);
      final count = match.group(2) != null ? int.parse(match.group(2)!) : 1;

      for (var i = 0; i < count; i++) {
        targetReps.add(reps);
      }
    }

    return targetReps;
  }
}
