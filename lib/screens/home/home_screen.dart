import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:habit_tracker/services/auth_service.dart';
import 'package:habit_tracker/services/theme_service.dart';
import 'package:habit_tracker/screens/home/habit_list_screen.dart';
import 'package:habit_tracker/screens/habit/habit_form_screen.dart';
import 'package:habit_tracker/screens/statistics/statistics_screen.dart';
import 'package:habit_tracker/screens/calendar/calendar_screen.dart';
import 'package:habit_tracker/screens/habit/template_selection_screen.dart';
import 'package:habit_tracker/screens/partnership/partnership_screen.dart';

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final themeService = Provider.of<ThemeService>(context);
    
    return Scaffold(
      appBar: AppBar(
        title: FutureBuilder<String>(
          future: context.read<AuthService>().getCurrentUsername(),
          builder: (context, snapshot) {
            if (!snapshot.hasData) return const Text('Daily Habits');
            return Text('Welcome, ${snapshot.data}');
          },
        ),
        actions: [
          PopupMenuButton<String>(
            icon: const Icon(Icons.menu),
            position: PopupMenuPosition.under,
            offset: const Offset(0, 8),
            onSelected: (value) {
              switch (value) {
                case 'theme':
                  themeService.toggleTheme();
                  break;
                case 'statistics':
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => const StatisticsScreen(),
                    ),
                  );
                  break;
                case 'calendar':
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => const CalendarScreen(),
                    ),
                  );
                  break;
                case 'logout':
                  context.read<AuthService>().signOut();
                  break;
                case 'colors':
                  _showColorPicker(context, themeService);
                  break;
                case 'partners':
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => const PartnershipScreen(),
                    ),
                  );
                  break;
              }
            },
            itemBuilder: (BuildContext context) => <PopupMenuEntry<String>>[
              PopupMenuItem<String>(
                value: 'theme',
                child: Row(
                  children: [
                    Icon(
                      themeService.isDarkMode
                          ? Icons.light_mode
                          : Icons.dark_mode,
                      color: Theme.of(context).iconTheme.color,
                    ),
                    const SizedBox(width: 8),
                    Text(themeService.isDarkMode ? 'Light Mode' : 'Dark Mode'),
                  ],
                ),
              ),
              PopupMenuItem<String>(
                value: 'colors',
                child: Row(
                  children: [
                    Icon(
                      Icons.palette,
                      color: Theme.of(context).iconTheme.color,
                    ),
                    const SizedBox(width: 8),
                    const Text('Theme Color'),
                  ],
                ),
              ),
              PopupMenuItem<String>(
                value: 'statistics',
                child: Row(
                  children: [
                    Icon(
                      Icons.bar_chart,
                      color: Theme.of(context).iconTheme.color,
                    ),
                    const SizedBox(width: 8),
                    const Text('Statistics'),
                  ],
                ),
              ),
              PopupMenuItem<String>(
                value: 'calendar',
                child: Row(
                  children: [
                    Icon(
                      Icons.calendar_today,
                      color: Theme.of(context).iconTheme.color,
                    ),
                    const SizedBox(width: 8),
                    const Text('Calendar'),
                  ],
                ),
              ),
              PopupMenuItem<String>(
                value: 'partners',
                child: Row(
                  children: [
                    Icon(
                      Icons.people,
                      color: Theme.of(context).iconTheme.color,
                    ),
                    const SizedBox(width: 8),
                    const Text('Partners'),
                  ],
                ),
              ),
              const PopupMenuDivider(),
              PopupMenuItem<String>(
                value: 'logout',
                child: Row(
                  children: [
                    Icon(
                      Icons.logout,
                      color: Theme.of(context).colorScheme.error,
                    ),
                    const SizedBox(width: 8),
                    Text(
                      'Logout',
                      style: TextStyle(
                        color: Theme.of(context).colorScheme.error,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
      body: const HabitListScreen(),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          showModalBottomSheet(
            context: context,
            builder: (context) => SafeArea(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  ListTile(
                    leading: const Icon(Icons.add),
                    title: const Text('Custom Habit'),
                    onTap: () {
                      Navigator.pop(context);
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => const HabitFormScreen(),
                        ),
                      );
                    },
                  ),
                  ListTile(
                    leading: const Icon(Icons.list_alt),
                    title: const Text('Use Template'),
                    onTap: () {
                      Navigator.pop(context);
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => const TemplateSelectionScreen(),
                        ),
                      );
                    },
                  ),
                ],
              ),
            ),
          );
        },
        child: const Icon(Icons.add),
      ),
    );
  }

  void _showColorPicker(BuildContext context, ThemeService themeService) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Choose Theme Color'),
        content: SingleChildScrollView(
          child: Wrap(
            spacing: 8,
            runSpacing: 8,
            children: ThemeService.availableColors.entries.map((entry) {
              return InkWell(
                onTap: () {
                  themeService.setColor(entry.key);
                  Navigator.pop(context);
                },
                child: Container(
                  width: 50,
                  height: 50,
                  decoration: BoxDecoration(
                    color: entry.value,
                    shape: BoxShape.circle,
                    border: Border.all(
                      color: Theme.of(context).dividerColor,
                      width: 2,
                    ),
                  ),
                  child: themeService.primaryColor == entry.value
                      ? Icon(
                          Icons.check,
                          color: entry.value.computeLuminance() > 0.5
                              ? Colors.black
                              : Colors.white,
                        )
                      : null,
                ),
              );
            }).toList(),
          ),
        ),
      ),
    );
  }
} 