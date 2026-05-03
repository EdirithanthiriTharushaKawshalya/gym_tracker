import '../models/workout_template.dart';

class WorkoutSchedule {
  final String id;
  final String name;
  final String? description;
  final DateTime createdAt;
  final List<WorkoutTemplate> templates;

  WorkoutSchedule({
    required this.id,
    required this.name,
    this.description,
    required this.createdAt,
    required this.templates,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
      'description': description,
      'createdAt': createdAt.toIso8601String(),
      'templates': templates.map((t) => t.toMap()).toList(),
    };
  }

  factory WorkoutSchedule.fromMap(Map<String, dynamic> map) {
    return WorkoutSchedule(
      id: map['id'] ?? '',
      name: map['name'] ?? '',
      description: map['description'],
      createdAt: map['createdAt'] != null 
          ? DateTime.parse(map['createdAt']) 
          : DateTime.now(),
      templates: (map['templates'] as List? ?? [])
          .map((t) => WorkoutTemplate.fromMap(t as Map<String, dynamic>))
          .toList(),
    );
  }

  WorkoutSchedule copyWith({
    String? id,
    String? name,
    String? description,
    DateTime? createdAt,
    List<WorkoutTemplate>? templates,
  }) {
    return WorkoutSchedule(
      id: id ?? this.id,
      name: name ?? this.name,
      description: description ?? this.description,
      createdAt: createdAt ?? this.createdAt,
      templates: templates ?? this.templates,
    );
  }
}
