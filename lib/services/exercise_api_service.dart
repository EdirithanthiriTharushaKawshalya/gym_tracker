import 'dart:convert';
import 'package:http/http.dart' as http;

class ExerciseApiService {
  static final ExerciseApiService _instance = ExerciseApiService._internal();
  factory ExerciseApiService() => _instance;
  ExerciseApiService._internal();

  List<dynamic>? _cachedExercises;

  Future<String?> getImageUrl(String exerciseName) async {
    try {
      if (_cachedExercises == null) {
        final response = await http.get(Uri.parse(
          'https://raw.githubusercontent.com/yuhonas/free-exercise-db/main/dist/exercises.json',
        ));
        if (response.statusCode == 200) {
          _cachedExercises = json.decode(response.body);
        }
      }

      if (_cachedExercises == null) return null;

      // Basic fuzzy matching: Find the first exercise that contains most of the words
      final queryWords = exerciseName.toLowerCase()
          .replaceAll(RegExp(r'[^a-z0-9\s]'), '')
          .split(' ')
          .where((w) => w.length > 2)
          .toList();

      if (queryWords.isEmpty) return null;

      var bestMatch;
      int maxScore = 0;

      for (var exercise in _cachedExercises!) {
        final name = (exercise['name'] as String).toLowerCase();
        int score = 0;
        for (var word in queryWords) {
          if (name.contains(word)) score++;
        }

        if (score > maxScore) {
          maxScore = score;
          bestMatch = exercise;
        }
      }

      if (bestMatch != null && maxScore >= (queryWords.length / 2).floor()) {
        final imagePath = (bestMatch['images'] as List).first;
        return 'https://raw.githubusercontent.com/yuhonas/free-exercise-db/main/exercises/$imagePath';
      }
    } catch (e) {
      print('Error fetching exercise image: $e');
    }
    return null;
  }
}
