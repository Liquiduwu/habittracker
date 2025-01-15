import 'package:flutter/material.dart';
import 'package:habit_tracker/repositories/habit_repository.dart';
import 'package:habit_tracker/services/database_service.dart';
import 'package:habit_tracker/services/offline_sync_service.dart';
import 'package:provider/provider.dart';
import 'package:habit_tracker/models/habit.dart';
import 'package:habit_tracker/services/habit_service.dart';
import 'package:habit_tracker/services/notification_service.dart';
import 'package:google_generative_ai/google_generative_ai.dart';

class HabitFormScreen extends StatefulWidget {
  final Habit? habit;

  const HabitFormScreen({super.key, this.habit});

  @override
  State<HabitFormScreen> createState() => _HabitFormScreenState();
}

class _HabitFormScreenState extends State<HabitFormScreen> {
  late final DatabaseService _databaseService;
  late final HabitRepository _habitRepository;
  String? _databasePath;

  final _formKey = GlobalKey<FormState>();
  late TextEditingController _titleController;
  late TextEditingController _descriptionController;
  late TextEditingController _targetDaysController;
  bool _reminderEnabled = false;
  TimeOfDay? _reminderTime;
  String? aiGeneratedHabit;
  bool isLoadingAI = false;

  @override
  void initState() {
    super.initState();
    _databaseService = DatabaseService();
    _titleController = TextEditingController(text: widget.habit?.title);
    _descriptionController =
        TextEditingController(text: widget.habit?.description);
    _targetDaysController =
        TextEditingController(text: widget.habit?.targetDays.toString() ?? '');
    _reminderEnabled = widget.habit?.reminderEnabled ?? false;
    _reminderTime = widget.habit?.reminderTime;

    // Use Future.microtask to ensure the context is available
    Future.microtask(() async {
      await _initializeDatabase();
      if (mounted) {
        setState(() {});
      }
    });
  }

  Future<void> _initializeDatabase() async {
    try {
      _databasePath = await _databaseService.databasePath;
      print('Database path: $_databasePath');

      if (!mounted) return;

      _habitRepository = HabitRepository(
        databaseService: _databaseService,
        offlineSyncService: context.read<OfflineSyncService>(),
      );
    } catch (e) {
      print('Error initializing database: $e');
      // Handle error appropriately
    }
  }

  @override
  void dispose() {
    _titleController.dispose();
    _descriptionController.dispose();
    _targetDaysController.dispose();
    super.dispose();
  }

  Future<void> _saveHabit() async {
    if (_formKey.currentState!.validate()) {
      final habitService = context.read<HabitService>();
      final userId = habitService.userId;
      final habit = Habit(
        id: widget.habit?.id ??
            DateTime.now().millisecondsSinceEpoch.toString(),
        userId: userId,
        title: _titleController.text,
        description: _descriptionController.text,
        targetDays: int.parse(_targetDaysController.text),
        reminderEnabled: _reminderEnabled,
        reminderTime: _reminderTime,
        completedDates: widget.habit?.completedDates ?? [],
        createdAt: widget.habit?.createdAt ?? DateTime.now(),
        isSynced: false,
      );

      try {
        // Convert to map with snake_case keys for SQLite
        final habitMap = {
          'id': habit.id,
          'user_id': habit.userId, // Changed from userId
          'title': habit.title,
          'description': habit.description,
          'target_days': habit.targetDays,
          'reminder_enabled': habit.reminderEnabled ? 1 : 0,
          'reminder_time': habit.reminderTime?.format(context),
          'completed_dates': habit.completedDates.join(','),
          'created_at': habit.createdAt.toIso8601String(),
          'is_synced': habit.isSynced ? 1 : 0,
          'is_favorite': 0, // Default value
        };

        if (widget.habit != null) {
          await _habitRepository.updateHabit(habit);
          await habitService.updateHabit(habit);
        } else {
          await _habitRepository.addHabit(habit);
          await habitService.addHabit(habit);
        }

        if (mounted) {
          Navigator.pop(context);
        }
      } catch (e) {
        print('Error saving habit: $e');
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Error: $e')),
          );
        }
      }
    }
  }

  Future<void> _generateHabitUsingAI(BuildContext context) async {
    final summaryController = TextEditingController();

    final summary = await showDialog<String>(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Enter Habit Summary'),
          content: TextField(
            controller: summaryController,
            decoration: const InputDecoration(
              labelText: 'Summary',
              border: OutlineInputBorder(),
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context, null),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: () => Navigator.pop(context, summaryController.text),
              child: const Text('Submit'),
            ),
          ],
        );
      },
    );

    if (summary == null || summary.isEmpty) return;

    setState(() {
      isLoadingAI = true;
    });

    try {
      final generativeModel = GenerativeModel(
        model: 'gemini-1.5-flash',
        apiKey: 'YOUR_API_KEY', // Replace with actual API key
      );

      final prompt = '''
Based on the following summary, generate a habit idea:
Summary: $summary

Provide:
- A title (less than 10 words)
- A description (less than 50 words)
- Target days as an integer
''';

      final response =
          await generativeModel.generateContent([Content.text(prompt)]);

      final content = response.text?.trim() ?? '';
      final titleMatch = RegExp(r'\*\*Title:\*\*\s*(.*)').firstMatch(content);
      final descriptionMatch =
          RegExp(r'\*\*Description:\*\*\s*(.*)').firstMatch(content);
      final targetDaysMatch =
          RegExp(r'\*\*Target days:\*\*\s*(.*)').firstMatch(content);

      final title = titleMatch?.group(1)?.trim() ?? '';
      final description = descriptionMatch?.group(1)?.trim() ?? '';
      final targetDays = targetDaysMatch?.group(1)?.trim() ?? '';

      setState(() {
        _titleController.text = title;
        _descriptionController.text = description;
        _targetDaysController.text = targetDays;
        isLoadingAI = false;
      });
    } catch (error) {
      print('Error generating habit: $error');
      setState(() {
        aiGeneratedHabit = 'Error generating habit. Please try again.';
        isLoadingAI = false;
      });
    }
  }

  Future<void> _selectTime() async {
    final TimeOfDay? picked = await showTimePicker(
      context: context,
      initialTime: _reminderTime ?? TimeOfDay.now(),
    );
    if (picked != null) {
      setState(() {
        _reminderTime = picked;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.habit != null ? 'Edit Habit' : 'New Habit'),
      ),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            if (aiGeneratedHabit != null)
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(8),
                  color: Colors.grey.shade200,
                ),
                child: Text(
                  aiGeneratedHabit!,
                  style: const TextStyle(fontSize: 16),
                ),
              ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _titleController,
              decoration: const InputDecoration(
                labelText: 'Title',
                border: OutlineInputBorder(),
              ),
              validator: (value) {
                if (value == null || value.isEmpty) {
                  return 'Please enter a title';
                }
                return null;
              },
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _descriptionController,
              decoration: const InputDecoration(
                labelText: 'Description (optional)',
                border: OutlineInputBorder(),
              ),
              maxLines: 3,
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _targetDaysController,
              decoration: const InputDecoration(
                labelText: 'Target Days',
                border: OutlineInputBorder(),
              ),
              keyboardType: TextInputType.number,
              validator: (value) {
                if (value == null || value.isEmpty) {
                  return 'Please enter target days';
                }
                final days = int.tryParse(value);
                if (days == null || days < 1) {
                  return 'Please enter a valid number';
                }
                return null;
              },
            ),
            const SizedBox(height: 16),
            SwitchListTile(
              title: const Text('Enable Reminder'),
              value: _reminderEnabled,
              onChanged: (value) async {
                if (value) {
                  await NotificationService().requestPermissions();
                }
                setState(() {
                  _reminderEnabled = value;
                  if (!value) {
                    _reminderTime = null;
                  }
                });
              },
            ),
            if (_reminderEnabled)
              ListTile(
                title: const Text('Reminder Time'),
                trailing: Text(_reminderTime?.format(context) ?? 'Select time'),
                onTap: _selectTime,
              ),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed:
                  isLoadingAI ? null : () => _generateHabitUsingAI(context),
              child: isLoadingAI
                  ? const CircularProgressIndicator(color: Colors.white)
                  : const Text('Create Using AI'),
            ),
            const SizedBox(height: 32),
            ElevatedButton(
              onPressed: _saveHabit,
              child: Text(widget.habit != null ? 'Update' : 'Create'),
            ),
          ],
        ),
      ),
    );
  }
}
