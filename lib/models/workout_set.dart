import 'package:cloud_firestore/cloud_firestore.dart';

class WorkoutSet {
  final String id;
  final int reps;
  final String repsUnit; // 'reps' or 'mins'
  final double? weight;
  final String weightUnit; // 'kg' or 'km'
  final DateTime timestamp;

  WorkoutSet({
    required this.id,
    required this.reps,
    this.repsUnit = 'reps',
    this.weight,
    this.weightUnit = 'kg',
    required this.timestamp,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'reps': reps,
      'repsUnit': repsUnit,
      'weight': weight,
      'weightUnit': weightUnit,
      'timestamp': timestamp,
    };
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'reps': reps,
      'repsUnit': repsUnit,
      'weight': weight,
      'weightUnit': weightUnit,
      'timestamp': timestamp.toIso8601String(),
    };
  }

  double get volume => (repsUnit == 'reps' && weightUnit == 'kg') ? (weight ?? 0) * reps : 0.0;

  factory WorkoutSet.fromMap(Map<String, dynamic> map) {
    DateTime ts;
    if (map['timestamp'] is Timestamp) {
      ts = (map['timestamp'] as Timestamp).toDate();
    } else if (map['timestamp'] is String) {
      ts = DateTime.parse(map['timestamp']);
    } else {
      ts = DateTime.now();
    }

    return WorkoutSet(
      id: map['id'] ?? '',
      reps: map['reps'] ?? 0,
      repsUnit: map['repsUnit'] ?? 'reps',
      weight: (map['weight'] as num?)?.toDouble(),
      weightUnit: map['weightUnit'] ?? 'kg',
      timestamp: ts,
    );
  }
}
