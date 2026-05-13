import 'package:cloud_firestore/cloud_firestore.dart';
import 'exercise.dart';
import '../services/workout_parser.dart';

class WorkoutSession {
  final String id;
  final String templateId;
  final String scheduleName;
  final String name;
  final DateTime date;
  final List<Exercise> exercises;

  double get totalVolume => exercises.fold(0.0, (sum, exercise) => sum + exercise.totalVolume);

  List<String> get targetMuscleGroups => WorkoutParser.identifyMuscleGroups(exercises);

  WorkoutSession({
    required this.id,
    required this.templateId,
    required this.scheduleName,
    required this.name,
    required this.date,
    required this.exercises,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'templateId': templateId,
      'scheduleName': scheduleName,
      'name': name,
      'date': date,
      'exercises': exercises.map((e) => e.toMap()).toList(),
    };
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'templateId': templateId,
      'scheduleName': scheduleName,
      'name': name,
      'date': date.toIso8601String(),
      'exercises': exercises.map((e) => e.toJson()).toList(),
    };
  }

  factory WorkoutSession.fromMap(Map<String, dynamic> map) {
    DateTime d;
    if (map['date'] is Timestamp) {
      d = (map['date'] as Timestamp).toDate();
    } else if (map['date'] is String) {
      d = DateTime.parse(map['date']);
    } else {
      d = DateTime.now();
    }

    return WorkoutSession(
      id: map['id'] ?? '',
      templateId: map['templateId'] ?? '',
      scheduleName: map['scheduleName'] ?? 'Unknown Schedule',
      name: map['name'] ?? '',
      date: d,
      exercises: (map['exercises'] as List? ?? [])
          .map((e) => Exercise.fromMap(e as Map<String, dynamic>))
          .toList(),
    );
  }
}
