import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'app/app.dart';
import 'providers/settings_provider.dart';
import 'providers/statistics_provider.dart';
import 'providers/water_provider.dart';
import 'services/notification_service.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  final notificationService = NotificationService();
  await notificationService.init();

  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => SettingsProvider()..load()),
        ChangeNotifierProvider(create: (_) => WaterProvider()..init()),
        ChangeNotifierProvider(create: (_) => StatisticsProvider()),
      ],
      child: const AquaApp(),
    ),
  );
}