import 'dart:convert';
import 'package:http/http.dart' as http;

class ExerciseInfo {
  final String id;
  final String name;
  final String equipment;
  final String bodyPart;

  ExerciseInfo({
    required this.id,
    required this.name,
    required this.equipment,
    required this.bodyPart,
  });
}

class ExerciseApiService {
  static final ExerciseApiService _instance = ExerciseApiService._internal();
  factory ExerciseApiService() => _instance;
  ExerciseApiService._internal();

  List<ExerciseInfo>? _cachedExercises;
  final Map<String, String?> _searchCache = {};

  // Professional mapping of colloquial terms to target body parts in the database
  static const Map<String, String> _bodyPartMap = {
    'chest': 'chest', 'pec': 'chest', 'bench': 'chest', 'fly': 'chest',
    'back': 'back', 'lat': 'back', 'row': 'back', 'pull': 'back', 'lats': 'back',
    'shoulder': 'shoulders', 'delt': 'shoulders', 'press': 'shoulders', 
    'bicep': 'upper arms', 'curl': 'upper arms',
    'tricep': 'upper arms', 'dip': 'upper arms', 'extension': 'upper arms',
    'leg': 'upper legs', 'squat': 'upper legs', 'quad': 'upper legs', 'hamstring': 'upper legs', 'glute': 'upper legs',
    'calf': 'lower legs',
    'abs': 'waist', 'core': 'waist', 'crunch': 'waist', 'sit up': 'waist',
  };

  static const Map<String, String> _aliases = {
    // Chest
    'pec flys': 'lever seated fly',
    'pec fly': 'lever seated fly',
    'pec deck': 'lever seated fly',
    'machine fly': 'lever seated fly',
    'chest flys': 'dumbbell chest fly',
    'chest fly': 'dumbbell chest fly',
    'bench': 'barbell bench press',
    'bench press': 'barbell bench press',
    'bb bench': 'barbell bench press',
    'b/b bench': 'barbell bench press',
    'db bench': 'dumbbell bench press',
    'd/b bench': 'dumbbell bench press',
    'incline bench': 'barbell incline bench press',
    'decline bench': 'barbell decline bench press',
    // Back
    'lat pull downs': 'lat pulldown',
    'lat pull down': 'lat pulldown',
    'latpulldown': 'lat pulldown',
    'rows': 'seated cable row',
    'row': 'seated cable row',
    'pull ups': 'pull-up',
    'push ups': 'push-up',
    't-bar row': 'lever t-bar row',
    // Shoulders
    'shoulder press': 'dumbbell shoulder press',
    'overhead press': 'barbell shoulder press',
    'military press': 'barbell shoulder press',
    'lateral raises': 'dumbbell lateral raise',
    'lateral raise': 'dumbbell lateral raise',
    'front raises': 'dumbbell front raise',
    // Arms
    'bicep curls': 'dumbbell curl',
    'bicep curl': 'dumbbell curl',
    'hammer curls': 'dumbbell hammer curl',
    'preacher curls': 'barbell preacher curl',
    'tricep pushdowns': 'cable triceps pushdown',
    'tricep extensions': 'dumbbell triceps extension',
    'skull crushers': 'ez barbell skullcrusher',
    // Legs
    'squats': 'barbell squat',
    'deadlifts': 'barbell deadlift',
    'leg press': 'lever leg press',
    'leg extensions': 'lever leg extension',
    'leg curls': 'lever lying leg curl',
    'calf raises': 'lever standing calf raise',
  };

  Future<void> _loadExercises() async {
    if (_cachedExercises != null) return;

    try {
      final response = await http.get(Uri.parse(
        'https://raw.githubusercontent.com/omercotkd/exercises-gifs/main/exercises.csv',
      ));

      if (response.statusCode == 200) {
        final lines = const LineSplitter().convert(response.body);
        if (lines.isEmpty) return;

        _cachedExercises = [];
        for (var i = 1; i < lines.length; i++) {
          final parts = _parseCsvLine(lines[i]);
          if (parts.length >= 4) {
            _cachedExercises!.add(ExerciseInfo(
              bodyPart: parts[0],
              equipment: parts[1],
              id: parts[2],
              name: parts[3],
            ));
          }
        }
      }
    } catch (e) {
      print('Error loading exercises: $e');
    }
  }

  List<String> _parseCsvLine(String line) {
    final parts = <String>[];
    var current = StringBuffer();
    var inQuotes = false;

    for (var i = 0; i < line.length; i++) {
      final char = line[i];
      if (char == '"') {
        inQuotes = !inQuotes;
      } else if (char == ',' && !inQuotes) {
        parts.add(current.toString().trim());
        current = StringBuffer();
      } else {
        current.write(char);
      }
    }
    parts.add(current.toString().trim());
    return parts;
  }

  Future<String?> getImageUrl(String exerciseName) async {
    final originalQuery = exerciseName.toLowerCase().trim();
    if (_searchCache.containsKey(originalQuery)) return _searchCache[originalQuery];

    await _loadExercises();
    if (_cachedExercises == null || _cachedExercises!.isEmpty) return null;

    // 1. Alias Resolution
    String query = originalQuery;
    if (_aliases.containsKey(query)) {
      query = _aliases[query]!;
    } else {
      _aliases.forEach((alias, replacement) {
        if (query.contains(alias)) {
          query = query.replaceAll(alias, replacement);
        }
      });
    }

    query = query
        .replaceAll('d/b', 'dumbbell')
        .replaceAll('db', 'dumbbell')
        .replaceAll('b/b', 'barbell')
        .replaceAll('bb', 'barbell');

    // 2. Exact Match Check
    for (var ex in _cachedExercises!) {
      if (ex.name.toLowerCase() == query) {
        final url = buildGifUrl(ex.id);
        _searchCache[originalQuery] = url;
        return url;
      }
    }

    // 3. Muscle Group Context Detection
    String? suspectedBodyPart;
    final queryLower = query.toLowerCase();
    for (var entry in _bodyPartMap.entries) {
      if (queryLower.contains(entry.key)) {
        suspectedBodyPart = entry.value;
        break;
      }
    }

    // 4. Advanced Scoring
    final queryWords = query.split(RegExp(r'[\s\-]')).where((w) => w.length >= 2).toList();
    if (queryWords.isEmpty) return null;

    ExerciseInfo? bestMatch;
    double maxScore = -100.0;

    for (var ex in _cachedExercises!) {
      final exName = ex.name.toLowerCase();
      final exWords = exName.split(RegExp(r'[\s\-]'));
      final exBodyPart = ex.bodyPart.toLowerCase();
      
      double score = 0;
      int wordMatches = 0;

      // Body Part Filter (Strong)
      if (suspectedBodyPart != null && exBodyPart != suspectedBodyPart) {
        if (!(queryLower.contains('press') && (exBodyPart == 'chest' || exBodyPart == 'shoulders'))) {
           score -= 20.0;
        }
      }

      for (var qw in queryWords) {
        if (exWords.contains(qw)) {
          wordMatches++;
          score += 10.0;
        } else if (exName.startsWith(qw)) {
          score += 4.0;
        } else if (exName.contains(qw)) {
          score += 1.0;
        }
      }

      final hasDumbbell = query.contains('dumbbell');
      final hasBarbell = query.contains('barbell');
      final hasCable = query.contains('cable');
      final hasMachine = query.contains('machine') || query.contains('lever');

      if (hasDumbbell && ex.equipment.contains('dumbbell')) score += 5.0;
      if (hasBarbell && ex.equipment.contains('barbell')) score += 5.0;
      if (hasCable && ex.equipment.contains('cable')) score += 5.0;
      if (hasMachine && (ex.equipment.contains('lever') || ex.equipment.contains('machine'))) score += 5.0;

      if (hasDumbbell && !ex.equipment.contains('dumbbell')) score -= 15.0;
      if (hasBarbell && !ex.equipment.contains('barbell')) score -= 15.0;
      if (hasCable && !ex.equipment.contains('cable')) score -= 15.0;

      score -= (exWords.length - wordMatches).abs() * 2.0;

      if (score > maxScore) {
        maxScore = score;
        bestMatch = ex;
      }
    }

    if (bestMatch != null && maxScore > 5.0) {
      final url = buildGifUrl(bestMatch.id);
      _searchCache[originalQuery] = url;
      return url;
    }

    _searchCache[originalQuery] = null;
    return null;
  }

  Future<List<ExerciseInfo>> searchExercises(String query) async {
    await _loadExercises();
    if (_cachedExercises == null) return [];

    final searchTerms = query.toLowerCase().split(RegExp(r'[\s\-]')).where((t) => t.length > 1).toList();
    if (searchTerms.isEmpty) return [];

    final results = _cachedExercises!.map((ex) {
      final name = ex.name.toLowerCase();
      int score = 0;
      for (var term in searchTerms) {
        if (name == term) score += 10;
        if (name.contains(term)) score += 2;
      }
      return MapEntry(ex, score);
    }).where((entry) => entry.value > 0).toList();

    results.sort((a, b) => b.value.compareTo(a.value));
    return results.take(20).map((e) => e.key).toList();
  }

  static String buildGifUrl(String id) {
    final paddedId = id.padLeft(4, '0');
    return 'https://raw.githubusercontent.com/omercotkd/exercises-gifs/main/assets/$paddedId.gif';
  }
}
