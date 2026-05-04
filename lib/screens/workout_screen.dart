import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
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
      body: Stack(
        children: [
          CustomScrollView(
            slivers: [
              SliverAppBar(
                expandedHeight: 300,
                pinned: true,
                stretch: true,
                backgroundColor: Colors.white,
                elevation: 0,
                leadingWidth: 70,
                leading: Padding(
                  padding: const EdgeInsets.only(left: 16.0),
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
                actions: [
                  Padding(
                    padding: const EdgeInsets.only(right: 16.0),
                    child: Center(
                      child: ElevatedButton(
                        onPressed: () {
                          provider.endSession();
                          Navigator.pop(context);
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF121212),
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                          minimumSize: Size.zero,
                        ),
                        child: const Text('FINISH', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w800)),
                      ),
                    ),
                  ),
                ],
                flexibleSpace: FlexibleSpaceBar(
                  centerTitle: true,
                  titlePadding: const EdgeInsets.only(bottom: 16),
                  title: LayoutBuilder(
                    builder: (context, constraints) {
                      final isCollapsed = constraints.biggest.height <= (kToolbarHeight + MediaQuery.of(context).padding.top);
                      return Text(
                        session.name.toUpperCase(),
                        style: TextStyle(
                          color: isCollapsed ? const Color(0xFF121212) : Colors.white,
                          fontWeight: FontWeight.w900,
                          fontSize: 18,
                          letterSpacing: 1,
                        ),
                      );
                    },
                  ),
                  background: Stack(
                    fit: StackFit.expand,
                    children: [
                      Image.network(
                        'https://images.unsplash.com/photo-1534438327276-14e5300c3a48?q=80&w=2070&auto=format&fit=crop',
                        fit: BoxFit.cover,
                      ),
                      Container(
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            colors: [Colors.black.withOpacity(0.7), Colors.transparent],
                            begin: Alignment.bottomCenter,
                            end: Alignment.topCenter,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              SliverToBoxAdapter(
                child: Transform.translate(
                  offset: const Offset(0, -32),
                  child: Container(
                    decoration: const BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.vertical(top: Radius.circular(32)),
                    ),
                    padding: const EdgeInsets.fromLTRB(24, 32, 24, 100),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Target Exercises',
                          style: Theme.of(context).textTheme.headlineMedium,
                        ),
                        const SizedBox(height: 24),
                        ...session.exercises.map((exercise) => ExerciseCard(exercise: exercise)),
                      ],
                    ),
                  ),
                ),
              ),
            ],
          ),
          if (provider.isTimerRunning)
            Positioned(
              left: 24,
              right: 24,
              bottom: 40,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
                decoration: BoxDecoration(
                  color: const Color(0xFF121212),
                  borderRadius: BorderRadius.circular(24),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.3),
                      blurRadius: 20,
                      offset: const Offset(0, 10),
                    ),
                  ],
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Row(
                      children: [
                        const Icon(Icons.timer_outlined, color: Colors.white, size: 24),
                        const SizedBox(width: 16),
                        Column(
                          mainAxisSize: MainAxisSize.min,
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'REST TIMER',
                              style: TextStyle(
                                color: Colors.white.withOpacity(0.6),
                                fontWeight: FontWeight.bold,
                                fontSize: 10,
                                letterSpacing: 1,
                              ),
                            ),
                            const Text(
                              'Take a breath',
                              style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 14),
                            ),
                          ],
                        ),
                      ],
                    ),
                    Row(
                      children: [
                        Text(
                          '${provider.timerSeconds}s',
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 24,
                            fontWeight: FontWeight.w900,
                          ),
                        ),
                        const SizedBox(width: 16),
                        GestureDetector(
                          onTap: () => provider.stopTimer(),
                          child: Container(
                            padding: const EdgeInsets.all(4),
                            decoration: BoxDecoration(
                              color: Colors.white.withOpacity(0.2),
                              shape: BoxShape.circle,
                            ),
                            child: const Icon(Icons.close, color: Colors.white, size: 16),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
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
    final provider = Provider.of<WorkoutProvider>(context, listen: false);
    final contextMuscleGroups = provider.activeSession?.targetMuscleGroups ?? [];
    final url = await ExerciseApiService().getImageUrl(widget.exercise.name, contextMuscleGroups: contextMuscleGroups);
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

    return Container(
      margin: const EdgeInsets.only(bottom: 32),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.all(24.0),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: GestureDetector(
                    onLongPress: () {
                      Clipboard.setData(ClipboardData(text: widget.exercise.name));
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text('Copied: ${widget.exercise.name}'),
                          duration: const Duration(seconds: 1),
                          behavior: SnackBarBehavior.floating,
                          width: 200,
                        ),
                      );
                    },
                    child: Row(
                      children: [
                        Expanded(
                          child: Text(
                            widget.exercise.name,
                            style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w800),
                          ),
                        ),
                        IconButton(
                          onPressed: () => _showSearchDialog(context),
                          icon: Icon(Icons.search, color: Colors.grey[400], size: 20),
                          tooltip: 'Change exercise GIF',
                          visualDensity: VisualDensity.compact,
                        ),
                      ],
                    ),
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: const Color(0xFFF5F5F5),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Text(
                    '${widget.exercise.targetSets} Sets',
                    style: const TextStyle(color: Color(0xFF121212), fontWeight: FontWeight.bold, fontSize: 12),
                  ),
                ),
              ],
            ),
          ),
          if (_loadingImage)
            const SizedBox(height: 200, child: Center(child: SizedBox(width: 24, height: 24, child: CircularProgressIndicator(strokeWidth: 2, color: Color(0xFF121212)))))
          else if (_imageUrl != null)
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24),
              child: Container(
                height: 200,
                width: double.infinity,
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(20),
                ),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(20),
                  child: Image.network(
                    _imageUrl!,
                    fit: BoxFit.contain,
                    errorBuilder: (_, __, ___) => const SizedBox.shrink(),
                  ),
                ),
              ),
            ),
          Padding(
            padding: const EdgeInsets.all(24.0),
            child: Column(
              children: List.generate(widget.exercise.targetSets, (index) {
                final isCompleted = index < widget.exercise.completedSets.length;
                
                WorkoutSet? lastSet;
                if (lastExercise != null && index < lastExercise.completedSets.length) {
                  lastSet = lastExercise.completedSets[index];
                }

                return Padding(
                  padding: const EdgeInsets.only(bottom: 16.0),
                  child: Row(
                    children: [
                      Container(
                        width: 36,
                        height: 36,
                        decoration: BoxDecoration(
                          color: isCompleted ? const Color(0xFF121212) : const Color(0xFFF5F5F5),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Center(
                          child: Text(
                            '${index + 1}',
                            style: TextStyle(
                              fontSize: 14,
                              color: isCompleted ? Colors.white : const Color(0xFF121212),
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              widget.exercise.isCardio 
                                  ? '${widget.exercise.targetReps[index]} Mins'
                                  : '${widget.exercise.targetReps[index]} Reps',
                              style: TextStyle(
                                decoration: isCompleted ? TextDecoration.lineThrough : null,
                                fontWeight: FontWeight.w700,
                                fontSize: 15,
                              ),
                            ),
                            if (lastSet != null)
                              Text(
                                widget.exercise.isCardio
                                    ? 'Previous: ${lastSet.weight}km in ${lastSet.reps}m'
                                    : 'Previous: ${lastSet.weight}kg x ${lastSet.reps}',
                                style: TextStyle(color: Colors.grey[500], fontSize: 12),
                              ),
                          ],
                        ),
                      ),
                      if (isCompleted)
                        const Icon(Icons.check_circle, color: Color(0xFF121212), size: 28)
                      else
                        GestureDetector(
                          onTap: () => _showLogDialog(context, widget.exercise, index, lastSet),
                          child: Container(
                            padding: const EdgeInsets.all(8),
                            decoration: BoxDecoration(
                              color: const Color(0xFF121212),
                              borderRadius: BorderRadius.circular(10),
                            ),
                            child: const Icon(Icons.add, color: Colors.white, size: 20),
                          ),
                        ),
                    ],
                  ),
                );
              }),
            ),
          ),
        ],
      ),
    );
  }

  void _showSearchDialog(BuildContext context) {
    final searchController = TextEditingController(text: widget.exercise.name);
    final apiService = ExerciseApiService();
    
    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          backgroundColor: Colors.white,
          surfaceTintColor: Colors.transparent,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
          title: const Text('Find Correct Exercise', style: TextStyle(fontWeight: FontWeight.bold)),
          content: SizedBox(
            width: double.maxFinite,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(
                  controller: searchController,
                  decoration: InputDecoration(
                    hintText: 'Search exercise...',
                    prefixIcon: const Icon(Icons.search),
                    suffixIcon: IconButton(
                      icon: const Icon(Icons.clear),
                      onPressed: () {
                        searchController.clear();
                        setDialogState(() {});
                      },
                    ),
                  ),
                  onChanged: (_) => setDialogState(() {}),
                  autofocus: true,
                ),
                const SizedBox(height: 16),
                Flexible(
                  child: FutureBuilder<List<ExerciseInfo>>(
                    future: apiService.searchExercises(searchController.text),
                    builder: (context, snapshot) {
                      if (snapshot.connectionState == ConnectionState.waiting) {
                        return const Center(child: Padding(
                          padding: EdgeInsets.all(24.0),
                          child: CircularProgressIndicator(strokeWidth: 2, color: Color(0xFF121212)),
                        ));
                      }
                      
                      final results = snapshot.data ?? [];
                      if (results.isEmpty) {
                        return const Padding(
                          padding: EdgeInsets.all(24.0),
                          child: Text('No matching exercises found'),
                        );
                      }

                      return ListView.builder(
                        shrinkWrap: true,
                        itemCount: results.length,
                        itemBuilder: (context, index) {
                          final ex = results[index];
                          return ListTile(
                            contentPadding: const EdgeInsets.symmetric(horizontal: 8),
                            title: Text(ex.name.toUpperCase(), style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
                            subtitle: Text('${ex.equipment} • ${ex.bodyPart}', style: const TextStyle(fontSize: 11)),
                            trailing: const Icon(Icons.chevron_right, size: 16),
                            onTap: () {
                              final newUrl = ExerciseApiService.buildGifUrl(ex.id);
                              setState(() {
                                _imageUrl = newUrl;
                              });
                              Navigator.pop(context);
                            },
                          );
                        },
                      );
                    },
                  ),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancel', style: TextStyle(color: Colors.grey, fontWeight: FontWeight.w600)),
            ),
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
        backgroundColor: Colors.white,
        surfaceTintColor: Colors.transparent,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        title: Text('Log Set ${setIndex + 1}', style: const TextStyle(fontWeight: FontWeight.bold)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (lastSet != null)
              Padding(
                padding: const EdgeInsets.only(bottom: 16.0),
                child: Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: const Color(0xFFF5F5F5),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.history, size: 16, color: Colors.grey),
                      const SizedBox(width: 8),
                      Text(exercise.isCardio ? 'Last time: ${lastSet.weight}km in ${lastSet.reps}m' : 'Last time: ${lastSet.weight}kg x ${lastSet.reps}', 
                           style: TextStyle(color: Colors.grey[700], fontSize: 13, fontWeight: FontWeight.w500)),
                    ],
                  ),
                ),
              ),
            TextField(
              controller: repsController,
              decoration: InputDecoration(labelText: exercise.isCardio ? 'Duration (mins)' : 'Reps'),
              keyboardType: TextInputType.number,
            ),
            const SizedBox(height: 16),
            TextField(
              controller: weightController,
              decoration: InputDecoration(labelText: exercise.isCardio ? 'Distance (km) - Optional' : 'Weight (kg)'),
              keyboardType: TextInputType.number,
              autofocus: true,
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel', style: TextStyle(color: Colors.grey, fontWeight: FontWeight.w600)),
          ),
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
