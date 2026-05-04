import 'workout_set.dart';

class Exercise {
  final String id;
  final String name;
  final List<int> targetReps;
  final List<WorkoutSet> completedSets;
  final String? gifUrl;

  Exercise({
    required this.id,
    required this.name,
    required this.targetReps,
    this.completedSets = const [],
    this.gifUrl,
  });

  int get targetSets => targetReps.length;

  double get totalVolume => completedSets.fold(0.0, (sum, set) => sum + set.volume);

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
      'targetReps': targetReps,
      'completedSets': completedSets.map((s) => s.toMap()).toList(),
      'gifUrl': gifUrl,
    };
  }

  factory Exercise.fromMap(Map<String, dynamic> map) {
    return Exercise(
      id: map['id'] ?? '',
      name: map['name'] ?? '',
      targetReps: List<int>.from(map['targetReps'] ?? []),
      completedSets: (map['completedSets'] as List? ?? [])
          .map((s) => WorkoutSet.fromMap(s as Map<String, dynamic>))
          .toList(),
      gifUrl: map['gifUrl'],
    );
  }

  Exercise copyWith({
    List<WorkoutSet>? completedSets,
    String? gifUrl,
  }) {
    return Exercise(
      id: id,
      name: name,
      targetReps: targetReps,
      completedSets: completedSets ?? this.completedSets,
      gifUrl: gifUrl ?? this.gifUrl,
    );
  }
}
