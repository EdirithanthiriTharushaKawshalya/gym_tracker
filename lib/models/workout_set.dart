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

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'reps': reps,
      'weight': weight,
      'timestamp': timestamp.toIso8601String(),
    };
  }

  double get volume => (weight ?? 0) * reps;

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
      weight: (map['weight'] as num?)?.toDouble(),
      timestamp: ts,
    );
  }
}
