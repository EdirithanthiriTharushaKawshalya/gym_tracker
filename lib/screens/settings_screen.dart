import 'package:flutter/material.dart';
import '../services/auth_service.dart';
import '../services/database_service.dart';

class SettingsScreen extends StatelessWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final dbService = DatabaseService();
    final authService = AuthService();

    return Scaffold(
      appBar: AppBar(
        title: const Text('Settings'),
        centerTitle: true,
      ),
      body: ListView(
        children: [
          const SectionHeader(title: 'Account'),
          ListTile(
            leading: const Icon(Icons.person),
            title: const Text('User ID'),
            subtitle: Text(authService.currentUserUid ?? 'Not logged in'),
          ),
          ListTile(
            leading: const Icon(Icons.logout, color: Colors.redAccent),
            title: const Text('Logout'),
            onTap: () {
              authService.signOut();
              Navigator.pop(context);
            },
          ),
          const Divider(),
          const SectionHeader(title: 'Data Management'),
          ListTile(
            leading: const Icon(Icons.delete_sweep, color: Colors.redAccent),
            title: const Text('Clear All Schedule Folders'),
            subtitle: const Text('Remove all imported programs'),
            onTap: () => _confirmAction(
              context,
              'Clear Schedules',
              'This will permanently delete all your schedule folders. Session history will be kept.',
              () => dbService.clearAllSchedules(),
            ),
          ),
          ListTile(
            leading: const Icon(Icons.history, color: Colors.redAccent),
            title: const Text('Clear Workout History'),
            subtitle: const Text('Remove all logged session data'),
            onTap: () => _confirmAction(
              context,
              'Clear History',
              'This will permanently delete every session you have logged. This cannot be undone.',
              () => dbService.clearAllSessions(),
            ),
          ),
          const Divider(),
          const SectionHeader(title: 'App Info'),
          const ListTile(
            leading: Icon(Icons.info_outline),
            title: Text('Version'),
            subtitle: Text('1.0.0 (Schedule Folder Edition)'),
          ),
        ],
      ),
    );
  }

  void _confirmAction(BuildContext context, String title, String content, Future<void> Function() action) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(title),
        content: Text(content),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancel')),
          TextButton(
            onPressed: () async {
              await action();
              if (context.mounted) {
                Navigator.pop(context);
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text('$title completed')),
                );
              }
            },
            child: const Text('Confirm', style: TextStyle(color: Colors.redAccent)),
          ),
        ],
      ),
    );
  }
}

class SectionHeader extends StatelessWidget {
  final String title;
  const SectionHeader({super.key, required this.title});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
      child: Text(
        title.toUpperCase(),
        style: TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.bold,
          color: Theme.of(context).colorScheme.primary,
          letterSpacing: 1.2,
        ),
      ),
    );
  }
}
