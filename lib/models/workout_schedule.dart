import '../models/workout_template.dart';

class WorkoutSchedule {
  final String id;
  final String name;
  final DateTime createdAt;
  final List<WorkoutTemplate> templates;

  WorkoutSchedule({
    required this.id,
    required this.name,
    required this.createdAt,
    required this.templates,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
      'createdAt': createdAt.toIso8601String(),
      'templates': templates.map((t) => t.toMap()).toList(),
    };
  }

  factory WorkoutSchedule.fromMap(Map<String, dynamic> map) {
    return WorkoutSchedule(
      id: map['id'] ?? '',
      name: map['name'] ?? '',
      createdAt: map['createdAt'] != null 
          ? DateTime.parse(map['createdAt']) 
          : DateTime.now(),
      templates: (map['templates'] as List? ?? [])
          .map((t) => WorkoutTemplate.fromMap(t as Map<String, dynamic>))
          .toList(),
    );
  }
}
