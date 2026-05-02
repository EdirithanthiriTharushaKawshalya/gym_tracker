import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/workout_provider.dart';
import '../models/exercise.dart';
import '../models/workout_set.dart';
import '../services/exercise_api_service.dart';

class WorkoutScreen extends StatelessWidget {
  const WorkoutScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final provider = Provider.of<WorkoutProvider>(context);
    final session = provider.activeSession;

    if (session == null) {
      return const Scaffold(
        body: Center(
          child: CircularProgressIndicator(),
        ),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: Text(session.name),
        leading: IconButton(
          icon: const Icon(Icons.close),
          onPressed: () {
            provider.cancelSession();
            Navigator.pop(context);
          },
        ),
        actions: [
          TextButton(
            onPressed: () {
              provider.endSession();
              Navigator.pop(context);
            },
            child: const Text(
              'FINISH',
              style: TextStyle(color: Colors.green, fontWeight: FontWeight.bold),
            ),
          ),
        ],
      ),
      body: Column(
        children: [
          if (provider.isTimerRunning)
            Container(
              color: Colors.green[900],
              padding: const EdgeInsets.symmetric(vertical: 8),
              width: double.infinity,
              child: Center(
                child: Text(
                  'Rest Timer: ${provider.timerSeconds}s',
                  style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18, color: Colors.white),
                ),
              ),
            ),
          Expanded(
            child: ListView.builder(
              itemCount: session.exercises.length,
              itemBuilder: (context, index) {
                final exercise = session.exercises[index];
                return ExerciseCard(exercise: exercise);
              },
            ),
          ),
        ],
      ),
    );
  }
}

class ExerciseCard extends StatefulWidget {
  final Exercise exercise;

  const ExerciseCard({super.key, required this.exercise});

  @override
  State<ExerciseCard> createState() => _ExerciseCardState();
}

class _ExerciseCardState extends State<ExerciseCard> {
  String? _imageUrl;
  bool _loadingImage = true;

  @override
  void initState() {
    super.initState();
    _fetchImage();
  }

  Future<void> _fetchImage() async {
    final url = await ExerciseApiService().getImageUrl(widget.exercise.name);
    if (mounted) {
      setState(() {
        _imageUrl = url;
        _loadingImage = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final provider = Provider.of<WorkoutProvider>(context);
    final lastSession = provider.lastSession;
    
    Exercise? lastExercise;
    if (lastSession != null) {
      try {
        lastExercise = lastSession.exercises.firstWhere((e) => e.name == widget.exercise.name);
      } catch (_) {
        lastExercise = null;
      }
    }

    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              widget.exercise.name,
              style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            Container(
              height: 180,
              width: double.infinity,
              decoration: BoxDecoration(
                color: Colors.black26,
                borderRadius: BorderRadius.circular(8),
              ),
              child: _loadingImage
                  ? const Center(child: CircularProgressIndicator())
                  : _imageUrl != null
                      ? ClipRRect(
                          borderRadius: BorderRadius.circular(8),
                          child: Image.network(
                            _imageUrl!,
                            fit: BoxFit.cover,
                            errorBuilder: (_, __, ___) => const Icon(Icons.broken_image, size: 50),
                          ),
                        )
                      : const Center(child: Icon(Icons.fitness_center, size: 50)),
            ),
            const SizedBox(height: 16),
            ...List.generate(widget.exercise.targetSets, (index) {
              final isCompleted = index < widget.exercise.completedSets.length;
              
              WorkoutSet? lastSet;
              if (lastExercise != null && index < lastExercise.completedSets.length) {
                lastSet = lastExercise.completedSets[index];
              }

              return ListTile(
                dense: true,
                contentPadding: EdgeInsets.zero,
                leading: CircleAvatar(
                  radius: 14,
                  backgroundColor: isCompleted ? Colors.green : Colors.grey[700],
                  child: Text('${index + 1}', style: const TextStyle(fontSize: 12, color: Colors.white)),
                ),
                title: Text('${widget.exercise.targetReps[index]} reps', 
                           style: TextStyle(decoration: isCompleted ? TextDecoration.lineThrough : null)),
                subtitle: lastSet != null 
                    ? Text('Last: ${lastSet.weight}kg x ${lastSet.reps}', 
                           style: TextStyle(color: Colors.blueGrey[300], fontSize: 11))
                    : null,
                trailing: isCompleted
                    ? const Icon(Icons.check_circle, color: Colors.green)
                    : IconButton(
                        icon: const Icon(Icons.add_circle_outline),
                        onPressed: () => _showLogDialog(context, widget.exercise, index, lastSet),
                      ),
              );
            }),
          ],
        ),
      ),
    );
  }

  void _showLogDialog(BuildContext context, Exercise exercise, int setIndex, WorkoutSet? lastSet) {
    final repsController = TextEditingController(text: exercise.targetReps[setIndex].toString());
    final weightController = TextEditingController(text: lastSet?.weight?.toString() ?? '');

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Log Set ${setIndex + 1}'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (lastSet != null)
              Padding(
                padding: const EdgeInsets.only(bottom: 12.0),
                child: Text('Previous: ${lastSet.weight}kg x ${lastSet.reps}', 
                           style: const TextStyle(color: Colors.blueGrey, fontStyle: FontStyle.italic)),
              ),
            TextField(
              controller: repsController,
              decoration: const InputDecoration(labelText: 'Reps'),
              keyboardType: TextInputType.number,
            ),
            TextField(
              controller: weightController,
              decoration: const InputDecoration(labelText: 'Weight (kg)'),
              keyboardType: TextInputType.number,
              autofocus: true,
            ),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancel')),
          ElevatedButton(
            onPressed: () {
              final reps = int.tryParse(repsController.text) ?? 0;
              final weight = double.tryParse(weightController.text) ?? 0.0;
              Provider.of<WorkoutProvider>(context, listen: false).logSet(exercise.id, reps, weight);
              Navigator.pop(context);
            },
            child: const Text('Log Set'),
          ),
        ],
      ),
    );
  }
}
