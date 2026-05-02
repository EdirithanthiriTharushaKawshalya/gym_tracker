import 'package:cloud_firestore/cloud_firestore.dart';
import 'exercise.dart';

class Workout {
  final String id;
  final String name;
  final DateTime date;
  final List<Exercise> exercises;

  Workout({
    required this.id,
    required this.name,
    required this.date,
    required this.exercises,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
      'date': date,
      'exercises': exercises.map((e) => e.toMap()).toList(),
    };
  }

  factory Workout.fromMap(Map<String, dynamic> map) {
    return Workout(
      id: map['id'] ?? '',
      name: map['name'] ?? '',
      date: (map['date'] as Timestamp).toDate(),
      exercises: (map['exercises'] as List? ?? [])
          .map((e) => Exercise.fromMap(e as Map<String, dynamic>))
          .toList(),
    );
  }
}
