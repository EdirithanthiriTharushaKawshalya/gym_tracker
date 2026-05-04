import 'package:flutter/material.dart';
import '../services/auth_service.dart';
import '../services/database_service.dart';
import 'about_screen.dart';
import 'package:provider/provider.dart';
import '../providers/workout_provider.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  final AuthService _authService = AuthService();
  final DatabaseService _dbService = DatabaseService();

  String _getUserName() {
    final displayName = _authService.currentUserDisplayName;
    if (displayName != null && displayName.isNotEmpty) return displayName;
    
    final email = _authService.currentUserEmail;
    if (email == null || email.isEmpty) return 'Gym Member';
    final parts = email.split('@');
    final name = parts[0];
    return name[0].toUpperCase() + name.substring(1);
  }

  void _showEditNameDialog() {
    final controller = TextEditingController(text: _getUserName());
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: Colors.white,
        surfaceTintColor: Colors.transparent,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        title: const Text('Edit User Name', style: TextStyle(fontWeight: FontWeight.bold)),
        content: TextField(
          controller: controller,
          decoration: const InputDecoration(
            hintText: 'Enter your user name',
          ),
          autofocus: true,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel', style: TextStyle(color: Colors.grey)),
          ),
          ElevatedButton(
            onPressed: () async {
              if (controller.text.isNotEmpty) {
                await _authService.updateDisplayName(controller.text);
                if (mounted) {
                  setState(() {});
                  Navigator.pop(context);
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Name updated successfully')),
                  );
                }
              }
            },
            child: const Text('Save'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final userEmail = _authService.currentUserEmail;
    final userName = _getUserName();

    return Scaffold(
      appBar: AppBar(
        title: const Text('Profile'),
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
            const SizedBox(height: 32),
            const Center(
              child: CircleAvatar(
                radius: 60,
                backgroundColor: Color(0xFF121212),
                child: Icon(Icons.person, size: 60, color: Colors.white),
              ),
            ),
            const SizedBox(height: 16),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const SizedBox(width: 48), // Spacer for centering
                Text(
                  userName,
                  style: Theme.of(context).textTheme.headlineMedium,
                ),
                IconButton(
                  icon: const Icon(Icons.edit_outlined, size: 20, color: Colors.grey),
                  onPressed: _showEditNameDialog,
                ),
              ],
            ),
            Text(
              userEmail ?? 'Guest',
              style: Theme.of(context).textTheme.bodyMedium,
            ),
            const SizedBox(height: 40),
            const Padding(
              padding: EdgeInsets.symmetric(horizontal: 24.0),
              child: Divider(color: Color(0xFFF5F5F5), thickness: 2),
            ),
            _ProfileOptionTile(
              label: 'About Gym Tracker',
              icon: Icons.info_outline,
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => const AboutScreen()),
                );
              },
            ),
            _ProfileOptionTile(
              label: 'Clear All Schedules',
              icon: Icons.delete_outline,
              isDestructive: true,
              onTap: () => _confirmAction(
                context,
                'Clear Schedules',
                'This will permanently delete all your schedule folders.',
                () => _dbService.clearAllSchedules(),
              ),
            ),
            _ProfileOptionTile(
              label: 'Reset Today\'s Data',
              icon: Icons.refresh,
              isDestructive: true,
              onTap: () => _confirmAction(
                context,
                'Reset Today\'s Data',
                'This will permanently delete all workouts logged today. They will not be counted in your daily/weekly volume.',
                () => Provider.of<WorkoutProvider>(context, listen: false).resetToday(),
              ),
            ),
            _ProfileOptionTile(
              label: 'Clear Workout History',
              icon: Icons.history,
              isDestructive: true,
              onTap: () => _confirmAction(
                context,
                'Clear History',
                'This will permanently delete every session you have logged.',
                () => _dbService.clearAllSessions(),
              ),
            ),
            _ProfileOptionTile(
              label: 'Logout',
              icon: Icons.logout,
              isDestructive: true,
              onTap: () {
                _authService.signOut();
                Navigator.pop(context);
              },
            ),
            const Padding(
              padding: EdgeInsets.symmetric(horizontal: 24.0),
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

class _ProfileOptionTile extends StatelessWidget {
  final String label;
  final IconData icon;
  final VoidCallback onTap;
  final bool isDestructive;

  const _ProfileOptionTile({
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
