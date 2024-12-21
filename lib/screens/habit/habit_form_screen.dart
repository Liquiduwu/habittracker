import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:habit_tracker/models/habit.dart';
import 'package:habit_tracker/services/habit_service.dart';
import 'package:habit_tracker/services/notification_service.dart';

class HabitFormScreen extends StatefulWidget {
  final Habit? habit;

  const HabitFormScreen({super.key, this.habit});

  @override
  State<HabitFormScreen> createState() => _HabitFormScreenState();
}

class _HabitFormScreenState extends State<HabitFormScreen> {
  final _formKey = GlobalKey<FormState>();
  late TextEditingController _titleController;
  late TextEditingController _descriptionController;
  late TextEditingController _targetDaysController;
  bool _reminderEnabled = false;
  TimeOfDay? _reminderTime;

  @override
  void initState() {
    super.initState();
    _titleController = TextEditingController(text: widget.habit?.title);
    _descriptionController = TextEditingController(text: widget.habit?.description);
    _targetDaysController =
        TextEditingController(text: widget.habit?.targetDays.toString());
    _reminderEnabled = widget.habit?.reminderEnabled ?? false;
    _reminderTime = widget.habit?.reminderTime;
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
        id: widget.habit?.id ?? DateTime.now().millisecondsSinceEpoch.toString(),
        userId: userId,
        title: _titleController.text,
        description: _descriptionController.text,
        targetDays: int.parse(_targetDaysController.text),
        reminderEnabled: _reminderEnabled,
        reminderTime: _reminderTime,
        completedDates: widget.habit?.completedDates ?? [],
        createdAt: widget.habit?.createdAt,
      );

      try {
        if (widget.habit != null) {
          await habitService.updateHabit(habit);
        } else {
          await habitService.addHabit(habit);
        }
        if (mounted) {
          Navigator.pop(context);
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Error: $e')),
          );
        }
      }
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
            if (_reminderEnabled) ...[
              ListTile(
                title: const Text('Reminder Time'),
                trailing: Text(_reminderTime?.format(context) ?? 'Select time'),
                onTap: _selectTime,
              ),
            ],
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