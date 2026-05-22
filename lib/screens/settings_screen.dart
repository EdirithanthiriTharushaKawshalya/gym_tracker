import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../services/auth_service.dart';
import '../services/database_service.dart';
import 'about_screen.dart';

class SettingsScreen extends StatelessWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final dbService = DatabaseService();
    final authService = AuthService();

    return Scaffold(
      appBar: AppBar(
        title: const Text('Settings'),
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
      body: SingleChildScrollView(
        child: Column(
          children: [
            const SizedBox(height: 24),
            _SettingsTile(
              label: 'About Gym Tracker',
              icon: Icons.info_outline,
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => const AboutScreen()),
                );
              },
            ),
            _SettingsTile(
              label: 'Reset Discovery Hints',
              icon: Icons.lightbulb_outline,
              onTap: () => _confirmAction(
                context,
                'Reset Hints',
                'This will re-enable all one-time tutorial tips and notifications.',
                () async {
                  final prefs = await SharedPreferences.getInstance();
                  await prefs.remove('history_long_press_hint_seen');
                },
              ),
            ),
            const Padding(
              padding: EdgeInsets.symmetric(horizontal: 24.0, vertical: 16),
              child: Divider(color: Color(0xFFF5F5F5), thickness: 2),
            ),
            _SettingsTile(
              label: 'Clear All Schedules',
              icon: Icons.delete_outline,
              isDestructive: true,
              onTap: () => _confirmAction(
                context,
                'Clear Schedules',
                'This will permanently delete all your schedule folders.',
                () => dbService.clearAllSchedules(),
              ),
            ),
            _SettingsTile(
              label: 'Clear Workout History',
              icon: Icons.history,
              isDestructive: true,
              onTap: () => _confirmAction(
                context,
                'Clear History',
                'This will permanently delete every session you have logged.',
                () => dbService.clearAllSessions(),
              ),
            ),
            _SettingsTile(
              label: 'Logout',
              icon: Icons.logout,
              isDestructive: true,
              onTap: () {
                authService.signOut();
                Navigator.pop(context);
              },
            ),
            const Padding(
              padding: EdgeInsets.symmetric(horizontal: 24.0, vertical: 16),
              child: Divider(color: Color(0xFFF5F5F5), thickness: 2),
            ),
            const ListTile(
              contentPadding: EdgeInsets.symmetric(horizontal: 24),
              title: Text('Version', style: TextStyle(fontWeight: FontWeight.w600)),
              trailing: Text('1.0.0', style: TextStyle(color: Colors.grey)),
            ),
            const SizedBox(height: 40),
          ],
        ),
      ),
    );
  }

  void _confirmAction(BuildContext context, String title, String content, Future<void> Function() action) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: Colors.white,
        surfaceTintColor: Colors.transparent,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        title: Text(title, style: const TextStyle(fontWeight: FontWeight.bold)),
        content: Text(content),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel', style: TextStyle(color: Colors.grey)),
          ),
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
            child: const Text('Confirm', style: TextStyle(color: Colors.redAccent, fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );
  }
}

class _SettingsTile extends StatelessWidget {
  final String label;
  final IconData icon;
  final VoidCallback onTap;
  final bool isDestructive;

  const _SettingsTile({
    required this.label,
    required this.icon,
    required this.onTap,
    this.isDestructive = false,
  });

  @override
  Widget build(BuildContext context) {
    return ListTile(
      contentPadding: const EdgeInsets.symmetric(horizontal: 24, vertical: 8),
      leading: Container(
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          color: isDestructive ? Colors.redAccent.withOpacity(0.1) : const Color(0xFFF5F5F5),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Icon(icon, color: isDestructive ? Colors.redAccent : const Color(0xFF121212), size: 20),
      ),
      title: Text(
        label,
        style: TextStyle(
          fontSize: 16,
          fontWeight: FontWeight.w600,
          color: isDestructive ? Colors.redAccent : const Color(0xFF121212),
        ),
      ),
      trailing: Icon(
        Icons.chevron_right,
        color: isDestructive ? Colors.redAccent.withOpacity(0.5) : Colors.grey[400],
      ),
      onTap: onTap,
    );
  }
}
