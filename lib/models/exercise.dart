import 'workout_set.dart';

enum ExerciseMeasurementType { weight, cardio, bodyweight }

class Exercise {
  final String id;
  final String name;
  final List<int> targetReps;
  final List<WorkoutSet> completedSets;
  final String? gifUrl;
  final String category;

  Exercise({
    required this.id,
    required this.name,
    required this.targetReps,
    this.completedSets = const [],
    this.gifUrl,
    this.category = 'Other',
  });

  int get targetSets => targetReps.length;

  bool get isCardio => measurementType == ExerciseMeasurementType.cardio;

  ExerciseMeasurementType get measurementType {
    final lowerName = name.toLowerCase();
    
    // Cardio Keywords
    const cardioKeywords = ['treadmill', 'bike', 'bicycle', 'cycling', 'run', 'walk', 'elliptical', 'stair', 'rowing', 'cardio', 'swimming'];
    if (cardioKeywords.any((word) => lowerName.contains(word))) {
      return ExerciseMeasurementType.cardio;
    }

    // Bodyweight Keywords
    const bodyweightKeywords = [
      'crunch', 'plank', 'sit up', 'sit-up', 'leg raise', 'push up', 'push-up', 
      'pull up', 'pull-up', 'dip', 'bodyweight', 'calisthenics', 'mountain climber',
      'burpee', 'squat jump', 'lunges'
    ];
    
    // If it contains bodyweight keywords AND doesn't mention equipment like dumbbell/barbell/kettlebell
    final mentionsEquipment = lowerName.contains('dumbbell') || 
                              lowerName.contains('barbell') || 
                              lowerName.contains('kettlebell') || 
                              lowerName.contains('machine') || 
                              lowerName.contains('cable') ||
                              lowerName.contains('lever');

    if (bodyweightKeywords.any((word) => lowerName.contains(word)) && !mentionsEquipment) {
      return ExerciseMeasurementType.bodyweight;
    }

    return ExerciseMeasurementType.weight;
  }

  double get totalVolume => isCardio ? 0.0 : completedSets.fold(0.0, (sum, set) => sum + set.volume);

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
      'targetReps': targetReps,
      'completedSets': completedSets.map((s) => s.toMap()).toList(),
      'gifUrl': gifUrl,
      'category': category,
    };
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'targetReps': targetReps,
      'completedSets': completedSets.map((s) => s.toJson()).toList(),
      'gifUrl': gifUrl,
      'category': category,
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
      category: map['category'] ?? 'Other',
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
      category: category,
    );
  }
}
