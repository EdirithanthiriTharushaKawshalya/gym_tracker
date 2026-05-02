import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/workout_provider.dart';
import '../models/workout_schedule.dart';
import '../models/workout_session.dart';
import 'import_screen.dart';
import 'settings_screen.dart';
import 'schedule_details_screen.dart';
import 'package:intl/intl.dart';

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final provider = Provider.of<WorkoutProvider>(context);

    return DefaultTabController(
      length: 2,
      child: Scaffold(
        appBar: AppBar(
          title: const Text('GYM TRACKER'),
          titleTextStyle: const TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.w900,
            letterSpacing: 1.5,
          ),
          centerTitle: true,
          actions: [
            IconButton(
              icon: const Icon(Icons.tune),
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => const SettingsScreen()),
                );
              },
            ),
          ],
          bottom: const TabBar(
            indicatorSize: TabBarIndicatorSize.label,
            indicatorWeight: 3,
            tabs: [
              Tab(text: 'MY PROGRAMS'),
              Tab(text: 'HISTORY'),
            ],
          ),
        ),
        body: TabBarView(
          children: [
            _SchedulesTab(provider: provider),
            _HistoryTab(provider: provider),
          ],
        ),
        floatingActionButton: FloatingActionButton.extended(
          onPressed: () {
            Navigator.push(
              context,
              MaterialPageRoute(builder: (context) => const ImportScreen()),
            );
          },
          label: const Text('NEW PROGRAM'),
          icon: const Icon(Icons.add),
          backgroundColor: Theme.of(context).colorScheme.primaryContainer,
          foregroundColor: Theme.of(context).colorScheme.onPrimaryContainer,
        ),
      ),
    );
  }
}

class _SchedulesTab extends StatelessWidget {
  final WorkoutProvider provider;
  const _SchedulesTab({required this.provider});

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<List<WorkoutSchedule>>(
      stream: provider.getSchedules(),
      builder: (context, snapshot) {
        if (!snapshot.hasData || snapshot.data!.isEmpty) {
          return const Center(
            child: Text(
              'No active programs.\nTap "+" to import your schedule.',
              textAlign: TextAlign.center,
              style: TextStyle(color: Colors.grey),
            ),
          );
        }
        final schedules = snapshot.data!;
        return ListView.builder(
          padding: const EdgeInsets.all(20),
          itemCount: schedules.length,
          itemBuilder: (context, index) {
            final schedule = schedules[index];
            return ProgramCard(schedule: schedule);
          },
        );
      },
    );
  }
}

class ProgramCard extends StatelessWidget {
  final WorkoutSchedule schedule;
  const ProgramCard({super.key, required this.schedule});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => ScheduleDetailsScreen(
              scheduleName: schedule.name,
              templates: schedule.templates,
            ),
          ),
        );
      },
      child: Container(
        margin: const EdgeInsets.only(bottom: 20),
        height: 140,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(20),
          gradient: LinearGradient(
            colors: [
              Theme.of(context).colorScheme.surfaceVariant,
              Theme.of(context).colorScheme.surface,
            ],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.2),
              blurRadius: 10,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(20),
          child: Stack(
            children: [
              Positioned(
                right: -20,
                bottom: -20,
                child: Icon(
                  Icons.fitness_center,
                  size: 120,
                  color: Theme.of(context).colorScheme.primary.withOpacity(0.05),
                ),
              ),
              Padding(
                padding: const EdgeInsets.all(20.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          schedule.name.toUpperCase(),
                          style: const TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.w900,
                            letterSpacing: 1,
                          ),
                        ),
                        Text(
                          'Started ${DateFormat('MMMM d').format(schedule.createdAt)}',
                          style: TextStyle(
                            fontSize: 12,
                            color: Theme.of(context).colorScheme.outline,
                          ),
                        ),
                      ],
                    ),
                    Row(
                      children: [
                        _buildBadge(
                          context, 
                          '${schedule.templates.length} DAYS',
                          Icons.calendar_view_week,
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildBadge(BuildContext context, String label, IconData icon, {bool isPrimary = false}) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: isPrimary 
          ? Theme.of(context).colorScheme.primary.withOpacity(0.2)
          : Colors.white.withOpacity(0.05),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: isPrimary 
            ? Theme.of(context).colorScheme.primary.withOpacity(0.5)
            : Colors.white.withOpacity(0.1),
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            icon, 
            size: 12, 
            color: isPrimary ? Theme.of(context).colorScheme.primary : Colors.grey
          ),
          const SizedBox(width: 4),
          Text(
            label,
            style: TextStyle(
              fontSize: 10,
              fontWeight: FontWeight.bold,
              color: isPrimary ? Theme.of(context).colorScheme.primary : Colors.grey,
            ),
          ),
        ],
      ),
    );
  }
}

class _HistoryTab extends StatelessWidget {
  final WorkoutProvider provider;
  const _HistoryTab({required this.provider});

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<List<WorkoutSession>>(
      stream: provider.getSessionHistory(),
      builder: (context, snapshot) {
        if (!snapshot.hasData || snapshot.data!.isEmpty) {
          return const Center(child: Text('No sessions logged yet.'));
        }
        final sessions = snapshot.data!;
        
        // Group sessions by date for a cleaner look
        final Map<String, List<WorkoutSession>> groupedSessions = {};
        for (var session in sessions) {
          final dateKey = DateFormat('MMMM yyyy').format(session.date);
          groupedSessions.putIfAbsent(dateKey, () => []).add(session);
        }

        return ListView.builder(
          padding: const EdgeInsets.all(16),
          itemCount: groupedSessions.length,
          itemBuilder: (context, index) {
            final dateKey = groupedSessions.keys.elementAt(index);
            final monthSessions = groupedSessions[dateKey]!;

            return Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Padding(
                  padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 4),
                  child: Text(
                    dateKey.toUpperCase(),
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                      color: Theme.of(context).colorScheme.primary,
                      letterSpacing: 1,
                    ),
                  ),
                ),
                ...monthSessions.map((session) => Card(
                  margin: const EdgeInsets.only(bottom: 12),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  child: ListTile(
                    contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                    title: Row(
                      children: [
                        Text(
                          session.name, // The Workout Day (e.g., "1st day")
                          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                        ),
                        const Spacer(),
                        Text(
                          DateFormat('MMM d').format(session.date),
                          style: TextStyle(
                            fontSize: 12,
                            color: Theme.of(context).colorScheme.outline,
                          ),
                        ),
                      ],
                    ),
                    subtitle: Padding(
                      padding: const EdgeInsets.only(top: 4.0),
                      child: Row(
                        children: [
                          Icon(Icons.folder_open, size: 14, color: Theme.of(context).colorScheme.primary),
                          const SizedBox(width: 4),
                          Text(
                            session.scheduleName,
                            style: TextStyle(color: Theme.of(context).colorScheme.primary, fontSize: 12, fontWeight: FontWeight.w500),
                          ),
                        ],
                      ),
                    ),
                    trailing: const Icon(Icons.chevron_right, size: 20),
                    onTap: () {
                      // TODO: View session summary
                    },
                  ),
                )),
                const SizedBox(height: 16),
              ],
            );
          },
        );
      },
    );
  }
}
