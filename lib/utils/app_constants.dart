class AppConstants {
  static const String appName = 'Aqua Reminder';
  static const String tagline = 'Drink Water. Stay Hydrated. Feel Better.';

  // Brand colors
  static const int primaryBlue = 0xFF2196F3;
  static const int deepBlue = 0xFF1565C0;
  static const int lightBlue = 0xFFE3F2FD;
  static const int background = 0xFFF7FAFD;
  static const int darkText = 0xFF172B4D;
  static const int secondaryText = 0xFF718096;
  static const int successGreen = 0xFF2EAD75;

  // Defaults
  static const int defaultGoalMl = 2000;
  static const List<int> presetGoals = [1500, 2000, 2500, 3000];
  static const List<int> quickAddAmounts = [100, 150, 250, 500];
  static const List<int> reminderIntervals = [30, 45, 60, 90, 120];
  static const List<String> drinkTypes = ['Water', 'Tea', 'Coffee', 'Juice', 'Other'];

  // Database
  static const String dbName = 'aqua_reminder.db';
  static const int dbVersion = 2;
}