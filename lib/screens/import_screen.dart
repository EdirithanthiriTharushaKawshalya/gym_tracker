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
  final TextEditingController _descriptionController = TextEditingController();
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
    final name = _nameController.text.trim();
    final content = _textController.text.trim();

    if (name.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please enter a Program Name')),
      );
      return;
    }
    if (content.isEmpty || _previewSchedule == null || _previewSchedule!.templates.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please enter valid Workout Content')),
      );
      return;
    }

    final finalSchedule = WorkoutSchedule(
      id: _previewSchedule!.id,
      name: name,
      description: _descriptionController.text.isEmpty ? null : _descriptionController.text.trim(),
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

  Widget _buildAITip(BuildContext context) {
    const aiPrompt = """Act as an elite fitness coach. Reformat the following workout schedule into a structured, professional training plan.

RULES:
1. Organize exercises by muscle groups (e.g., [CHEST], [BACK], [LEGS], [CARDIO]).
2. Each training day must start with the day name (e.g., 1st Day, Day 1).
3. Exercise format: [Name] [Reps] [Reps]([Sets])
4. Do NOT include bullet points, hashtags, or introductory text. Only provide the formatted plan.

EXAMPLE:
Day 1
[CHEST]
Bench Press 12 10 8(2)
Incline Flys 12(3)

[TRICEPS]
Skull Crushers 10(3)

Day 2
[BACK]
Lat Pulldowns 12 10 8(2)""";

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: const Color(0xFF121212),
        borderRadius: BorderRadius.circular(32),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.2),
            blurRadius: 15,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.1),
                  shape: BoxShape.circle,
                ),
                child: const Icon(Icons.auto_awesome, size: 20, color: Colors.white),
              ),
              const SizedBox(width: 16),
              const Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'AI ASSISTED IMPORT',
                      style: TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.w900,
                        letterSpacing: 1.5,
                        fontSize: 12,
                      ),
                    ),
                    Text(
                      'Professional reformatting',
                      style: TextStyle(color: Colors.grey, fontSize: 11),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 24),
          const Text(
            'For the best experience, copy our professional coach prompt and use it with your favorite AI to format your schedule before pasting it here.',
            style: TextStyle(
              color: Colors.white,
              fontSize: 14,
              height: 1.5,
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: 24),
          InkWell(
            onTap: () {
              Clipboard.setData(const ClipboardData(text: aiPrompt));
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('Coach Prompt Copied!'),
                  behavior: SnackBarBehavior.floating,
                  width: 200,
                ),
              );
            },
            borderRadius: BorderRadius.circular(100),
            child: Container(
              padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 20),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(100),
              ),
              child: const Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.copy_rounded, size: 18, color: Color(0xFF121212)),
                  const SizedBox(width: 12),
                  Text(
                    'Copy Coach Prompt',
                    style: TextStyle(
                      color: Color(0xFF121212),
                      fontWeight: FontWeight.w800,
                      fontSize: 14,
                    ),
                  ),
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
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        centerTitle: true,
        title: const Text(
          'CREATE PROGRAM',
          style: TextStyle(fontWeight: FontWeight.w900, fontSize: 16, letterSpacing: 1.2),
        ),
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
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildAITip(context),
            const SizedBox(height: 40),
            _buildSectionHeader('Program Details'),
            const SizedBox(height: 20),
            _buildInputField(
              controller: _nameController,
              hint: 'Program Name (Required)',
              icon: Icons.edit_note_rounded,
            ),
            const SizedBox(height: 16),
            _buildInputField(
              controller: _descriptionController,
              hint: 'Program Description (optional)',
              icon: Icons.description_outlined,
              maxLines: 2,
            ),
            const SizedBox(height: 32),
            _buildSectionHeader('Workout Content'),
            const SizedBox(height: 20),
            Container(
              decoration: BoxDecoration(
                color: const Color(0xFFF8F8F8),
                borderRadius: BorderRadius.circular(40),
                border: Border.all(color: const Color(0xFFEEEEEE)),
              ),
              child: TextField(
                controller: _textController,
                maxLines: 12,
                onChanged: (_) => _parseText(),
                style: const TextStyle(fontSize: 14, height: 1.6, fontWeight: FontWeight.w500),
                decoration: const InputDecoration(
                  hintText: 'Paste workout text here... (Required)',
                  hintStyle: TextStyle(color: Colors.grey, fontSize: 13),
                  contentPadding: EdgeInsets.all(24),
                  border: InputBorder.none,
                  enabledBorder: InputBorder.none,
                  focusedBorder: InputBorder.none,
                  filled: false,
                ),
              ),
            ),
            const SizedBox(height: 40),
            if (_previewSchedule != null && _previewSchedule!.templates.isNotEmpty) ...[
              _buildSectionHeader('Plan Preview'),
              const SizedBox(height: 20),
              ..._previewSchedule!.templates.map((template) => _buildPreviewCard(template)),
              const SizedBox(height: 40),
              ElevatedButton(
                onPressed: _save,
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF121212),
                  foregroundColor: Colors.white,
                  minimumSize: const Size.fromHeight(65),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(100)),
                  elevation: 0,
                ),
                child: const Text(
                  'CONFIRM & SAVE PROGRAM',
                  style: TextStyle(fontWeight: FontWeight.w900, fontSize: 14, letterSpacing: 1),
                ),
              ),
              const SizedBox(height: 60),
            ] else
              _buildEmptyPreview(),
          ],
        ),
      ),
    );
  }

  Widget _buildSectionHeader(String title) {
    return Text(
      title.toUpperCase(),
      style: const TextStyle(
        fontWeight: FontWeight.w900,
        fontSize: 14,
        letterSpacing: 1.5,
        color: Color(0xFF121212),
      ),
    );
  }

  Widget _buildInputField({
    required TextEditingController controller,
    required String hint,
    required IconData icon,
    int maxLines = 1,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: const Color(0xFFF8F8F8),
        borderRadius: BorderRadius.circular(maxLines > 1 ? 32 : 100),
        border: Border.all(color: const Color(0xFFEEEEEE)),
      ),
      child: TextField(
        controller: controller,
        maxLines: maxLines,
        onChanged: (_) => _parseText(),
        decoration: InputDecoration(
          hintText: hint,
          prefixIcon: Padding(
            padding: const EdgeInsets.only(left: 16.0),
            child: Icon(icon, color: Colors.grey, size: 20),
          ),
          border: InputBorder.none,
          contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 18),
          filled: false,
        ),
      ),
    );
  }

  Widget _buildPreviewCard(template) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(32),
        border: Border.all(color: const Color(0xFFF0F0F0)),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: const Color(0xFF121212).withValues(alpha: 0.05),
              shape: BoxShape.circle,
            ),
            child: const Icon(Icons.fitness_center_rounded, size: 18, color: Color(0xFF121212)),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  template.name,
                  style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 15),
                ),
                const SizedBox(height: 4),
                Text(
                  '${template.exercises.length} Exercises',
                  style: TextStyle(color: Colors.grey[600], fontSize: 12, fontWeight: FontWeight.w600),
                ),
              ],
            ),
          ),
          const Icon(Icons.check_circle_rounded, color: Colors.green, size: 20),
        ],
      ),
    );
  }

  Widget _buildEmptyPreview() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(40.0),
        child: Column(
          children: [
            Icon(Icons.pending_actions_rounded, size: 48, color: Colors.grey[300]),
            const SizedBox(height: 16),
            Text(
              'Input your workout details to generate a professional preview.',
              textAlign: TextAlign.center,
              style: TextStyle(color: Colors.grey[500], fontSize: 13, height: 1.5, fontWeight: FontWeight.w500),
            ),
          ],
        ),
      ),
    );
  }
}
