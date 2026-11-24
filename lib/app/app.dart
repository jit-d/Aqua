import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/settings_provider.dart';
import '../screens/home_screen.dart';
import '../screens/onboarding_screen.dart';
import '../screens/statistics_screen.dart';
import '../screens/reminder_screen.dart';
import '../screens/achievements_screen.dart';
import '../screens/settings_screen.dart';
import 'theme.dart';

class AquaApp extends StatefulWidget {
  const AquaApp({super.key});
  @override
  State<AquaApp> createState() => _AquaAppState();
}

class _AquaAppState extends State<AquaApp> {
  int _index = 0;

  final _screens = const [
    HomeScreen(),
    StatisticsScreen(),
    ReminderScreen(),
    AchievementsScreen(),
    SettingsScreen(),
  ];

  @override
  Widget build(BuildContext context) {
    final settings = context.watch<SettingsProvider>();

    return MaterialApp(
      title: 'Aqua Reminder',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.light(),
      darkTheme: AppTheme.dark(),
      themeMode: settings.themeMode,
      home: !settings.loaded
          ? const Scaffold(body: Center(child: CircularProgressIndicator()))
          : !settings.onboarded
              ? OnboardingScreen(
                  onComplete: () => setState(() {}),
                )
              : Scaffold(
                  body: IndexedStack(index: _index, children: _screens),
                  bottomNavigationBar: NavigationBar(
                    selectedIndex: _index,
                    onDestinationSelected: (i) => setState(() => _index = i),
                    destinations: const [
                      NavigationDestination(
                          icon: Icon(Icons.home_outlined),
                          selectedIcon: Icon(Icons.home),
                          label: 'Home'),
                      NavigationDestination(
                          icon: Icon(Icons.bar_chart_outlined),
                          selectedIcon: Icon(Icons.bar_chart),
                          label: 'Stats'),
                      NavigationDestination(
                          icon: Icon(Icons.alarm_outlined),
                          selectedIcon: Icon(Icons.alarm),
                          label: 'Reminders'),
                      NavigationDestination(
                          icon: Icon(Icons.emoji_events_outlined),
                          selectedIcon: Icon(Icons.emoji_events),
                          label: 'Awards'),
                      NavigationDestination(
                          icon: Icon(Icons.settings_outlined),
                          selectedIcon: Icon(Icons.settings),
                          label: 'Settings'),
                    ],
                  ),
                ),
    );
  }
}