import '../models/exercise.dart';

class WorkoutTemplate {
  final String id;
  final String name;
  final List<Exercise> exercises;
  final List<String> targetMuscleGroups;
  final DateTime createdAt; // To group by import batch

  WorkoutTemplate({
    required this.id,
    required this.name,
    required this.exercises,
    this.targetMuscleGroups = const [],
    required this.createdAt,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
      'exercises': exercises.map((e) => e.toMap()).toList(),
      'targetMuscleGroups': targetMuscleGroups,
      'createdAt': createdAt.toIso8601String(),
    };
  }

  factory WorkoutTemplate.fromMap(Map<String, dynamic> map) {
    return WorkoutTemplate(
      id: map['id'] ?? '',
      name: map['name'] ?? '',
      exercises: (map['exercises'] as List? ?? [])
          .map((e) => Exercise.fromMap(e as Map<String, dynamic>))
          .toList(),
      targetMuscleGroups: List<String>.from(map['targetMuscleGroups'] ?? []),
      createdAt: map['createdAt'] != null 
          ? DateTime.parse(map['createdAt']) 
          : DateTime.now(),
    );
  }
}
