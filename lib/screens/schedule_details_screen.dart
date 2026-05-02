import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/workout_provider.dart';
import '../models/workout_template.dart';
import 'workout_screen.dart';

class ScheduleDetailsScreen extends StatelessWidget {
  final String scheduleName;
  final List<WorkoutTemplate> templates;

  const ScheduleDetailsScreen({
    super.key,
    required this.scheduleName,
    required this.templates,
  });

  @override
  Widget build(BuildContext context) {
    final provider = Provider.of<WorkoutProvider>(context, listen: false);

    return Scaffold(
      appBar: AppBar(
        title: Text(scheduleName),
        centerTitle: true,
      ),
      body: ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: templates.length,
        itemBuilder: (context, index) {
          final template = templates[index];
          return Card(
            margin: const EdgeInsets.only(bottom: 12),
            child: ListTile(
              title: Text(template.name, style: const TextStyle(fontWeight: FontWeight.bold)),
              subtitle: Text('${template.exercises.length} exercises'),
              trailing: const Icon(Icons.play_arrow, color: Colors.green),
              onTap: () {
                provider.startSession(template, scheduleName);
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => const WorkoutScreen()),
                );
              },
            ),
          );
        },
      ),
    );
  }
}
