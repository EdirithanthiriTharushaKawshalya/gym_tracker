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
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.primaryContainer.withOpacity(0.3),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Theme.of(context).colorScheme.primary.withOpacity(0.5)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.auto_awesome, size: 18, color: Theme.of(context).colorScheme.primary),
              const SizedBox(width: 8),
              const Text('PRO TIP: UNIVERSAL IMPORT', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12)),
            ],
          ),
          const SizedBox(height: 8),
          const Text(
            'Members of ANY gym can use this app. If your schedule is in a PDF or image, use an AI to reformat it:',
            style: TextStyle(fontSize: 11),
          ),
          const SizedBox(height: 12),
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: Colors.black26,
              borderRadius: BorderRadius.circular(8),
            ),
            child: Row(
              children: [
                const Expanded(
                  child: Text(
                    'Ask AI to: "Reformat into [Exercise Name] [Reps]..."',
                    style: TextStyle(fontSize: 10, fontStyle: FontStyle.italic, color: Colors.grey),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.copy, size: 16),
                  onPressed: () {
                    Clipboard.setData(const ClipboardData(text: aiPrompt));
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('AI Prompt copied!')),
                    );
                  },
                  padding: EdgeInsets.zero,
                  constraints: const BoxConstraints(),
                  tooltip: 'Copy full prompt',
                ),
              ],
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
        title: const Text('New Schedule'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            TextField(
              controller: _nameController,
              decoration: const InputDecoration(
                labelText: 'Schedule Name',
                hintText: 'e.g., Winter 8-Week Program',
                border: OutlineInputBorder(),
              ),
              onChanged: (_) => _parseText(),
            ),
            const SizedBox(height: 16),
            _buildAITip(context),
            const SizedBox(height: 16),
            TextField(
              controller: _textController,
              maxLines: 6,
              decoration: const InputDecoration(
                hintText: 'Paste reformatted text here...',
                border: OutlineInputBorder(),
              ),
              onChanged: (_) => _parseText(),
            ),
            const SizedBox(height: 16),
            Expanded(
              child: _previewSchedule == null || _previewSchedule!.templates.isEmpty
                  ? const Center(child: Text('Enter details to see a preview.'))
                  : Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Padding(
                          padding: EdgeInsets.symmetric(vertical: 8.0),
                          child: Text('Preview:', style: TextStyle(fontWeight: FontWeight.bold)),
                        ),
                        Expanded(
                          child: ListView.builder(
                            itemCount: _previewSchedule!.templates.length,
                            itemBuilder: (context, index) {
                              final template = _previewSchedule!.templates[index];
                              return Card(
                                child: ListTile(
                                  title: Text(template.name),
                                  subtitle: Text('${template.exercises.length} exercises'),
                                ),
                              );
                            },
                          ),
                        ),
                      ],
                    ),
            ),
            if (_previewSchedule != null && _previewSchedule!.templates.isNotEmpty)
              ElevatedButton(
                onPressed: _save,
                style: ElevatedButton.styleFrom(
                  minimumSize: const Size.fromHeight(50),
                ),
                child: const Text('Save Schedule Folder'),
              ),
          ],
        ),
      ),
    );
  }
}
