import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:habit_tracker/models/habit_template.dart';
import 'package:habit_tracker/services/template_service.dart';
import 'package:habit_tracker/services/habit_service.dart';
import 'package:habit_tracker/models/habit.dart';

class TemplateSelectionScreen extends StatelessWidget {
  const TemplateSelectionScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: TemplateService.categories.length,
      child: Scaffold(
        appBar: AppBar(
          title: const Text('Choose a Template'),
          bottom: TabBar(
            isScrollable: true,
            tabs: TemplateService.categories
                .map((category) => Tab(text: category))
                .toList(),
          ),
        ),
        body: TabBarView(
          children: TemplateService.categories
              .map((category) => _CategoryTemplates(category: category))
              .toList(),
        ),
      ),
    );
  }
}

class _CategoryTemplates extends StatelessWidget {
  final String category;

  const _CategoryTemplates({required this.category});

  @override
  Widget build(BuildContext context) {
    final templates = TemplateService.getTemplatesByCategory(category);

    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: templates.length,
      itemBuilder: (context, index) {
        final template = templates[index];
        return Card(
          child: ListTile(
            leading: Icon(template.icon),
            title: Text(template.title),
            subtitle: Text(template.description),
            trailing: Text('${template.targetDays} days'),
            onTap: () => _createHabitFromTemplate(context, template),
          ),
        );
      },
    );
  }

  void _createHabitFromTemplate(BuildContext context, HabitTemplate template) {
    final habitService = context.read<HabitService>();
    final habit = Habit(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      userId: habitService.userId,
      title: template.title,
      description: template.description,
      targetDays: template.targetDays,
      reminderEnabled: false,
    );

    habitService.addHabit(habit).then((_) {
      Navigator.pop(context);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Created habit: ${template.title}')),
      );
    });
  }
} 