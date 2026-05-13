import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import '../providers/workout_provider.dart';
import '../models/workout_template.dart';
import '../services/visual_assets.dart';
import 'workout_screen.dart';

class ScheduleDetailsScreen extends StatelessWidget {
  final String scheduleName;
  final List<WorkoutTemplate> templates;
  final int startIndex;

  const ScheduleDetailsScreen({
    super.key,
    required this.scheduleName,
    required this.templates,
    this.startIndex = 0,
  });

  @override
  Widget build(BuildContext context) {
    final provider = Provider.of<WorkoutProvider>(context, listen: false);

    return Scaffold(
      appBar: AppBar(
        title: Text(scheduleName),
        leading: Padding(
          padding: const EdgeInsets.all(8.0),
          child: Center(
            child: GestureDetector(
              onTap: () => Navigator.pop(context),
              child: Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: const Color(0xFFF5F5F5),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Icon(Icons.arrow_back_ios_new, color: Color(0xFF121212), size: 16),
              ),
            ),
          ),
        ),
      ),
      body: ListView.builder(
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
        itemCount: templates.length,
        itemBuilder: (context, index) {
          final template = templates[index];
          final String image = VisualAssets.getDarkGymImage(startIndex + index);

          return GestureDetector(
            onTap: () async {
              final activeSession = provider.activeSession;
              
              // Case 1: Tapping the day that is already active
              if (activeSession?.templateId == template.id) {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => const WorkoutScreen()),
                );
                return;
              }

              // Case 2: Another day is active and has progress
              if (provider.hasActiveSessionProgress) {
                final bool? confirm = await showDialog<bool>(
                  context: context,
                  builder: (context) => AlertDialog(
                    title: const Text('Workout in Progress'),
                    content: Text('You are currently doing "${activeSession!.name}". Starting "${template.name}" will erase your current progress. Continue?'),
                    actions: [
                      TextButton(
                        onPressed: () => Navigator.pop(context, false),
                        child: const Text('CANCEL'),
                      ),
                      ElevatedButton(
                        style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
                        onPressed: () => Navigator.pop(context, true),
                        child: const Text('START NEW'),
                      ),
                    ],
                  ),
                );

                if (confirm != true) return;
              }

              // Case 3: No active session OR active session has no progress OR user confirmed overwrite
              provider.startSession(template, scheduleName);
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => const WorkoutScreen()),
              );
            },
            child: Container(
              margin: const EdgeInsets.only(bottom: 24),
              height: 180,
              decoration: BoxDecoration(
                color: const Color(0xFF121212),
                borderRadius: BorderRadius.circular(30),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.05),
                    blurRadius: 20,
                    offset: const Offset(0, 10),
                  ),
                ],
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(30),
                child: Stack(
                  children: [
                    VisualAssets.buildGymImage(image),
                    Container(
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: [Colors.black.withValues(alpha: 0.7), Colors.transparent],
                          begin: Alignment.bottomCenter,
                          end: Alignment.topCenter,
                        ),
                      ),
                    ),
                    Positioned(
                      bottom: 0,
                      left: 0,
                      right: 0,
                      child: Padding(
                        padding: const EdgeInsets.all(24.0),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          crossAxisAlignment: CrossAxisAlignment.end,
                          children: [
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Text(
                                    template.name.toUpperCase(),
                                    style: const TextStyle(
                                      color: Colors.white,
                                      fontSize: 18,
                                      fontWeight: FontWeight.w800,
                                    ),
                                  ),
                                  Text(
                                    '${template.exercises.length} Exercises',
                                    style: TextStyle(
                                      color: Colors.white.withValues(alpha: 0.8),
                                      fontSize: 14,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            Container(
                              padding: const EdgeInsets.all(12),
                              decoration: const BoxDecoration(
                                color: Colors.white,
                                shape: BoxShape.circle,
                              ),
                              child: const Icon(Icons.play_arrow, color: Color(0xFF121212), size: 20),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}
