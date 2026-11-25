import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'app/app.dart';
import 'providers/achievement_provider.dart';
import 'providers/container_provider.dart';
import 'providers/reminder_provider.dart';
import 'providers/settings_provider.dart';
import 'providers/statistics_provider.dart';
import 'providers/water_provider.dart';
import 'services/notification_service.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await NotificationService().init();

  final sp = SettingsProvider();
  await sp.load();
  
  // Calculate personalized base goal
  int baseGoal = (sp.weightKg * 35).round();
  baseGoal += (sp.exerciseMinutes ~/ 30) * 350;
  if (sp.age > 55) baseGoal += 150;
  if (sp.region == 'tropical') baseGoal += 300;

  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider.value(value: sp),
        ChangeNotifierProvider(create: (_) => WaterProvider()..initWithProfile(baseGoal)),
        ChangeNotifierProvider(create: (_) => StatisticsProvider()),
        ChangeNotifierProvider(create: (_) => ReminderProvider()..load()),
        ChangeNotifierProvider(create: (_) => AchievementProvider()),
        ChangeNotifierProvider(create: (_) => ContainerProvider()..init()),
      ],
      child: const AquaApp(),
    ),
  );
}