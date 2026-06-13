import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import '../providers/workout_provider.dart';
import '../models/exercise.dart';
import '../models/workout_set.dart';
import '../services/exercise_api_service.dart';
import '../services/visual_assets.dart';

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
                    padding: const EdgeInsets.only(right: 8.0),
                    child: Center(
                      child: TextButton(
                        onPressed: () => _showCancelDialog(context, provider),
                        child: Text(
                          'CANCEL',
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w800,
                            color: Colors.redAccent.withOpacity(0.8),
                          ),
                        ),
                      ),
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.only(right: 16.0),
                    child: Center(
                      child: ElevatedButton(
                        onPressed: () async {
                          await provider.endSession();
                          if (context.mounted) Navigator.pop(context);
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
                      return Padding(
                        padding: EdgeInsets.only(
                          left: isCollapsed ? 80.0 : 24.0,
                          right: isCollapsed ? 172.0 : 24.0,
                        ),
                        child: FittedBox(
                          fit: BoxFit.scaleDown,
                          child: Text(
                            session.name.toUpperCase(),
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              color: isCollapsed ? const Color(0xFF121212) : Colors.white,
                              fontWeight: FontWeight.w900,
                              fontSize: isCollapsed ? 15 : 18,
                              letterSpacing: 1,
                            ),
                          ),
                        ),
                      );
                    },
                  ),
                  background: Stack(
                    fit: StackFit.expand,
                    children: [
                      VisualAssets.buildGymImage(VisualAssets.getDarkGymImage(session.name.length)),
                      Container(
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            colors: [Colors.black.withValues(alpha: 0.7), Colors.transparent],
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
                    padding: const EdgeInsets.fromLTRB(24, 48, 24, 100),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Padding(
                          padding: const EdgeInsets.only(bottom: 24.0),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text(
                                'Target Exercises',
                                style: Theme.of(context).textTheme.titleLarge?.copyWith(
                                  fontWeight: FontWeight.w900,
                                  fontSize: 18,
                                ),
                              ),
                              Row(
                                children: [
                                  _ToggleButton(
                                    onPressed: () => provider.toggleAllGifsCollapsed(),
                                    isCollapsed: provider.allGifsCollapsed,
                                    collapsedIcon: Icons.image_not_supported_outlined,
                                    expandedIcon: Icons.image_outlined,
                                    label: 'GIFs',
                                  ),
                                  const SizedBox(width: 8),
                                  _ToggleButton(
                                    onPressed: () => provider.toggleAllSetsCollapsed(),
                                    isCollapsed: provider.allSetsCollapsed,
                                    collapsedIcon: Icons.unfold_less,
                                    expandedIcon: Icons.unfold_more,
                                    label: 'Sets',
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                        ..._buildCategorizedExercises(session.exercises),
                        const SizedBox(height: 32),
                        Center(
                          child: OutlinedButton.icon(
                            onPressed: () => _showAddExerciseDialog(context),
                            icon: const Icon(Icons.add, size: 18),
                            label: const Text('ADD EXERCISE', style: TextStyle(fontWeight: FontWeight.w900, letterSpacing: 1)),
                            style: OutlinedButton.styleFrom(
                              foregroundColor: const Color(0xFF121212),
                              side: const BorderSide(color: Color(0xFF121212), width: 2),
                              padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 16),
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(100)),
                            ),
                          ),
                        ),
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

  void _showCancelDialog(BuildContext context, WorkoutProvider provider) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: Colors.white,
        surfaceTintColor: Colors.transparent,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        title: const Text('Cancel Workout?', style: TextStyle(fontWeight: FontWeight.bold)),
        content: const Text('All progress for this session will be lost. This cannot be undone.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('KEEP GOING', style: TextStyle(color: Colors.grey, fontWeight: FontWeight.w600)),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.redAccent),
            onPressed: () async {
              await provider.cancelSession();
              if (context.mounted) {
                Navigator.pop(context); // Pop dialog
                Navigator.pop(context); // Pop WorkoutScreen
              }
            },
            child: const Text('CANCEL WORKOUT'),
          ),
        ],
      ),
    );
  }

  List<Widget> _buildCategorizedExercises(List<Exercise> exercises) {
    final Map<String, List<Exercise>> grouped = {};
    for (final ex in exercises) {
      grouped.putIfAbsent(ex.category, () => []).add(ex);
    }

    final List<Widget> widgets = [];
    int categoryIndex = 0;
    grouped.forEach((category, categoryExercises) {
      widgets.add(
        Padding(
          padding: EdgeInsets.only(
            bottom: 16.0, 
            top: categoryIndex == 0 ? 8.0 : 32.0, // More space between categories
          ),
          child: Row(
            children: [
              Container(
                width: 4,
                height: 16,
                decoration: BoxDecoration(
                  color: const Color(0xFF121212),
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              const SizedBox(width: 8),
              Text(
                category.toUpperCase(),
                style: const TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w900,
                  letterSpacing: 1.2,
                  color: Color(0xFF121212),
                ),
              ),
            ],
          ),
        ),
      );
      widgets.addAll(categoryExercises.map((exercise) => ExerciseCard(exercise: exercise)));
      categoryIndex++;
    });

    return widgets;
  }

  void _showAddExerciseDialog(BuildContext context) {
    final searchController = TextEditingController();
    final setsController = TextEditingController(text: '3');
    final repsController = TextEditingController(text: '12');
    final apiService = ExerciseApiService();
    ExerciseInfo? selectedExercise;

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          backgroundColor: Colors.white,
          surfaceTintColor: Colors.transparent,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
          title: const Text('Add One-time Exercise', style: TextStyle(fontWeight: FontWeight.bold)),
          content: SizedBox(
            width: double.maxFinite,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                if (selectedExercise == null) ...[
                  TextField(
                    controller: searchController,
                    decoration: const InputDecoration(
                      hintText: 'Search exercise...',
                      prefixIcon: Icon(Icons.search),
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
                              onTap: () {
                                setDialogState(() {
                                  selectedExercise = ex;
                                });
                              },
                            );
                          },
                        );
                      },
                    ),
                  ),
                ] else ...[
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: const Color(0xFFF5F5F5),
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: Row(
                      children: [
                        const Icon(Icons.fitness_center, color: Color(0xFF121212)),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(selectedExercise!.name.toUpperCase(), style: const TextStyle(fontWeight: FontWeight.bold)),
                              Text('${selectedExercise!.equipment} • ${selectedExercise!.bodyPart}', style: const TextStyle(fontSize: 12)),
                            ],
                          ),
                        ),
                        IconButton(
                          icon: const Icon(Icons.edit_outlined, size: 20),
                          onPressed: () => setDialogState(() => selectedExercise = null),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 24),
                  Row(
                    children: [
                      Expanded(
                        child: TextField(
                          controller: setsController,
                          decoration: const InputDecoration(labelText: 'Sets'),
                          keyboardType: TextInputType.number,
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: TextField(
                          controller: repsController,
                          decoration: const InputDecoration(labelText: 'Reps/Mins'),
                          keyboardType: TextInputType.number,
                        ),
                      ),
                    ],
                  ),
                ],
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancel', style: TextStyle(color: Colors.grey, fontWeight: FontWeight.w600)),
            ),
            if (selectedExercise != null)
              ElevatedButton(
                onPressed: () {
                  final sets = int.tryParse(setsController.text) ?? 3;
                  final reps = int.tryParse(repsController.text) ?? 12;
                  Provider.of<WorkoutProvider>(context, listen: false).addExerciseToActiveSession(
                    selectedExercise!.name,
                    selectedExercise!.bodyPart,
                    sets,
                    reps,
                  );
                  Navigator.pop(context);
                },
                child: const Text('Add to Session'),
              ),
          ],
        ),
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
                            _cleanExerciseName(widget.exercise.name),
                            style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w800),
                          ),
                        ),
                        IconButton(
                          onPressed: () => _showSearchDialog(context),
                          icon: Icon(Icons.search, color: Colors.grey[400], size: 18),
                          tooltip: 'Change exercise GIF',
                          visualDensity: VisualDensity.compact,
                        ),
                      ],
                    ),
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: const Color(0xFFF5F5F5),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    '${widget.exercise.targetSets} Sets',
                    style: const TextStyle(color: Color(0xFF121212), fontWeight: FontWeight.bold, fontSize: 10),
                  ),
                ),
                IconButton(
                  onPressed: () => provider.removeExerciseFromActiveSession(widget.exercise.id),
                  icon: const Icon(Icons.delete_outline, color: Colors.redAccent, size: 20),
                  tooltip: 'Remove exercise',
                ),
              ],
            ),
          ),
          if (!provider.allGifsCollapsed) ...[
            if (_loadingImage)
              const SizedBox(height: 200, child: Center(child: SizedBox(width: 24, height: 24, child: CircularProgressIndicator(strokeWidth: 2, color: Color(0xFF121212)))))
            else if (_imageUrl != null)
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 24),
                child: Column(
                  children: [
                    Container(
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
                    const SizedBox(height: 12),
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Icon(Icons.info_outline, size: 14, color: Colors.grey[600]),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            'Disclaimer: This GIF is automatically matched and may differ from the exact exercise intent. Please consult a coach before attempting any unfamiliar movements.',
                            style: TextStyle(
                              color: Colors.grey[600],
                              fontSize: 11,
                              fontWeight: FontWeight.w500,
                              height: 1.3,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 24), // Added padding for when sets are collapsed
                  ],
                ),
              )
            else
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 8),
                child: Container(
                  height: 100,
                  width: double.infinity,
                  decoration: BoxDecoration(
                    color: const Color(0xFFF8F8F8),
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(color: Colors.black.withOpacity(0.05)),
                  ),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.image_not_supported_outlined, size: 28, color: Colors.grey[400]),
                      const SizedBox(height: 8),
                      Text(
                        'GIF not available',
                        style: TextStyle(color: Colors.grey[600], fontWeight: FontWeight.bold, fontSize: 13),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'Tap the search icon to find manually',
                        style: TextStyle(color: Colors.grey[500], fontSize: 11),
                      ),
                    ],
                  ),
                ),
              ),
          ],
          if (!provider.allSetsCollapsed)
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
                                isCompleted 
                                    ? (widget.exercise.completedSets[index].repsUnit == 'mins' 
                                        ? '${widget.exercise.completedSets[index].reps} Mins' 
                                        : '${widget.exercise.completedSets[index].reps} Reps')
                                    : (widget.exercise.isCardio 
                                        ? '${widget.exercise.targetReps[index]} Mins'
                                        : '${widget.exercise.targetReps[index]} Reps'),
                                style: TextStyle(
                                  decoration: isCompleted ? TextDecoration.lineThrough : null,
                                  fontWeight: FontWeight.w700,
                                  fontSize: 15,
                                ),
                              ),
                              if (lastSet != null)
                                Text(
                                  lastSet.repsUnit == 'mins'
                                      ? 'Previous: ${lastSet.weight ?? 0}${lastSet.weightUnit} in ${lastSet.reps}m'
                                      : 'Previous: ${lastSet.weight ?? 0}${lastSet.weightUnit} x ${lastSet.reps}',
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
    
    // Default units based on exercise type and last set
    String currentWeightUnit = lastSet?.weightUnit ?? (exercise.measurementType == ExerciseMeasurementType.cardio ? 'km' : 'kg');
    String currentRepsUnit = lastSet?.repsUnit ?? (exercise.isCardio ? 'mins' : 'reps');

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) {
          String weightLabel;
          String weightHint;

          switch (exercise.measurementType) {
            case ExerciseMeasurementType.cardio:
              weightLabel = currentWeightUnit == 'km' ? 'Distance (km)' : 'Weight/Load (kg)';
              weightHint = 'Optional distance or weight';
              break;
            case ExerciseMeasurementType.bodyweight:
              weightLabel = 'Added Weight (kg) - Optional';
              weightHint = 'Leave blank if no extra weight';
              break;
            case ExerciseMeasurementType.weight:
            default:
              weightLabel = 'Weight (kg)';
              weightHint = 'Weight used for this set';
              break;
          }

          return AlertDialog(
            backgroundColor: Colors.white,
            surfaceTintColor: Colors.transparent,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
            title: Text('Log Set ${setIndex + 1}', style: const TextStyle(fontWeight: FontWeight.bold)),
            content: SingleChildScrollView(
              child: Column(
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
                            Expanded(
                              child: Text(
                                lastSet.repsUnit == 'mins'
                                  ? 'Last time: ${lastSet.weight}${lastSet.weightUnit} in ${lastSet.reps}m'
                                  : 'Last time: ${lastSet.weight}${lastSet.weightUnit} x ${lastSet.reps}', 
                                style: TextStyle(color: Colors.grey[700], fontSize: 13, fontWeight: FontWeight.w500)
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  
                  if (exercise.measurementType != ExerciseMeasurementType.weight) ...[
                    const Text('Measurement Basis', style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: Colors.grey)),
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        Expanded(
                          child: SegmentedButton<String>(
                            segments: const [
                              ButtonSegment(value: 'reps', label: Text('REPS'), icon: Icon(Icons.repeat, size: 14)),
                              ButtonSegment(value: 'mins', label: Text('MINS'), icon: Icon(Icons.timer_outlined, size: 14)),
                            ],
                            selected: {currentRepsUnit},
                            onSelectionChanged: (newSelection) => setDialogState(() => currentRepsUnit = newSelection.first),
                            style: SegmentedButton.styleFrom(
                              visualDensity: VisualDensity.compact,
                              selectedBackgroundColor: const Color(0xFF121212),
                              selectedForegroundColor: Colors.white,
                              textStyle: const TextStyle(fontSize: 10, fontWeight: FontWeight.bold),
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                  ],
                  
                  if (exercise.measurementType == ExerciseMeasurementType.cardio) ...[
                    const Text('Secondary Unit', style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: Colors.grey)),
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        Expanded(
                          child: SegmentedButton<String>(
                            segments: const [
                              ButtonSegment(value: 'km', label: Text('KM'), icon: Icon(Icons.directions_run, size: 14)),
                              ButtonSegment(value: 'kg', label: Text('KG'), icon: Icon(Icons.fitness_center, size: 14)),
                            ],
                            selected: {currentWeightUnit},
                            onSelectionChanged: (newSelection) => setDialogState(() => currentWeightUnit = newSelection.first),
                            style: SegmentedButton.styleFrom(
                              visualDensity: VisualDensity.compact,
                              selectedBackgroundColor: const Color(0xFF121212),
                              selectedForegroundColor: Colors.white,
                              textStyle: const TextStyle(fontSize: 10, fontWeight: FontWeight.bold),
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                  ],

                  TextField(
                    controller: repsController,
                    decoration: InputDecoration(
                      labelText: currentRepsUnit == 'mins' ? 'Duration (mins)' : 'Reps',
                      hintText: currentRepsUnit == 'mins' ? 'How many minutes?' : 'How many reps?',
                    ),
                    keyboardType: TextInputType.number,
                  ),
                  const SizedBox(height: 16),
                  TextField(
                    controller: weightController,
                    decoration: InputDecoration(
                      labelText: weightLabel,
                      hintText: weightHint,
                      helperText: exercise.measurementType == ExerciseMeasurementType.bodyweight 
                          ? 'Bodyweight only? Just leave this empty.' 
                          : null,
                      helperStyle: const TextStyle(fontSize: 10),
                    ),
                    keyboardType: TextInputType.number,
                    autofocus: true,
                  ),
                ],
              ),
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
                  Provider.of<WorkoutProvider>(context, listen: false).logSet(
                    exercise.id, 
                    reps, 
                    weight,
                    repsUnit: currentRepsUnit,
                    weightUnit: currentWeightUnit,
                  );
                  Navigator.pop(context);
                },
                child: const Text('Log Set'),
              ),
            ],
          );
        },
      ),
    );
  }
}

// Helper functions outside the classes to avoid duplication and scope issues
String _cleanExerciseName(String name) {
  final prefixes = ['stomach', 'abs', 'chest', 'back', 'legs', 'shoulders', 'biceps', 'triceps'];
  String cleaned = name.trim();
  
  // AI often adds formatting asterisks (e.g. **Bench Press**)
  cleaned = cleaned.replaceAll('*', '').trim();

  for (final prefix in prefixes) {
    final lowerName = cleaned.toLowerCase();
    if (lowerName.startsWith('$prefix ')) {
      cleaned = cleaned.substring(prefix.length + 1).trim();
      break;
    } else if (lowerName.startsWith('$prefix:')) {
      cleaned = cleaned.substring(prefix.length + 1).trim();
      break;
    }
  }
  
  return cleaned;
  }

class _ToggleButton extends StatelessWidget {
  final VoidCallback onPressed;
  final bool isCollapsed;
  final IconData collapsedIcon;
  final IconData expandedIcon;
  final String label;

  const _ToggleButton({
    required this.onPressed,
    required this.isCollapsed,
    required this.collapsedIcon,
    required this.expandedIcon,
    required this.label,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onPressed,
      borderRadius: BorderRadius.circular(10),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        decoration: BoxDecoration(
          color: isCollapsed ? const Color(0xFF121212) : const Color(0xFFF5F5F5),
          borderRadius: BorderRadius.circular(10),
        ),
        child: Row(
          children: [
            Icon(
              isCollapsed ? collapsedIcon : expandedIcon,
              size: 14,
              color: isCollapsed ? Colors.white : const Color(0xFF121212),
            ),
            const SizedBox(width: 6),
            Text(
              label,
              style: TextStyle(
                fontSize: 10,
                fontWeight: FontWeight.w700,
                color: isCollapsed ? Colors.white : const Color(0xFF121212),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
