import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../services/workout_parser.dart';
import '../models/workout_schedule.dart';
import '../services/database_service.dart';

class ImportScreen extends StatefulWidget {
  const ImportScreen({super.key});

  @override
  State<ImportScreen> createState() => _ImportScreenState();
}

class _ImportScreenState extends State<ImportScreen> {
  final TextEditingController _textController = TextEditingController();
  final TextEditingController _nameController = TextEditingController();
  WorkoutSchedule? _previewSchedule;
  final DatabaseService _dbService = DatabaseService();

  void _parseText() {
    if (_textController.text.isNotEmpty) {
      setState(() {
        _previewSchedule = WorkoutParser.parse(
          _textController.text,
          _nameController.text.isEmpty ? 'New Schedule' : _nameController.text,
        );
      });
    }
  }

  Future<void> _save() async {
    if (_previewSchedule != null) {
      final finalSchedule = WorkoutSchedule(
        id: _previewSchedule!.id,
        name: _nameController.text.isEmpty ? 'New Schedule' : _nameController.text,
        createdAt: _previewSchedule!.createdAt,
        templates: _previewSchedule!.templates,
      );
      
      await _dbService.saveSchedule(finalSchedule);
      if (mounted) {
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Schedule saved successfully!')),
        );
      }
    }
  }

  Widget _buildAITip(BuildContext context) {
    const aiPrompt = """Convert my workout schedule into this exact format:
[Number]st/nd/rd/th day
Exercise Name [reps] [reps]([sets])

Example:
1st day
Bench Press 12 10 8(2)
Skull Crunches 10 8(3)""";

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: const Color(0xFF121212),
        borderRadius: BorderRadius.circular(24),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.auto_awesome, size: 20, color: Colors.white),
              const SizedBox(width: 12),
              Text(
                'UNIVERSAL IMPORT',
                style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                  letterSpacing: 1,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            'Paste your schedule below. Use AI to format it first for the best experience.',
            style: TextStyle(color: Colors.white.withOpacity(0.7), fontSize: 13),
          ),
          const SizedBox(height: 20),
          GestureDetector(
            onTap: () {
              Clipboard.setData(const ClipboardData(text: aiPrompt));
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('AI Prompt copied!')),
              );
            },
            child: Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.1),
                borderRadius: BorderRadius.circular(16),
              ),
              child: Row(
                children: [
                  const Expanded(
                    child: Text(
                      'Copy AI Reformat Prompt',
                      style: TextStyle(color: Colors.white, fontWeight: FontWeight.w600),
                    ),
                  ),
                  Icon(Icons.copy, size: 18, color: Colors.white.withOpacity(0.5)),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('New Program'),
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
        padding: const EdgeInsets.all(24.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildAITip(context),
            const SizedBox(height: 32),
            Text('Program Details', style: Theme.of(context).textTheme.headlineMedium),
            const SizedBox(height: 20),
            TextField(
              controller: _nameController,
              decoration: const InputDecoration(
                hintText: 'Program Name (e.g. Summer Shred)',
              ),
              onChanged: (_) => _parseText(),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: _textController,
              maxLines: 8,
              decoration: const InputDecoration(
                hintText: 'Paste formatted schedule text here...',
              ),
              onChanged: (_) => _parseText(),
            ),
            const SizedBox(height: 32),
            if (_previewSchedule != null && _previewSchedule!.templates.isNotEmpty) ...[
              Text('Preview', style: Theme.of(context).textTheme.headlineMedium),
              const SizedBox(height: 16),
              ..._previewSchedule!.templates.map((template) => Container(
                margin: const EdgeInsets.only(bottom: 12),
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: const Color(0xFFF5F5F5),
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.calendar_today, size: 18, color: Color(0xFF121212)),
                    const SizedBox(width: 12),
                    Text(
                      template.name,
                      style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                    ),
                    const Spacer(),
                    Text(
                      '${template.exercises.length} Exercises',
                      style: TextStyle(color: Colors.grey[600], fontSize: 12),
                    ),
                  ],
                ),
              )),
              const SizedBox(height: 32),
              ElevatedButton(
                onPressed: _save,
                style: ElevatedButton.styleFrom(
                  minimumSize: const Size.fromHeight(60),
                ),
                child: const Text('Save Program'),
              ),
              const SizedBox(height: 40),
            ] else
              const Center(
                child: Padding(
                  padding: EdgeInsets.all(40.0),
                  child: Text(
                    'Enter details above to see a preview of your program.',
                    textAlign: TextAlign.center,
                    style: TextStyle(color: Colors.grey),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}
