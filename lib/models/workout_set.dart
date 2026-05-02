import 'package:cloud_firestore/cloud_firestore.dart';

class WorkoutSet {
  final String id;
  final int reps;
  final double? weight;
  final DateTime timestamp;

  WorkoutSet({
    required this.id,
    required this.reps,
    this.weight,
    required this.timestamp,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'reps': reps,
      'weight': weight,
      'timestamp': timestamp,
    };
  }

  factory WorkoutSet.fromMap(Map<String, dynamic> map) {
    return WorkoutSet(
      id: map['id'] ?? '',
      reps: map['reps'] ?? 0,
      weight: (map['weight'] as num?)?.toDouble(),
      timestamp: (map['timestamp'] as Timestamp).toDate(),
    );
  }
}
