import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:habit_tracker/models/habit.dart';
import 'package:habit_tracker/models/journal_entry.dart';
import 'package:habit_tracker/services/journal_service.dart';

class JournalEntryScreen extends StatefulWidget {
  final Habit habit;
  final JournalEntry? existingEntry;

  const JournalEntryScreen({
    super.key,
    required this.habit,
    this.existingEntry,
  });

  @override
  State<JournalEntryScreen> createState() => _JournalEntryScreenState();
}

class _JournalEntryScreenState extends State<JournalEntryScreen> {
  final _contentController = TextEditingController();
  String _selectedMood = 'good';
  final List<String> _prompts = [
    'What went well today?',
    'What challenges did you face?',
    'How can you improve tomorrow?',
    'What are you grateful for?',
    'How did this habit make you feel?',
  ];
  String? _selectedPrompt;

  @override
  void initState() {
    super.initState();
    if (widget.existingEntry != null) {
      _contentController.text = widget.existingEntry!.content;
      _selectedMood = widget.existingEntry!.mood;
    }
  }

  @override
  void dispose() {
    _contentController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Journal Entry'),
        actions: [
          TextButton(
            onPressed: _saveEntry,
            child: const Text('Save'),
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'How are you feeling about your progress?',
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: 16),
            _buildMoodSelector(),
            const SizedBox(height: 24),
            _buildPromptSelector(),
            const SizedBox(height: 24),
            TextField(
              controller: _contentController,
              maxLines: 10,
              decoration: InputDecoration(
                hintText: _selectedPrompt ?? 'Write your thoughts here...',
                border: const OutlineInputBorder(),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMoodSelector() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceAround,
      children: [
        _buildMoodOption('great', '😄', 'Great'),
        _buildMoodOption('good', '🙂', 'Good'),
        _buildMoodOption('okay', '😐', 'Okay'),
        _buildMoodOption('difficult', '😔', 'Difficult'),
      ],
    );
  }

  Widget _buildMoodOption(String mood, String emoji, String label) {
    final isSelected = _selectedMood == mood;
    return InkWell(
      onTap: () => setState(() => _selectedMood = mood),
      child: Container(
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          border: Border.all(
            color: isSelected
                ? Theme.of(context).colorScheme.primary
                : Colors.transparent,
          ),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Column(
          children: [
            Text(emoji, style: const TextStyle(fontSize: 32)),
            Text(label),
          ],
        ),
      ),
    );
  }

  Widget _buildPromptSelector() {
    return DropdownButtonFormField<String>(
      value: _selectedPrompt,
      decoration: const InputDecoration(
        labelText: 'Writing Prompt (Optional)',
        border: OutlineInputBorder(),
      ),
      items: _prompts.map((prompt) {
        return DropdownMenuItem(
          value: prompt,
          child: Text(prompt),
        );
      }).toList(),
      onChanged: (value) => setState(() => _selectedPrompt = value),
    );
  }

  void _saveEntry() {
    if (_contentController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please write something')),
      );
      return;
    }

    final journalService = context.read<JournalService>();
    final entry = JournalEntry(
      id: widget.existingEntry?.id ??
          DateTime.now().millisecondsSinceEpoch.toString(),
      habitId: widget.habit.id,
      content: _contentController.text,
      date: DateTime.now(),
      mood: _selectedMood,
    );

    journalService.addEntry(entry).then((_) {
      Navigator.pop(context);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Journal entry saved')),
      );
    });
  }
} 